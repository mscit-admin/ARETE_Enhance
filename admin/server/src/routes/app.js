// App-facing API for the mobile app (members).
// Endpoints return a Member-shaped JSON that the Flutter Member.fromJson parses.
const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../db');
const { signToken, requireAuth } = require('../middleware/auth');

const router = express.Router();

// ---- enum mapping between DB (snake_case) and the app (camelCase) ----
const GOAL_TO_APP = {
  lose_weight: 'loseWeight',
  build_muscle: 'buildMuscle',
  endurance: 'endurance',
  general_fitness: 'generalFitness',
};
const GOAL_TO_DB = Object.fromEntries(
  Object.entries(GOAL_TO_APP).map(([k, v]) => [v, k]),
);
const norm = (s) => String(s || '').trim().toLowerCase();

// A short, human-shareable, unique trainer code (used for the QR).
async function generateTrainerCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no confusing chars
  for (let attempt = 0; attempt < 8; attempt++) {
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += alphabet[Math.floor(Math.random() * alphabet.length)];
    }
    const clash = await db.query('SELECT 1 FROM trainers WHERE code = $1', [code]);
    if (!clash.rowCount) return code;
  }
  throw new Error('Could not allocate a trainer code');
}

// Build the full Member JSON the app expects for a given user id.
async function loadProfile(userId) {
  const { rows } = await db.query(
    `SELECT u.id, u.full_name, u.email, u.phone, u.photo_url, u.role,
            m.gender, m.date_of_birth, m.goal, m.experience, m.units,
            m.height_cm, m.weight_kg, m.body_fat_pct,
            m.current_streak_days, m.weekly_target_sessions, m.trainer_id,
            t.code AS trainer_code
       FROM users u
       LEFT JOIN members m ON m.user_id = u.id
       LEFT JOIN trainers t ON t.user_id = u.id
      WHERE u.id = $1`,
    [userId],
  );
  const r = rows[0];
  if (!r) return null;

  const ms = await db.query(
    `SELECT tier, status, started_on, renews_on FROM memberships
      WHERE member_id = $1 ORDER BY renews_on DESC LIMIT 1`,
    [userId],
  );
  const sessions = await db.query(
    `SELECT count(*)::int AS n FROM workout_sessions
      WHERE member_id = $1 AND started_at >= date_trunc('week', now())`,
    [userId],
  );

  const membership = ms.rows[0] || {
    tier: 'basic',
    status: 'active',
    started_on: new Date().toISOString(),
    renews_on: new Date(Date.now() + 365 * 864e5).toISOString(),
  };

  const dob = r.date_of_birth
    ? new Date(r.date_of_birth).toISOString()
    : new Date(Date.UTC(1995, 0, 1)).toISOString();

  return {
    id: r.id,
    fullName: r.full_name,
    email: r.email,
    phone: r.phone,
    photoUrl: r.photo_url,
    gender: r.gender || 'preferNotToSay',
    dateOfBirth: dob,
    goal: GOAL_TO_APP[r.goal] || 'generalFitness',
    experience: r.experience || 'beginner',
    units: r.units || 'metric',
    metrics: {
      weightKg: Number(r.weight_kg ?? 75),
      heightCm: Number(r.height_cm ?? 175),
      bodyFatPercent: r.body_fat_pct == null ? null : Number(r.body_fat_pct),
      waistCm: null,
    },
    dailyStats: {
      waterGlasses: 0,
      waterTargetGlasses: 8,
      steps: 0,
      stepsTarget: 8000,
      caloriesBurned: 0,
      caloriesTarget: 500,
      activeMinutes: 0,
      activeMinutesTarget: 45,
    },
    membership: {
      tier: membership.tier,
      status: membership.status,
      joinedOn: new Date(membership.started_on).toISOString(),
      renewsOn: new Date(membership.renews_on).toISOString(),
    },
    currentStreakDays: r.current_streak_days ?? 0,
    weeklyTargetSessions: r.weekly_target_sessions ?? 3,
    sessionsThisWeek: sessions.rows[0].n,
    assignedTrainerId: r.trainer_id,
    badges: [],
    // Extra fields (ignored by Member.fromJson, read by the auth layer):
    role: r.role,
    trainerCode: r.trainer_code || null,
  };
}

// POST /api/app/auth/register  { name, email, password, role? }
// role: 'member' (default) or 'trainer'. A trainer also gets a member profile
// so they can use trainee mode, plus a unique QR link code.
router.post('/auth/register', async (req, res) => {
  const name = String(req.body?.name || '').trim();
  const email = norm(req.body?.email);
  const password = req.body?.password || '';
  const role = req.body?.role === 'trainer' ? 'trainer' : 'member';
  if (!name || !email || password.length < 6) {
    return res
      .status(400)
      .json({ error: 'Name, email and a 6+ char password are required' });
  }
  const client = await db.pool.connect();
  try {
    const exists = await client.query('SELECT 1 FROM users WHERE email = $1', [
      email,
    ]);
    if (exists.rowCount) {
      return res.status(409).json({ error: 'That email is already registered' });
    }
    await client.query('BEGIN');
    const hash = await bcrypt.hash(password, 10);
    const u = await client.query(
      `INSERT INTO users (email, password_hash, full_name, role)
       VALUES ($1, $2, $3, $4) RETURNING id, email, full_name, role`,
      [email, hash, name, role],
    );
    const uid = u.rows[0].id;
    // Everyone gets a member profile (trainers can train too).
    await client.query(
      `INSERT INTO members (user_id, goal, experience, units, height_cm, weight_kg)
       VALUES ($1, 'general_fitness', 'beginner', 'metric', 175, 75)`,
      [uid],
    );
    await client.query(
      `INSERT INTO memberships (member_id, tier, status, renews_on, price)
       VALUES ($1, 'basic', 'active', current_date + interval '365 days', 0)`,
      [uid],
    );
    if (role === 'trainer') {
      const code = await generateTrainerCode();
      await client.query(
        `INSERT INTO trainers (user_id, specialty, code) VALUES ($1, $2, $3)`,
        [uid, 'Personal Trainer', code],
      );
    }
    await client.query('COMMIT');

    const token = signToken(u.rows[0]);
    const profile = await loadProfile(uid);
    return res.status(201).json({ token, profile });
  } catch (e) {
    await client.query('ROLLBACK');
    return res.status(500).json({ error: 'Registration failed' });
  } finally {
    client.release();
  }
});

// POST /api/app/auth/login  { email, password }
router.post('/auth/login', async (req, res) => {
  const email = norm(req.body?.email);
  const password = req.body?.password || '';
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }
  try {
    const { rows } = await db.query(
      `SELECT id, email, full_name, role, status, password_hash FROM users WHERE email = $1`,
      [email],
    );
    const user = rows[0];
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    if (user.role === 'admin') {
      return res.status(403).json({ error: 'Use the admin console for this account' });
    }
    if (user.status === 'suspended') {
      return res.status(403).json({
        error: 'Your account has been suspended. Please contact your gym.',
        code: 'account_suspended',
      });
    }
    const token = signToken(user);
    const profile = await loadProfile(user.id);
    return res.json({ token, profile });
  } catch (e) {
    return res.status(500).json({ error: 'Login failed' });
  }
});

// GET /api/app/profile  (member JWT)
router.get('/profile', requireAuth, async (req, res) => {
  try {
    const profile = await loadProfile(req.user.sub);
    if (!profile) return res.status(404).json({ error: 'Profile not found' });
    return res.json(profile);
  } catch (e) {
    return res.status(500).json({ error: 'Failed to load profile' });
  }
});

// PUT /api/app/profile  (member JWT) — updates the editable fields.
router.put('/profile', requireAuth, async (req, res) => {
  const b = req.body || {};
  const uid = req.user.sub;
  try {
    // users: name + phone
    if (b.fullName !== undefined || b.phone !== undefined) {
      await db.query(
        `UPDATE users SET
            full_name = COALESCE($1, full_name),
            phone = COALESCE($2, phone),
            updated_at = now()
          WHERE id = $3`,
        [b.fullName ? String(b.fullName).trim() : null, b.phone ?? null, uid],
      );
    }
    // members: profile + metrics
    await db.query(
      `UPDATE members SET
          gender = COALESCE($1, gender),
          date_of_birth = COALESCE($2::date, date_of_birth),
          goal = COALESCE($3, goal),
          experience = COALESCE($4, experience),
          units = COALESCE($5, units),
          height_cm = COALESCE($6, height_cm),
          weight_kg = COALESCE($7, weight_kg)
        WHERE user_id = $8`,
      [
        b.gender ?? null,
        b.dateOfBirth
          ? new Date(b.dateOfBirth).toISOString().slice(0, 10)
          : null,
        b.goal ? GOAL_TO_DB[b.goal] || null : null,
        b.experience ?? null,
        b.units ?? null,
        b.heightCm ?? null,
        b.weightKg ?? null,
        uid,
      ],
    );
    const profile = await loadProfile(uid);
    return res.json(profile);
  } catch (e) {
    return res.status(500).json({ error: 'Failed to update profile' });
  }
});

// GET /api/app/trainer/code  (trainer only) — the QR link code to share.
router.get('/trainer/code', requireAuth, async (req, res) => {
  try {
    const { rows } = await db.query(
      'SELECT code FROM trainers WHERE user_id = $1',
      [req.user.sub],
    );
    if (!rows[0]) {
      return res.status(403).json({ error: 'Only trainers have a link code' });
    }
    let code = rows[0].code;
    if (!code) {
      code = await generateTrainerCode();
      await db.query('UPDATE trainers SET code = $1 WHERE user_id = $2', [
        code,
        req.user.sub,
      ]);
    }
    // The QR payload the app encodes/scans.
    return res.json({ code, qr: `ARETE-COACH:${code}` });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to load code' });
  }
});

// GET /api/app/trainer/clients  (trainer only) — linked members.
router.get('/trainer/clients', requireAuth, async (req, res) => {
  try {
    const isTrainer = await db.query(
      'SELECT 1 FROM trainers WHERE user_id = $1',
      [req.user.sub],
    );
    if (!isTrainer.rowCount) {
      return res.status(403).json({ error: 'Trainers only' });
    }
    const { rows } = await db.query(
      `SELECT u.id, u.full_name, u.email, m.goal, m.experience
         FROM members m JOIN users u ON u.id = m.user_id
        WHERE m.trainer_id = $1
        ORDER BY u.full_name`,
      [req.user.sub],
    );
    return res.json({ rows });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to load clients' });
  }
});

// GET /api/app/coach  — the current member's linked coach (or null).
router.get('/coach', requireAuth, async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT u.id, u.full_name, u.email, t.specialty, t.certifications,
              t.rating, t.avg_response_h
         FROM members m
         JOIN trainers t ON t.user_id = m.trainer_id
         JOIN users u ON u.id = t.user_id
        WHERE m.user_id = $1`,
      [req.user.sub],
    );
    return res.json({ coach: rows[0] || null });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to load coach' });
  }
});

// POST /api/app/link  { code } — link the current member to a trainer by code.
router.post('/link', requireAuth, async (req, res) => {
  const raw = String(req.body?.code || '').trim().toUpperCase();
  // Accept both the raw code and the scanned "ARETE-COACH:CODE" payload.
  const code = raw.startsWith('ARETE-COACH:') ? raw.slice('ARETE-COACH:'.length) : raw;
  if (!code) return res.status(400).json({ error: 'A code is required' });
  try {
    const t = await db.query(
      `SELECT u.id, u.full_name, t.specialty, t.certifications, t.rating,
              t.avg_response_h
         FROM trainers t JOIN users u ON u.id = t.user_id
        WHERE t.code = $1`,
      [code],
    );
    if (!t.rows[0]) {
      return res.status(404).json({ error: 'No coach found for that code' });
    }
    const trainerId = t.rows[0].id;
    if (trainerId === req.user.sub) {
      return res.status(400).json({ error: 'You can\'t link to yourself' });
    }
    await db.query('UPDATE members SET trainer_id = $1 WHERE user_id = $2', [
      trainerId,
      req.user.sub,
    ]);
    const profile = await loadProfile(req.user.sub);
    return res.json({ coach: t.rows[0], profile });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to link' });
  }
});

// ======================================================================
//  Workout plans — a trainer builds plans and assigns them to clients.
// ======================================================================

async function isTrainer(userId) {
  const { rowCount } = await db.query(
    'SELECT 1 FROM trainers WHERE user_id = $1',
    [userId],
  );
  return rowCount > 0;
}

// Cache whether a column exists, so the app keeps working on installs that
// pulled new code but haven't run `npm run migrate` yet.
const _colCache = new Map();
async function hasColumn(table, col) {
  const key = `${table}.${col}`;
  if (_colCache.has(key)) return _colCache.get(key);
  try {
    const { rowCount } = await db.query(
      `SELECT 1 FROM information_schema.columns
        WHERE table_name = $1 AND column_name = $2`,
      [table, col],
    );
    _colCache.set(key, rowCount > 0);
    return rowCount > 0;
  } catch (_) {
    return false;
  }
}

// Shape a plan row + its exercises for the app.
async function planWithExercises(planId) {
  const p = await db.query(
    `SELECT id, name, description, days_per_week, weeks, split, created_at
       FROM plans WHERE id = $1`,
    [planId],
  );
  if (!p.rows[0]) return null;
  // Rich select; on an un-migrated DB (missing columns) fall back to the base
  // columns so plans still load.
  let ex;
  try {
    ex = await db.query(
      `SELECT e.id AS exercise_id, e.name, e.name_ar, e.muscle_group, e.category,
              pe.day_index, pe.position, pe.target_sets, pe.target_reps,
              pe.target_weight, pe.rest_seconds, pe.notes
         FROM plan_exercises pe JOIN exercises e ON e.id = pe.exercise_id
        WHERE pe.plan_id = $1
        ORDER BY pe.day_index, pe.position`,
      [planId],
    );
  } catch (_) {
    ex = await db.query(
      `SELECT e.id AS exercise_id, e.name, pe.day_index, pe.position,
              pe.target_sets, pe.target_reps
         FROM plan_exercises pe JOIN exercises e ON e.id = pe.exercise_id
        WHERE pe.plan_id = $1
        ORDER BY pe.day_index, pe.position`,
      [planId],
    );
  }
  const r = p.rows[0];
  return {
    id: r.id,
    name: r.name,
    description: r.description || '',
    daysPerWeek: r.days_per_week,
    weeks: r.weeks,
    split: r.split || '',
    createdAt: r.created_at,
    // Flat list; each item carries its `day` so any client can group by day.
    // Extra fields are additive — older clients simply ignore them.
    exercises: ex.rows.map((x) => ({
      exerciseId: x.exercise_id,
      name: x.name,
      nameAr: x.name_ar || '',
      muscleGroup: x.muscle_group || '',
      category: x.category || '',
      day: x.day_index,
      sets: x.target_sets,
      reps: x.target_reps,
      weight: x.target_weight != null ? Number(x.target_weight) : null,
      rest: x.rest_seconds,
      notes: x.notes || '',
    })),
  };
}

// POST /api/app/trainer/plans  (trainer) — create a plan with exercises.
// { name, description?, daysPerWeek?, weeks?, split?, exercises: [{name, sets, reps}] }
router.post('/trainer/plans', requireAuth, async (req, res) => {
  const uid = req.user.sub;
  if (!(await isTrainer(uid))) {
    return res.status(403).json({ error: 'Trainers only' });
  }
  const b = req.body || {};
  const name = String(b.name || '').trim();
  if (!name) return res.status(400).json({ error: 'A plan name is required' });
  const exercises = Array.isArray(b.exercises) ? b.exercises : [];

  // Tolerate an un-migrated database: only write the newer columns if present.
  const peHasDetail = await hasColumn('plan_exercises', 'notes');
  const exHasMeta = await hasColumn('exercises', 'visibility');

  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');
    const plan = await client.query(
      `INSERT INTO plans (name, description, days_per_week, weeks, split, created_by)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
      [
        name,
        String(b.description || '').trim() || null,
        Number(b.daysPerWeek) || 3,
        Number(b.weeks) || 8,
        String(b.split || '').trim() || null,
        uid,
      ],
    );
    const planId = plan.rows[0].id;
    // Track a running position per day so the ordering is stable.
    const posByDay = {};
    for (const e of exercises) {
      // Prefer a library exercise by id; fall back to creating one by name so
      // the older app (which sends {name, sets, reps}) still works.
      let exerciseId = e && e.exerciseId ? String(e.exerciseId) : null;
      if (exerciseId) {
        const chk = await client.query('SELECT 1 FROM exercises WHERE id = $1', [exerciseId]);
        if (!chk.rowCount) exerciseId = null;
      }
      if (!exerciseId) {
        const exName = String(e?.name || '').trim();
        if (!exName) continue;
        const exRow = exHasMeta
            ? await client.query(
                `INSERT INTO exercises (name, created_by, visibility)
                 VALUES ($1, $2, 'private') RETURNING id`,
                [exName, uid],
              )
            : await client.query(
                `INSERT INTO exercises (name) VALUES ($1) RETURNING id`,
                [exName],
              );
        exerciseId = exRow.rows[0].id;
      }
      const day = Number(e?.day) || 0;
      const pos = posByDay[day] || 0;
      posByDay[day] = pos + 1;
      if (peHasDetail) {
        await client.query(
          `INSERT INTO plan_exercises
             (plan_id, exercise_id, day_index, position, target_sets, target_reps,
              target_weight, rest_seconds, notes)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
           ON CONFLICT (plan_id, exercise_id, day_index) DO UPDATE
             SET position = EXCLUDED.position, target_sets = EXCLUDED.target_sets,
                 target_reps = EXCLUDED.target_reps, target_weight = EXCLUDED.target_weight,
                 rest_seconds = EXCLUDED.rest_seconds, notes = EXCLUDED.notes`,
          [
            planId, exerciseId, day, pos,
            Number(e?.sets) || 3, Number(e?.reps) || 10,
            e?.weight != null && e.weight !== '' ? Number(e.weight) : null,
            e?.rest != null && e.rest !== '' ? Number(e.rest) : null,
            String(e?.notes || '').trim() || null,
          ],
        );
      } else {
        await client.query(
          `INSERT INTO plan_exercises
             (plan_id, exercise_id, day_index, position, target_sets, target_reps)
           VALUES ($1, $2, $3, $4, $5, $6)
           ON CONFLICT (plan_id, exercise_id, day_index) DO UPDATE
             SET position = EXCLUDED.position, target_sets = EXCLUDED.target_sets,
                 target_reps = EXCLUDED.target_reps`,
          [planId, exerciseId, day, pos, Number(e?.sets) || 3, Number(e?.reps) || 10],
        );
      }
    }
    await client.query('COMMIT');
    return res.status(201).json({ plan: await planWithExercises(planId) });
  } catch (e) {
    await client.query('ROLLBACK');
    return res.status(500).json({ error: 'Failed to create plan' });
  } finally {
    client.release();
  }
});

// GET /api/app/trainer/plans  (trainer) — the trainer's own plans.
router.get('/trainer/plans', requireAuth, async (req, res) => {
  const uid = req.user.sub;
  if (!(await isTrainer(uid))) {
    return res.status(403).json({ error: 'Trainers only' });
  }
  try {
    const { rows } = await db.query(
      `SELECT p.id, p.name, p.description, p.days_per_week, p.weeks,
              count(DISTINCT pe.exercise_id)::int AS exercise_count,
              count(DISTINCT a.id) FILTER (WHERE a.active)::int AS assigned_count
         FROM plans p
         LEFT JOIN plan_exercises pe ON pe.plan_id = p.id
         LEFT JOIN plan_assignments a ON a.plan_id = p.id
        WHERE p.created_by = $1
        GROUP BY p.id
        ORDER BY p.created_at DESC`,
      [uid],
    );
    return res.json({
      rows: rows.map((r) => ({
        id: r.id,
        name: r.name,
        description: r.description || '',
        daysPerWeek: r.days_per_week,
        weeks: r.weeks,
        exerciseCount: r.exercise_count,
        assignedCount: r.assigned_count,
      })),
    });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to load plans' });
  }
});

// GET /api/app/trainer/plans/:id  (trainer) — a plan's full detail.
router.get('/trainer/plans/:id', requireAuth, async (req, res) => {
  const uid = req.user.sub;
  try {
    const owns = await db.query(
      'SELECT 1 FROM plans WHERE id = $1 AND created_by = $2',
      [req.params.id, uid],
    );
    if (!owns.rowCount) return res.status(404).json({ error: 'Plan not found' });
    return res.json({ plan: await planWithExercises(req.params.id) });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to load plan' });
  }
});

// POST /api/app/trainer/plans/:id/assign  (trainer) — assign to a client.
// { memberId }
router.post('/trainer/plans/:id/assign', requireAuth, async (req, res) => {
  const uid = req.user.sub;
  const planId = req.params.id;
  const memberId = String(req.body?.memberId || '');
  if (!memberId) return res.status(400).json({ error: 'memberId is required' });
  try {
    const owns = await db.query(
      'SELECT name FROM plans WHERE id = $1 AND created_by = $2',
      [planId, uid],
    );
    if (!owns.rowCount) return res.status(404).json({ error: 'Plan not found' });
    // The member must be one of this trainer's clients.
    const link = await db.query(
      'SELECT 1 FROM members WHERE user_id = $1 AND trainer_id = $2',
      [memberId, uid],
    );
    if (!link.rowCount) {
      return res.status(403).json({ error: 'That member is not your client' });
    }
    // One active plan per member: retire previous active assignments.
    await db.query(
      'UPDATE plan_assignments SET active = false WHERE member_id = $1 AND active',
      [memberId],
    );
    await db.query(
      `INSERT INTO plan_assignments (member_id, plan_id, assigned_by, active)
       VALUES ($1, $2, $3, true)`,
      [memberId, planId, uid],
    );
    // Drop a chat card so the client sees it in the conversation.
    await db.query(
      `INSERT INTO messages (member_id, trainer_id, from_coach, body, kind, plan_id)
       VALUES ($1, $2, true, $3, 'planCard', $4)`,
      [memberId, uid, owns.rows[0].name, planId],
    );
    // Notify the trainee that a plan was assigned/updated.
    await notify(memberId, 'plan_assigned', owns.rows[0].name, null, {
      planId,
      coachId: uid,
    });
    return res.json({ ok: true });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to assign plan' });
  }
});

// GET /api/app/my-plans  (member) — active plans assigned to me, with detail.
router.get('/my-plans', requireAuth, async (req, res) => {
  const uid = req.user.sub;
  try {
    const { rows } = await db.query(
      `SELECT a.plan_id, a.assigned_at, u.full_name AS coach_name
         FROM plan_assignments a
         LEFT JOIN trainers t ON t.user_id = a.assigned_by
         LEFT JOIN users u ON u.id = t.user_id
        WHERE a.member_id = $1 AND a.active
        ORDER BY a.assigned_at DESC`,
      [uid],
    );
    const plans = [];
    for (const r of rows) {
      const p = await planWithExercises(r.plan_id);
      if (p) plans.push({ ...p, assignedAt: r.assigned_at, coachName: r.coach_name });
    }
    return res.json({ rows: plans });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to load plans' });
  }
});

// Shape an exercises row for the app.
function shapeExercise(e) {
  return {
    id: e.id,
    name: e.name,
    nameAr: e.name_ar || '',
    muscleGroup: e.muscle_group || '',
    category: e.category || '',
    level: e.level || '',
    equipment: e.equipment || '',
    targetMuscles: e.target_muscles || [],
    videoUrl: e.video_url || '',
    imageUrl: e.image_url || '',
    createdByMe: e.created_by_me === true,
  };
}

// GET /api/app/exercises?category=&muscle=&level=&query= — catalogue the caller
// can use: global + their own custom + (for a trainee) their coach's shared.
router.get('/exercises', requireAuth, async (req, res) => {
  const uid = req.user.sub;
  const category = String(req.query.category || '').trim();
  const muscle = String(req.query.muscle || '').trim();
  const level = String(req.query.level || '').trim();
  const query = String(req.query.query || '').trim();
  const params = [uid];
  const where = [
    `(visibility = 'global' OR created_by IS NULL OR created_by = $1
       OR (visibility = 'coach_shared'
           AND created_by = (SELECT trainer_id FROM members WHERE user_id = $1)))`,
  ];
  if (category) { params.push(category); where.push(`category = $${params.length}`); }
  if (muscle) { params.push(muscle); where.push(`muscle_group = $${params.length}`); }
  if (level) { params.push(level); where.push(`level = $${params.length}`); }
  if (query) {
    params.push(`%${query}%`);
    where.push(`(name ILIKE $${params.length} OR name_ar ILIKE $${params.length})`);
  }
  try {
    const { rows } = await db.query(
      `SELECT id, name, name_ar, muscle_group, category, level, equipment,
              target_muscles, video_url, image_url, (created_by = $1) AS created_by_me
         FROM exercises WHERE ${where.join(' AND ')}
        ORDER BY category, muscle_group, name LIMIT 300`,
      params,
    );
    res.json({ rows: rows.map(shapeExercise) });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load exercises' });
  }
});

// POST /api/app/exercises — create a custom exercise.
// { name, nameAr?, muscleGroup?, category?, level?, equipment?, visibility? }
// A coach may set visibility 'coach_shared' (offered to their trainees);
// everyone else's custom exercises are 'private'.
router.post('/exercises', requireAuth, async (req, res) => {
  const uid = req.user.sub;
  const b = req.body || {};
  const name = String(b.name || '').trim();
  if (!name) return res.status(400).json({ error: 'An exercise name is required' });
  try {
    const coach = await isTrainer(uid);
    const visibility =
        coach && b.visibility === 'coach_shared' ? 'coach_shared' : 'private';
    const category = ['gym', 'calisthenics'].includes(b.category) ? b.category : null;
    const { rows } = await db.query(
      `INSERT INTO exercises
         (name, name_ar, muscle_group, category, level, equipment,
          target_muscles, created_by, visibility)
       VALUES ($1, $2, $3, $4, $5, $6, '{}', $7, $8)
       RETURNING id, name, name_ar, muscle_group, category, level, equipment,
                 target_muscles, video_url, image_url, true AS created_by_me`,
      [
        name,
        String(b.nameAr || '').trim() || null,
        String(b.muscleGroup || '').trim() || null,
        category,
        String(b.level || '').trim() || null,
        String(b.equipment || '').trim() || null,
        uid,
        visibility,
      ],
    );
    return res.status(201).json({ exercise: shapeExercise(rows[0]) });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to create exercise' });
  }
});

// DELETE /api/app/exercises/:id — remove one of your own custom exercises.
router.delete('/exercises/:id', requireAuth, async (req, res) => {
  const uid = req.user.sub;
  try {
    const { rowCount } = await db.query(
      `DELETE FROM exercises WHERE id = $1 AND created_by = $2 AND visibility <> 'global'`,
      [req.params.id, uid],
    );
    if (!rowCount) return res.status(404).json({ error: 'Not found or not yours' });
    return res.json({ ok: true });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to delete exercise' });
  }
});

// POST /api/app/sessions  (member) — log a completed session's real performance.
// { planId?, dayIndex?, title?, sets: [{exerciseId?, exerciseName?, setNumber, weight, reps}] }
router.post('/sessions', requireAuth, async (req, res) => {
  const uid = req.user.sub;
  const isMember = await db.query('SELECT 1 FROM members WHERE user_id = $1', [uid]);
  if (!isMember.rowCount) return res.status(403).json({ error: 'Members only' });
  const b = req.body || {};
  const sets = Array.isArray(b.sets) ? b.sets : [];

  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');
    let volume = 0;
    for (const s of sets) volume += (Number(s?.weight) || 0) * (Number(s?.reps) || 0);
    const hasDay = await hasColumn('workout_sessions', 'day_index');
    const sess = hasDay
        ? await client.query(
            `INSERT INTO workout_sessions
               (member_id, plan_id, day_index, title, finished_at, total_volume)
             VALUES ($1, $2, $3, $4, now(), $5) RETURNING id`,
            [
              uid,
              b.planId || null,
              b.dayIndex != null ? Number(b.dayIndex) : null,
              String(b.title || '').trim() || null,
              volume,
            ],
          )
        : await client.query(
            `INSERT INTO workout_sessions
               (member_id, plan_id, title, finished_at, total_volume)
             VALUES ($1, $2, $3, now(), $4) RETURNING id`,
            [uid, b.planId || null, String(b.title || '').trim() || null, volume],
          );
    const sessionId = sess.rows[0].id;
    for (const s of sets) {
      let exId = s && s.exerciseId ? String(s.exerciseId) : null;
      if (exId) {
        const chk = await client.query('SELECT 1 FROM exercises WHERE id = $1', [exId]);
        if (!chk.rowCount) exId = null;
      }
      if (!exId && s && s.exerciseName) {
        const exRow = await client.query(
          `INSERT INTO exercises (name, created_by, visibility) VALUES ($1, $2, 'private') RETURNING id`,
          [String(s.exerciseName).trim(), uid],
        );
        exId = exRow.rows[0].id;
      }
      await client.query(
        `INSERT INTO set_logs (session_id, exercise_id, set_number, weight_kg, reps)
         VALUES ($1, $2, $3, $4, $5)`,
        [sessionId, exId, Number(s?.setNumber) || 1, Number(s?.weight) || 0, Number(s?.reps) || 0],
      );
    }
    await client.query('COMMIT');
    // Notify the member's coach that a session was completed.
    try {
      const info = await db.query(
        `SELECT m.trainer_id, u.full_name
           FROM members m JOIN users u ON u.id = m.user_id
          WHERE m.user_id = $1`,
        [uid],
      );
      const coachId = info.rows[0] && info.rows[0].trainer_id;
      const memberName = (info.rows[0] && info.rows[0].full_name) || 'A member';
      if (coachId) {
        await notify(coachId, 'session_done', memberName, b.title || null, {
          sessionId,
          memberId: uid,
        });
      }
    } catch (_) {}
    res.status(201).json({ id: sessionId, totalVolume: volume });
  } catch (e) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: 'Failed to log session' });
  } finally {
    client.release();
  }
});

// ---------- In-app notifications ----------

// Insert a notification for a user (best-effort; never breaks the caller).
async function notify(userId, type, title, body, data) {
  if (!userId) return;
  try {
    await db.query(
      `INSERT INTO notifications (user_id, type, title, body, data)
       VALUES ($1, $2, $3, $4, $5::jsonb)`,
      [userId, type, title, body || null, data ? JSON.stringify(data) : null],
    );
  } catch (_) {
    // ignore — a missing notifications table (unmigrated) must not break flows
  }
}

// GET /api/app/notifications — latest notifications + unread count.
router.get('/notifications', requireAuth, async (req, res) => {
  try {
    const [list, unread] = await Promise.all([
      db.query(
        `SELECT id, type, title, body, data, read, created_at
           FROM notifications WHERE user_id = $1
          ORDER BY created_at DESC LIMIT 50`,
        [req.user.sub],
      ),
      db.query(
        `SELECT count(*)::int AS n FROM notifications WHERE user_id = $1 AND NOT read`,
        [req.user.sub],
      ),
    ]);
    res.json({
      unread: unread.rows[0].n,
      rows: list.rows.map((n) => ({
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body || '',
        data: n.data || {},
        read: n.read,
        createdAt: n.created_at,
      })),
    });
  } catch (e) {
    res.json({ unread: 0, rows: [] }); // degrade gracefully pre-migration
  }
});

// POST /api/app/notifications/read — mark all the caller's notifications read.
router.post('/notifications/read', requireAuth, async (req, res) => {
  try {
    await db.query(
      'UPDATE notifications SET read = true WHERE user_id = $1 AND NOT read',
      [req.user.sub],
    );
    res.json({ ok: true });
  } catch (e) {
    res.json({ ok: true });
  }
});

// ======================================================================
//  Messaging — a member and their trainer share one conversation.
// ======================================================================

// Resolve the (member_id, trainer_id) pair for a conversation between the
// current user and `peerId`, plus whether the current user is the coach.
async function resolvePair(currentId, peerId) {
  // Current user is the member, peer is their trainer.
  const asMember = await db.query(
    'SELECT 1 FROM members WHERE user_id = $1 AND trainer_id = $2',
    [currentId, peerId],
  );
  if (asMember.rowCount) {
    return { memberId: currentId, trainerId: peerId, currentIsCoach: false };
  }
  // Current user is the trainer, peer is one of their clients.
  const asTrainer = await db.query(
    'SELECT 1 FROM members WHERE user_id = $1 AND trainer_id = $2',
    [peerId, currentId],
  );
  if (asTrainer.rowCount) {
    return { memberId: peerId, trainerId: currentId, currentIsCoach: true };
  }
  return null;
}

// GET /api/app/messages/:peerId — the thread with a peer (coach or client).
router.get('/messages/:peerId', requireAuth, async (req, res) => {
  try {
    const pair = await resolvePair(req.user.sub, req.params.peerId);
    if (!pair) return res.status(404).json({ error: 'No conversation' });
    const { rows } = await db.query(
      `SELECT id, from_coach, body, kind, plan_id, created_at
         FROM messages
        WHERE member_id = $1 AND trainer_id = $2
        ORDER BY created_at ASC`,
      [pair.memberId, pair.trainerId],
    );
    return res.json({
      currentIsCoach: pair.currentIsCoach,
      rows: rows.map((m) => ({
        id: m.id,
        fromCoach: m.from_coach,
        body: m.body,
        kind: m.kind,
        planId: m.plan_id,
        createdAt: m.created_at,
      })),
    });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to load messages' });
  }
});

// POST /api/app/messages  { toUserId, body } — send a message to a peer.
router.post('/messages', requireAuth, async (req, res) => {
  const peerId = String(req.body?.toUserId || '');
  const body = String(req.body?.body || '').trim();
  if (!peerId || !body) {
    return res.status(400).json({ error: 'toUserId and body are required' });
  }
  try {
    const pair = await resolvePair(req.user.sub, peerId);
    if (!pair) return res.status(404).json({ error: 'No conversation' });
    const ins = await db.query(
      `INSERT INTO messages (member_id, trainer_id, from_coach, body, kind)
       VALUES ($1, $2, $3, $4, 'text')
       RETURNING id, from_coach, body, kind, plan_id, created_at`,
      [pair.memberId, pair.trainerId, pair.currentIsCoach, body],
    );
    const m = ins.rows[0];
    return res.status(201).json({
      message: {
        id: m.id,
        fromCoach: m.from_coach,
        body: m.body,
        kind: m.kind,
        planId: m.plan_id,
        createdAt: m.created_at,
      },
    });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to send message' });
  }
});

// ======================================================================
//  Nutrition — the water target, the meal schedule and today's intake.
//  The app keeps a local cache and works without these endpoints, so every
//  handler degrades quietly on an un-migrated server rather than erroring.
// ======================================================================

const NUTRITION_DEFAULTS = {
  waterTargetGlasses: 8,
  glassMl: 250,
  mealSchedule: null, // null = the app's default schedule
  planStartDay: '', // '' = no plan period set
  planDurationDays: 0, // 0 = runs until changed
  weeklyMeals: false, // false = the same meals every day
};

// Today in the caller's local time. The app sends its own day so a member in
// UTC+3 does not roll over at 03:00 local.
function nutritionDay(req) {
  const raw = String(req.query.day || req.body?.day || '').trim();
  if (/^\d{4}-\d{2}-\d{2}$/.test(raw)) return raw;
  return new Date().toISOString().slice(0, 10);
}

// Postgres `date` comes back as a Date; the app wants a plain yyyy-MM-dd.
function dayString(value) {
  if (!value) return '';
  if (typeof value === 'string') return value.slice(0, 10);
  return new Date(value).toISOString().slice(0, 10);
}

function settingsToApp(row) {
  if (!row) return { ...NUTRITION_DEFAULTS };
  return {
    waterTargetGlasses: row.water_target_glasses ?? NUTRITION_DEFAULTS.waterTargetGlasses,
    glassMl: row.glass_ml ?? NUTRITION_DEFAULTS.glassMl,
    mealSchedule: row.meal_schedule ?? null,
    planStartDay: dayString(row.plan_start_day),
    planDurationDays: row.plan_duration_days ?? 0,
    weeklyMeals: row.weekly_meals ?? false,
  };
}

function dayToApp(row, day) {
  return {
    day,
    waterGlasses: row?.water_glasses ?? 0,
    mealsDone: Array.isArray(row?.meals_done) ? row.meals_done : [],
  };
}

const clampInt = (value, min, max, fallback) => {
  const n = Number(value);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(max, Math.max(min, Math.round(n)));
};

// The coach-issued plan currently in force for a member (newest wins).
async function latestCoachPlan(memberUserId) {
  const { rows } = await db.query(
    `SELECT p.id, p.water_target_glasses, p.duration_days, p.meal_schedule,
            p.note, p.created_at, u.full_name AS trainer_name
       FROM nutrition_plans p
       LEFT JOIN users u ON u.id = p.trainer_user_id
      WHERE p.member_user_id = $1
      ORDER BY p.created_at DESC
      LIMIT 1`,
    [memberUserId],
  );
  const r = rows[0];
  if (!r) return null;
  return {
    id: r.id,
    waterTargetGlasses: r.water_target_glasses,
    durationDays: r.duration_days ?? 0,
    mealSchedule: Array.isArray(r.meal_schedule) ? r.meal_schedule : [],
    note: r.note || '',
    coachName: r.trainer_name || '',
    createdAt: r.created_at,
  };
}

// GET /api/app/nutrition?day=YYYY-MM-DD — settings, that day's intake and the
// coach's plan (if any).
router.get('/nutrition', requireAuth, async (req, res) => {
  const day = nutritionDay(req);
  try {
    const [settings, today, coachPlan] = await Promise.all([
      db.query('SELECT * FROM nutrition_settings WHERE user_id = $1', [req.user.sub]),
      db.query('SELECT * FROM nutrition_days WHERE user_id = $1 AND day = $2', [
        req.user.sub,
        day,
      ]),
      latestCoachPlan(req.user.sub).catch(() => null),
    ]);
    return res.json({
      settings: settingsToApp(settings.rows[0]),
      today: dayToApp(today.rows[0], day),
      coachPlan,
    });
  } catch (e) {
    return res.json({
      settings: { ...NUTRITION_DEFAULTS },
      today: dayToApp(null, day),
      coachPlan: null,
      unavailable: true,
    });
  }
});

// Both coach endpoints below require the caller to be this member's trainer.
async function requireOwnClient(req, res) {
  const memberId = String(req.params.memberId || '');
  if (!memberId) {
    res.status(400).json({ error: 'memberId is required' });
    return null;
  }
  const link = await db.query(
    'SELECT 1 FROM members WHERE user_id = $1 AND trainer_id = $2',
    [memberId, req.user.sub],
  );
  if (!link.rowCount) {
    res.status(403).json({ error: 'That member is not your client' });
    return null;
  }
  return memberId;
}

// GET /api/app/trainer/trainees/:memberId/nutrition — the plan the coach last
// sent, plus what the trainee is currently following (to start from).
router.get('/trainer/trainees/:memberId/nutrition', requireAuth, async (req, res) => {
  try {
    const memberId = await requireOwnClient(req, res);
    if (!memberId) return undefined;
    const [settings, plan] = await Promise.all([
      db.query('SELECT * FROM nutrition_settings WHERE user_id = $1', [memberId]),
      latestCoachPlan(memberId),
    ]);
    return res.json({ plan, current: settingsToApp(settings.rows[0]) });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to load the nutrition plan' });
  }
});

// POST /api/app/trainer/trainees/:memberId/nutrition — send a plan to a client.
router.post('/trainer/trainees/:memberId/nutrition', requireAuth, async (req, res) => {
  const schedule = Array.isArray(req.body?.mealSchedule) ? req.body.mealSchedule : null;
  if (!schedule || !schedule.length) {
    return res.status(400).json({ error: 'mealSchedule is required' });
  }
  const waterTarget =
    req.body?.waterTargetGlasses == null
      ? null
      : clampInt(req.body.waterTargetGlasses, 1, 30, NUTRITION_DEFAULTS.waterTargetGlasses);
  const note = String(req.body?.note || '').slice(0, 500);
  const durationDays = clampInt(req.body?.durationDays, 0, 366, 0);
  try {
    const memberId = await requireOwnClient(req, res);
    if (!memberId) return undefined;
    const ins = await db.query(
      `INSERT INTO nutrition_plans
              (member_user_id, trainer_user_id, water_target_glasses, duration_days,
               meal_schedule, note)
       VALUES ($1, $2, $3, $4, $5::jsonb, $6)
    RETURNING id, created_at`,
      [
        memberId,
        req.user.sub,
        waterTarget,
        durationDays,
        JSON.stringify(schedule),
        note || null,
      ],
    );
    // The app applies the plan on its next load; tell the trainee it arrived.
    await notify(memberId, 'nutrition_plan', note || '', null, {
      planId: ins.rows[0].id,
      coachId: req.user.sub,
    });
    return res.status(201).json({ plan: await latestCoachPlan(memberId) });
  } catch (e) {
    return res.status(500).json({ error: 'Failed to send the nutrition plan' });
  }
});

// PUT /api/app/nutrition/settings — daily target, glass size, meal schedule.
router.put('/nutrition/settings', requireAuth, async (req, res) => {
  const waterTarget = clampInt(req.body?.waterTargetGlasses, 1, 30, NUTRITION_DEFAULTS.waterTargetGlasses);
  const glassMl = clampInt(req.body?.glassMl, 50, 2000, NUTRITION_DEFAULTS.glassMl);
  const schedule = Array.isArray(req.body?.mealSchedule) ? req.body.mealSchedule : null;
  const planDuration = clampInt(req.body?.planDurationDays, 0, 366, 0);
  const weeklyMeals = req.body?.weeklyMeals === true;
  const rawStart = String(req.body?.planStartDay || '').slice(0, 10);
  const planStart = /^\d{4}-\d{2}-\d{2}$/.test(rawStart) ? rawStart : null;
  try {
    const r = await db.query(
      `INSERT INTO nutrition_settings
              (user_id, water_target_glasses, glass_ml, meal_schedule,
               plan_start_day, plan_duration_days, weekly_meals, updated_at)
            VALUES ($1, $2, $3, $4::jsonb, $5::date, $6, $7, now())
       ON CONFLICT (user_id) DO UPDATE
            SET water_target_glasses = EXCLUDED.water_target_glasses,
                glass_ml             = EXCLUDED.glass_ml,
                meal_schedule        = COALESCE(EXCLUDED.meal_schedule, nutrition_settings.meal_schedule),
                plan_start_day       = EXCLUDED.plan_start_day,
                plan_duration_days   = EXCLUDED.plan_duration_days,
                weekly_meals         = EXCLUDED.weekly_meals,
                updated_at           = now()
         RETURNING *`,
      [
        req.user.sub,
        waterTarget,
        glassMl,
        schedule ? JSON.stringify(schedule) : null,
        planStart,
        planDuration,
        weeklyMeals,
      ],
    );
    return res.json({ settings: settingsToApp(r.rows[0]) });
  } catch (e) {
    // Un-migrated server: the app keeps its local copy.
    return res.json({
      settings: {
        waterTargetGlasses: waterTarget,
        glassMl,
        mealSchedule: schedule,
        planStartDay: planStart || '',
        planDurationDays: planDuration,
        weeklyMeals,
      },
      unavailable: true,
    });
  }
});

// POST /api/app/nutrition/water  { day, glasses } — set today's glass count.
router.post('/nutrition/water', requireAuth, async (req, res) => {
  const day = nutritionDay(req);
  const glasses = clampInt(req.body?.glasses, 0, 60, 0);
  try {
    const r = await db.query(
      `INSERT INTO nutrition_days (user_id, day, water_glasses, updated_at)
            VALUES ($1, $2, $3, now())
       ON CONFLICT (user_id, day) DO UPDATE
            SET water_glasses = EXCLUDED.water_glasses, updated_at = now()
         RETURNING *`,
      [req.user.sub, day, glasses],
    );
    return res.json({ today: dayToApp(r.rows[0], day) });
  } catch (e) {
    return res.json({ today: { day, waterGlasses: glasses, mealsDone: [] }, unavailable: true });
  }
});

// POST /api/app/nutrition/meals  { day, mealsDone: [id] } — today's ticked meals.
router.post('/nutrition/meals', requireAuth, async (req, res) => {
  const day = nutritionDay(req);
  const done = Array.isArray(req.body?.mealsDone)
    ? req.body.mealsDone.map((id) => String(id)).slice(0, 40)
    : [];
  try {
    const r = await db.query(
      `INSERT INTO nutrition_days (user_id, day, meals_done, updated_at)
            VALUES ($1, $2, $3::jsonb, now())
       ON CONFLICT (user_id, day) DO UPDATE
            SET meals_done = EXCLUDED.meals_done, updated_at = now()
         RETURNING *`,
      [req.user.sub, day, JSON.stringify(done)],
    );
    return res.json({ today: dayToApp(r.rows[0], day) });
  } catch (e) {
    return res.json({ today: { day, waterGlasses: 0, mealsDone: done }, unavailable: true });
  }
});

module.exports = router;
