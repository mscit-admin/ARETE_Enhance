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
      `SELECT id, email, full_name, role, password_hash FROM users WHERE email = $1`,
      [email],
    );
    const user = rows[0];
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    if (user.role === 'admin') {
      return res.status(403).json({ error: 'Use the admin console for this account' });
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

// Shape a plan row + its exercises for the app.
async function planWithExercises(planId) {
  const p = await db.query(
    `SELECT id, name, description, days_per_week, weeks, split, created_at
       FROM plans WHERE id = $1`,
    [planId],
  );
  if (!p.rows[0]) return null;
  const ex = await db.query(
    `SELECT e.name, pe.target_sets, pe.target_reps, pe.position
       FROM plan_exercises pe JOIN exercises e ON e.id = pe.exercise_id
      WHERE pe.plan_id = $1
      ORDER BY pe.position, pe.day_index`,
    [planId],
  );
  const r = p.rows[0];
  return {
    id: r.id,
    name: r.name,
    description: r.description || '',
    daysPerWeek: r.days_per_week,
    weeks: r.weeks,
    split: r.split || '',
    createdAt: r.created_at,
    exercises: ex.rows.map((x) => ({
      name: x.name,
      sets: x.target_sets,
      reps: x.target_reps,
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
    let pos = 0;
    for (const e of exercises) {
      const exName = String(e?.name || '').trim();
      if (!exName) continue;
      const exRow = await client.query(
        `INSERT INTO exercises (name) VALUES ($1) RETURNING id`,
        [exName],
      );
      await client.query(
        `INSERT INTO plan_exercises (plan_id, exercise_id, day_index, position, target_sets, target_reps)
         VALUES ($1, $2, 0, $3, $4, $5)`,
        [planId, exRow.rows[0].id, pos, Number(e?.sets) || 3, Number(e?.reps) || 10],
      );
      pos += 1;
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

module.exports = router;
