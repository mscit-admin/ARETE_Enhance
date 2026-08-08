const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { SECTIONS, PERMISSIONS, expandLegacy, cleanList } = require('../permissions');

const router = express.Router();

// Resolve the caller's effective console permissions. Precedence:
//   custom role (role_key) → per-user override (permissions) → full access.
// Falls back to full access on installs where the columns aren't migrated yet.
async function attachPermissions(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT u.role, u.permissions, u.role_key, r.permissions AS role_perms
         FROM users u
         LEFT JOIN admin_roles r ON r.key = u.role_key
        WHERE u.id = $1`,
      [req.user.sub],
    );
    const u = rows[0] || {};
    if (u.role && u.role !== 'admin') {
      req.perms = [];
    } else if (u.role_key && u.role_perms != null) {
      req.perms = expandLegacy(u.role_perms);
    } else if (u.permissions != null) {
      req.perms = expandLegacy(u.permissions);
    } else {
      req.perms = PERMISSIONS.slice(); // super admin
    }
    return next();
  } catch (e) {
    // Not migrated yet (missing column 42703 / missing admin_roles table 42P01)
    // → treat as a full-access admin so the console keeps working.
    if (e && (e.code === '42703' || e.code === '42P01')) {
      req.perms = PERMISSIONS.slice();
      return next();
    }
    return res.status(500).json({ error: 'Authorization failed' });
  }
}

// Gate a route on a specific permission key.
function need(key) {
  return (req, res, next) =>
    (req.perms || []).includes(key)
      ? next()
      : res.status(403).json({ error: 'You do not have permission for this action.' });
}

// Everything here requires a valid admin token + loaded permissions.
router.use(requireAuth, requireRole('admin'), attachPermissions);

// GET /api/admin/me — the signed-in admin + their effective permissions.
router.get('/me', (req, res) => {
  res.json({
    id: req.user.sub,
    name: req.user.name,
    email: req.user.email,
    role: req.user.role,
    permissions: req.perms,
    allPermissions: PERMISSIONS,
    sections: SECTIONS,
  });
});

// GET /api/admin/overview — KPI tiles + tier breakdown.
router.get('/overview', async (_req, res) => {
  try {
    const [members, active, expiring, mrr, trainers, sessionsToday, tiers] =
      await Promise.all([
        db.query(`SELECT count(*)::int AS n FROM members`),
        db.query(
          `SELECT count(DISTINCT m.member_id)::int AS n
             FROM memberships m WHERE m.status = 'active'`,
        ),
        db.query(
          `SELECT count(*)::int AS n FROM memberships
            WHERE status = 'active'
              AND renews_on BETWEEN current_date AND current_date + 7`,
        ),
        db.query(
          `SELECT COALESCE(sum(price),0)::numeric AS total
             FROM memberships WHERE status = 'active'`,
        ),
        db.query(`SELECT count(*)::int AS n FROM trainers`),
        db.query(
          `SELECT count(*)::int AS n FROM workout_sessions
            WHERE started_at::date = current_date`,
        ),
        db.query(
          `SELECT tier, count(*)::int AS n
             FROM memberships WHERE status <> 'expired'
            GROUP BY tier`,
        ),
      ]);

    res.json({
      totalMembers: members.rows[0].n,
      activeMembers: active.rows[0].n,
      expiringSoon: expiring.rows[0].n,
      mrr: Number(mrr.rows[0].total),
      trainers: trainers.rows[0].n,
      sessionsToday: sessionsToday.rows[0].n,
      byTier: tiers.rows,
    });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load overview' });
  }
});

// GET /api/admin/members?query=&status=&page=&pageSize=
router.get('/members', need('members.view'), async (req, res) => {
  const query = (req.query.query || '').toString().trim();
  const status = (req.query.status || '').toString().trim();
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const pageSize = Math.min(50, Math.max(5, parseInt(req.query.pageSize, 10) || 10));
  const offset = (page - 1) * pageSize;

  const where = [];
  const params = [];
  if (query) {
    params.push(`%${query}%`);
    where.push(`(u.full_name ILIKE $${params.length} OR u.email ILIKE $${params.length})`);
  }
  if (status) {
    params.push(status);
    where.push(`ms.status = $${params.length}`);
  }
  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';

  try {
    // Latest membership per member via DISTINCT ON.
    const sql = `
      WITH latest AS (
        SELECT DISTINCT ON (member_id) member_id, tier, status, renews_on
          FROM memberships ORDER BY member_id, renews_on DESC
      )
      SELECT u.id, u.full_name, u.email, u.created_at, u.status AS account_status,
             ms.tier, ms.status, ms.renews_on,
             tu.full_name AS trainer_name,
             count(*) OVER()::int AS total
        FROM members mem
        JOIN users u ON u.id = mem.user_id
        LEFT JOIN latest ms ON ms.member_id = mem.user_id
        LEFT JOIN users tu ON tu.id = mem.trainer_id
        ${whereSql}
        ORDER BY u.created_at DESC
        LIMIT ${pageSize} OFFSET ${offset}`;
    const { rows } = await db.query(sql, params);
    const total = rows.length ? rows[0].total : 0;
    res.json({
      page,
      pageSize,
      total,
      rows: rows.map(({ total: _t, ...r }) => r),
    });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load members' });
  }
});

// GET /api/admin/members/:id — full detail.
router.get('/members/:id', need('members.view'), async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT u.id, u.full_name, u.email, u.phone, u.created_at,
              mem.goal, mem.experience, mem.height_cm, mem.weight_kg,
              mem.current_streak_days, tu.full_name AS trainer_name
         FROM members mem
         JOIN users u ON u.id = mem.user_id
         LEFT JOIN users tu ON tu.id = mem.trainer_id
        WHERE mem.user_id = $1`,
      [req.params.id],
    );
    if (!rows[0]) return res.status(404).json({ error: 'Member not found' });

    const [memberships, sessions] = await Promise.all([
      db.query(
        `SELECT tier, status, started_on, renews_on, price
           FROM memberships WHERE member_id = $1 ORDER BY renews_on DESC`,
        [req.params.id],
      ),
      db.query(
        `SELECT title, started_at, total_volume, pr_count
           FROM workout_sessions WHERE member_id = $1
          ORDER BY started_at DESC LIMIT 5`,
        [req.params.id],
      ),
    ]);

    res.json({
      ...rows[0],
      memberships: memberships.rows,
      recentSessions: sessions.rows,
    });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load member' });
  }
});

// PATCH /api/admin/members/:id  { status?, tier?, trainerId? }
router.patch('/members/:id', need('members.manage'), async (req, res) => {
  const { status, tier, trainerId, accountStatus } = req.body || {};
  if (accountStatus !== undefined && !['active', 'suspended'].includes(accountStatus)) {
    return res.status(400).json({ error: 'Invalid account status.' });
  }
  try {
    // Freeze/unfreeze the member's app account (blocks login).
    if (accountStatus !== undefined) {
      await db.query('UPDATE users SET status = $1, updated_at = now() WHERE id = $2', [
        accountStatus,
        req.params.id,
      ]);
    }
    if (trainerId !== undefined) {
      await db.query('UPDATE members SET trainer_id = $1 WHERE user_id = $2', [
        trainerId || null,
        req.params.id,
      ]);
    }
    if (status || tier) {
      // Update the member's latest membership row.
      await db.query(
        `UPDATE memberships SET
            status = COALESCE($1, status),
            tier   = COALESCE($2, tier)
          WHERE id = (
            SELECT id FROM memberships WHERE member_id = $3
             ORDER BY renews_on DESC LIMIT 1)`,
        [status || null, tier || null, req.params.id],
      );
    }
    await db.query(
      `INSERT INTO audit_log (admin_id, action, entity, entity_id)
       VALUES ($1, 'update_member', 'members', $2)`,
      [req.user.sub, req.params.id],
    );
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: 'Update failed' });
  }
});

// GET /api/admin/trainers — roster with client counts.
router.get('/trainers', need('trainers.view'), async (_req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT u.id, u.full_name, u.email, u.status AS account_status,
              t.specialty, t.rating, t.avg_response_h,
              count(m.user_id)::int AS clients
         FROM trainers t
         JOIN users u ON u.id = t.user_id
         LEFT JOIN members m ON m.trainer_id = t.user_id
        GROUP BY u.id, u.full_name, u.email, u.status, t.specialty, t.rating, t.avg_response_h
        ORDER BY clients DESC`,
    );
    res.json({ rows });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load trainers' });
  }
});

// PATCH /api/admin/trainers/:id  { status } — freeze/unfreeze a trainer's account.
router.patch('/trainers/:id', need('trainers.manage'), async (req, res) => {
  const { status } = req.body || {};
  if (!['active', 'suspended'].includes(status)) {
    return res.status(400).json({ error: 'Invalid account status.' });
  }
  try {
    const { rowCount } = await db.query(
      `UPDATE users SET status = $1, updated_at = now()
         WHERE id = $2 AND role = 'trainer'`,
      [status, req.params.id],
    );
    if (!rowCount) return res.status(404).json({ error: 'Trainer not found' });
    await db.query(
      `INSERT INTO audit_log (admin_id, action, entity, entity_id)
       VALUES ($1, 'update_trainer', 'trainers', $2)`,
      [req.user.sub, req.params.id],
    );
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: 'Failed to update trainer' });
  }
});

// GET /api/admin/plans — plan library.
router.get('/plans', need('plans.view'), async (_req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT id, name, split, days_per_week, weeks, goal, experience, avg_minutes
         FROM plans ORDER BY days_per_week`,
    );
    res.json({ rows });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load plans' });
  }
});

// ---------- Settings (currency) ----------

// GET /api/admin/settings — currency + the list of custom languages.
router.get('/settings', async (_req, res) => {
  try {
    const [s, locales] = await Promise.all([
      db.query(`SELECT value FROM app_settings WHERE key = 'currency'`),
      db.query(`SELECT code, name, dir FROM admin_locales ORDER BY name`),
    ]);
    let currency = { code: 'USD', symbol: '$', position: 'before' };
    if (s.rows[0]?.value) {
      try {
        currency = { ...currency, ...JSON.parse(s.rows[0].value) };
      } catch (_) {}
    }
    res.json({ currency, locales: locales.rows });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load settings' });
  }
});

// PUT /api/admin/settings — save the currency.
router.put('/settings', need('settings.manage'), async (req, res) => {
  const { currency } = req.body || {};
  if (!currency || typeof currency !== 'object') {
    return res.status(400).json({ error: 'currency object is required' });
  }
  const clean = {
    code: String(currency.code || 'USD').slice(0, 8).toUpperCase(),
    symbol: String(currency.symbol || '$').slice(0, 6),
    position: currency.position === 'after' ? 'after' : 'before',
  };
  try {
    await db.query(
      `INSERT INTO app_settings (key, value, updated_at)
         VALUES ('currency', $1, now())
       ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()`,
      [JSON.stringify(clean)],
    );
    await db.query(
      `INSERT INTO audit_log (admin_id, action, entity, entity_id)
       VALUES ($1, 'update_settings', 'app_settings', NULL)`,
      [req.user.sub],
    );
    res.json({ ok: true, currency: clean });
  } catch (e) {
    res.status(500).json({ error: 'Failed to save settings' });
  }
});

// ---------- Custom languages (added via CSV import) ----------

const CODE_RE = /^[a-z]{2,8}(-[a-z0-9]{2,8})?$/i;

// GET /api/admin/locales — list custom language codes/names.
router.get('/locales', async (_req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT code, name, dir FROM admin_locales ORDER BY name`,
    );
    res.json({ rows });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load languages' });
  }
});

// GET /api/admin/locales/:code — full string map for one custom language.
router.get('/locales/:code', async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT code, name, dir, strings FROM admin_locales WHERE code = $1`,
      [String(req.params.code).toLowerCase()],
    );
    if (!rows[0]) return res.status(404).json({ error: 'Language not found' });
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: 'Failed to load language' });
  }
});

// POST /api/admin/locales — create or replace a custom language.
// Body: { code, name, dir, strings:{key:value} } (parsed from the CSV client-side).
router.post('/locales', need('settings.manage'), async (req, res) => {
  const { code, name, dir, strings } = req.body || {};
  const c = String(code || '').trim().toLowerCase();
  if (!CODE_RE.test(c)) {
    return res.status(400).json({ error: 'Invalid language code (use e.g. es, tr, de).' });
  }
  if (['en', 'ar', 'fr'].includes(c)) {
    return res.status(400).json({ error: 'en, ar and fr are built in and cannot be overridden.' });
  }
  if (!name || typeof name !== 'string') {
    return res.status(400).json({ error: 'A language name is required.' });
  }
  if (!strings || typeof strings !== 'object' || Array.isArray(strings)) {
    return res.status(400).json({ error: 'strings must be an object of key → translation.' });
  }
  const d = dir === 'rtl' ? 'rtl' : 'ltr';
  try {
    await db.query(
      `INSERT INTO admin_locales (code, name, dir, strings, updated_at)
         VALUES ($1, $2, $3, $4::jsonb, now())
       ON CONFLICT (code) DO UPDATE
         SET name = EXCLUDED.name, dir = EXCLUDED.dir,
             strings = EXCLUDED.strings, updated_at = now()`,
      [c, name.trim().slice(0, 60), d, JSON.stringify(strings)],
    );
    res.json({ ok: true, code: c, name: name.trim(), dir: d });
  } catch (e) {
    res.status(500).json({ error: 'Failed to save language' });
  }
});

// DELETE /api/admin/locales/:code — remove a custom language.
router.delete('/locales/:code', need('settings.manage'), async (req, res) => {
  try {
    await db.query(`DELETE FROM admin_locales WHERE code = $1`, [
      String(req.params.code).toLowerCase(),
    ]);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: 'Failed to delete language' });
  }
});

// GET /api/admin/stats/growth — new members per week (last 12 weeks).
router.get('/stats/growth', async (_req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT to_char(date_trunc('week', u.created_at), 'MM-DD') AS week,
              count(*)::int AS signups
         FROM users u
         JOIN members m ON m.user_id = u.id
        WHERE u.created_at >= current_date - interval '12 weeks'
        GROUP BY 1 ORDER BY 1`,
    );
    res.json({ rows });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load growth' });
  }
});

// GET /api/admin/stats/revenue — paid revenue per month (last 6 months).
router.get('/stats/revenue', need('billing.view'), async (_req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT to_char(date_trunc('month', paid_at), 'YYYY-MM') AS month,
              sum(amount)::numeric AS revenue
         FROM payments WHERE status = 'paid'
          AND paid_at >= current_date - interval '6 months'
        GROUP BY 1 ORDER BY 1`,
    );
    res.json({ rows });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load revenue' });
  }
});

// ---------- User accounts, roles & permissions ----------

const ROLES = ['member', 'trainer', 'admin'];
const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

// Compute the (role_key, permissions) columns for a console user from the
// requested role plus either a custom role key or a per-user permissions
// array. Only admins carry either; a plain admin (both null) is full-access.
async function assignmentFor(role, roleKey, permsInput) {
  if (role !== 'admin') return { roleKey: null, permissions: null };
  if (roleKey) {
    const r = await db.query('SELECT key FROM admin_roles WHERE key = $1', [roleKey]);
    if (!r.rows[0]) return { error: 'Unknown role.' };
    return { roleKey, permissions: null };
  }
  if (Array.isArray(permsInput)) return { roleKey: null, permissions: cleanList(permsInput) };
  return { roleKey: null, permissions: null };
}

// Create the matching profile row so an admin-created trainer/member is usable
// in the app. No-op for admins; tolerant of races.
async function ensureProfileRow(userId, role) {
  if (role === 'trainer') {
    await db.query(
      'INSERT INTO trainers (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING',
      [userId],
    );
  } else if (role === 'member') {
    await db.query(
      'INSERT INTO members (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING',
      [userId],
    );
  }
}

// GET /api/admin/users?role=&query=
router.get('/users', need('users.view'), async (req, res) => {
  const role = (req.query.role || '').toString().trim();
  const query = (req.query.query || '').toString().trim();
  const where = [];
  const params = [];
  if (role && ROLES.includes(role)) {
    params.push(role);
    where.push(`role = $${params.length}`);
  }
  if (query) {
    params.push(`%${query}%`);
    where.push(`(full_name ILIKE $${params.length} OR email ILIKE $${params.length})`);
  }
  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
  try {
    const { rows } = await db.query(
      `SELECT id, full_name, email, role, status, permissions, role_key, created_at
         FROM users ${whereSql} ORDER BY created_at DESC LIMIT 200`,
      params,
    );
    res.json({ rows });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load users' });
  }
});

// POST /api/admin/users  { name, email, password, role, permissions[] }
router.post('/users', need('users.manage'), async (req, res) => {
  const { name, email, password, role } = req.body || {};
  const mail = String(email || '').trim().toLowerCase();
  if (!name || !mail || !password) {
    return res.status(400).json({ error: 'Name, email and password are required.' });
  }
  if (!EMAIL_RE.test(mail)) return res.status(400).json({ error: 'Enter a valid email.' });
  if (String(password).length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters.' });
  }
  if (!ROLES.includes(role)) return res.status(400).json({ error: 'Invalid role.' });
  const asn = await assignmentFor(role, req.body.roleKey, req.body.permissions);
  if (asn.error) return res.status(400).json({ error: asn.error });
  try {
    const hash = await bcrypt.hash(String(password), 10);
    const { rows } = await db.query(
      `INSERT INTO users (email, password_hash, full_name, role, permissions, role_key)
         VALUES ($1, $2, $3, $4, $5::jsonb, $6)
       RETURNING id, full_name, email, role, status, permissions, role_key, created_at`,
      [mail, hash, String(name).trim(), role,
        asn.permissions == null ? null : JSON.stringify(asn.permissions), asn.roleKey],
    );
    await ensureProfileRow(rows[0].id, role);
    await db.query(
      `INSERT INTO audit_log (admin_id, action, entity, entity_id)
       VALUES ($1, 'create_user', 'users', $2)`,
      [req.user.sub, rows[0].id],
    );
    res.status(201).json(rows[0]);
  } catch (e) {
    if (e && e.code === '23505') {
      return res.status(409).json({ error: 'A user with that email already exists.' });
    }
    res.status(500).json({ error: 'Failed to create user' });
  }
});

// PATCH /api/admin/users/:id  { name?, role?, status?, permissions?, password? }
router.patch('/users/:id', need('users.manage'), async (req, res) => {
  const { name, role, status, password } = req.body || {};
  const id = req.params.id;
  if (role !== undefined && !ROLES.includes(role)) {
    return res.status(400).json({ error: 'Invalid role.' });
  }
  if (status !== undefined && !['active', 'suspended'].includes(status)) {
    return res.status(400).json({ error: 'Invalid status.' });
  }
  try {
    // Resolve the effective role to normalise permissions against.
    const cur = await db.query('SELECT role FROM users WHERE id = $1', [id]);
    if (!cur.rows[0]) return res.status(404).json({ error: 'User not found' });
    const effRole = role !== undefined ? role : cur.rows[0].role;

    // Don't let an admin strip their own admin role / lock themselves out.
    if (id === req.user.sub && role !== undefined && role !== 'admin') {
      return res.status(400).json({ error: 'You cannot change your own role.' });
    }

    const sets = [];
    const params = [];
    if (name !== undefined) {
      params.push(String(name).trim());
      sets.push(`full_name = $${params.length}`);
    }
    if (role !== undefined) {
      params.push(role);
      sets.push(`role = $${params.length}`);
    }
    if (status !== undefined) {
      params.push(status);
      sets.push(`status = $${params.length}`);
    }
    if (req.body.permissions !== undefined || req.body.roleKey !== undefined || role !== undefined) {
      const asn = await assignmentFor(effRole, req.body.roleKey, req.body.permissions);
      if (asn.error) return res.status(400).json({ error: asn.error });
      params.push(asn.permissions == null ? null : JSON.stringify(asn.permissions));
      sets.push(`permissions = $${params.length}::jsonb`);
      params.push(asn.roleKey);
      sets.push(`role_key = $${params.length}`);
    }
    if (password !== undefined) {
      if (String(password).length < 6) {
        return res.status(400).json({ error: 'Password must be at least 6 characters.' });
      }
      params.push(await bcrypt.hash(String(password), 10));
      sets.push(`password_hash = $${params.length}`);
    }
    if (!sets.length) return res.json({ ok: true });

    params.push(id);
    const { rows } = await db.query(
      `UPDATE users SET ${sets.join(', ')}, updated_at = now()
         WHERE id = $${params.length}
       RETURNING id, full_name, email, role, status, permissions, role_key, created_at`,
      params,
    );
    if (role !== undefined) await ensureProfileRow(id, role);
    await db.query(
      `INSERT INTO audit_log (admin_id, action, entity, entity_id)
       VALUES ($1, 'update_user', 'users', $2)`,
      [req.user.sub, id],
    );
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: 'Failed to update user' });
  }
});

// DELETE /api/admin/users/:id
router.delete('/users/:id', need('users.manage'), async (req, res) => {
  const id = req.params.id;
  if (id === req.user.sub) {
    return res.status(400).json({ error: 'You cannot delete your own account.' });
  }
  try {
    // Never remove the last remaining admin.
    const target = await db.query('SELECT role FROM users WHERE id = $1', [id]);
    if (!target.rows[0]) return res.status(404).json({ error: 'User not found' });
    if (target.rows[0].role === 'admin') {
      const { rows } = await db.query(
        `SELECT count(*)::int AS n FROM users WHERE role = 'admin'`,
      );
      if (rows[0].n <= 1) {
        return res.status(400).json({ error: 'Cannot delete the last admin account.' });
      }
    }
    await db.query('DELETE FROM users WHERE id = $1', [id]);
    await db.query(
      `INSERT INTO audit_log (admin_id, action, entity, entity_id)
       VALUES ($1, 'delete_user', 'users', $2)`,
      [req.user.sub, id],
    );
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

// ---------- Custom roles (permission bundles) ----------

const ROLE_KEY_RE = /^[a-z0-9][a-z0-9_-]{1,31}$/;

function slugify(s) {
  return String(s || '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 32);
}

// GET /api/admin/roles — custom roles + the permission catalogue.
router.get('/roles', need('users.view'), async (_req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT key, name, permissions, is_system,
              (SELECT count(*)::int FROM users u WHERE u.role_key = admin_roles.key) AS users
         FROM admin_roles ORDER BY is_system DESC, name`,
    );
    res.json({ rows, allPermissions: PERMISSIONS, sections: SECTIONS });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load roles' });
  }
});

// POST /api/admin/roles  { key?, name, permissions[] }
router.post('/roles', need('users.manage'), async (req, res) => {
  const name = String(req.body.name || '').trim();
  if (!name) return res.status(400).json({ error: 'A role name is required.' });
  const key = (req.body.key && String(req.body.key).toLowerCase()) || slugify(name);
  if (!ROLE_KEY_RE.test(key)) {
    return res.status(400).json({ error: 'Invalid role key (use letters, numbers, - or _).' });
  }
  const permissions = cleanList(req.body.permissions);
  try {
    const { rows } = await db.query(
      `INSERT INTO admin_roles (key, name, permissions, updated_at)
         VALUES ($1, $2, $3::jsonb, now())
       ON CONFLICT (key) DO UPDATE
         SET name = EXCLUDED.name, permissions = EXCLUDED.permissions, updated_at = now()
       RETURNING key, name, permissions, is_system`,
      [key, name.slice(0, 60), JSON.stringify(permissions)],
    );
    await db.query(
      `INSERT INTO audit_log (admin_id, action, entity, entity_id)
       VALUES ($1, 'save_role', 'admin_roles', NULL)`,
      [req.user.sub],
    );
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: 'Failed to save role' });
  }
});

// PATCH /api/admin/roles/:key  { name?, permissions? } — not for system roles.
router.patch('/roles/:key', need('users.manage'), async (req, res) => {
  const key = String(req.params.key).toLowerCase();
  try {
    const cur = await db.query('SELECT is_system FROM admin_roles WHERE key = $1', [key]);
    if (!cur.rows[0]) return res.status(404).json({ error: 'Role not found' });
    if (cur.rows[0].is_system) {
      return res.status(400).json({ error: 'System roles cannot be edited.' });
    }
    const sets = [];
    const params = [];
    if (req.body.name !== undefined) {
      params.push(String(req.body.name).trim().slice(0, 60));
      sets.push(`name = $${params.length}`);
    }
    if (req.body.permissions !== undefined) {
      params.push(JSON.stringify(cleanList(req.body.permissions)));
      sets.push(`permissions = $${params.length}::jsonb`);
    }
    if (!sets.length) return res.json({ ok: true });
    params.push(key);
    const { rows } = await db.query(
      `UPDATE admin_roles SET ${sets.join(', ')}, updated_at = now()
         WHERE key = $${params.length}
       RETURNING key, name, permissions, is_system`,
      params,
    );
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: 'Failed to update role' });
  }
});

// DELETE /api/admin/roles/:key — downgrades its users to no console access.
router.delete('/roles/:key', need('users.manage'), async (req, res) => {
  const key = String(req.params.key).toLowerCase();
  try {
    const cur = await db.query('SELECT is_system FROM admin_roles WHERE key = $1', [key]);
    if (!cur.rows[0]) return res.status(404).json({ error: 'Role not found' });
    if (cur.rows[0].is_system) {
      return res.status(400).json({ error: 'System roles cannot be deleted.' });
    }
    // Detach users from the role safely: no role, no access (never full access).
    await db.query(
      `UPDATE users SET role_key = NULL, permissions = '[]'::jsonb WHERE role_key = $1`,
      [key],
    );
    await db.query('DELETE FROM admin_roles WHERE key = $1', [key]);
    await db.query(
      `INSERT INTO audit_log (admin_id, action, entity, entity_id)
       VALUES ($1, 'delete_role', 'admin_roles', NULL)`,
      [req.user.sub],
    );
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: 'Failed to delete role' });
  }
});

// ---------- Activity / audit log ----------

// GET /api/admin/audit?page= — recent admin actions.
router.get('/audit', need('users.view'), async (req, res) => {
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const pageSize = 20;
  const offset = (page - 1) * pageSize;
  try {
    const { rows } = await db.query(
      `SELECT a.action, a.entity, a.entity_id, a.at,
              u.full_name AS admin_name, u.email AS admin_email,
              count(*) OVER()::int AS total
         FROM audit_log a
         LEFT JOIN users u ON u.id = a.admin_id
        ORDER BY a.at DESC
        LIMIT $1 OFFSET $2`,
      [pageSize, offset],
    );
    const total = rows.length ? rows[0].total : 0;
    res.json({ page, pageSize, total, rows: rows.map(({ total: _t, ...r }) => r) });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load activity' });
  }
});

module.exports = router;
