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

module.exports = router;
