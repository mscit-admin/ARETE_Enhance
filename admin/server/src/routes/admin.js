const express = require('express');
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');

const router = express.Router();

// Everything here requires a valid admin token.
router.use(requireAuth, requireRole('admin'));

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
router.get('/members', async (req, res) => {
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
      SELECT u.id, u.full_name, u.email, u.created_at,
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
router.get('/members/:id', async (req, res) => {
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
router.patch('/members/:id', async (req, res) => {
  const { status, tier, trainerId } = req.body || {};
  try {
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
router.get('/trainers', async (_req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT u.id, u.full_name, u.email, t.specialty, t.rating, t.avg_response_h,
              count(m.user_id)::int AS clients
         FROM trainers t
         JOIN users u ON u.id = t.user_id
         LEFT JOIN members m ON m.trainer_id = t.user_id
        GROUP BY u.id, u.full_name, u.email, t.specialty, t.rating, t.avg_response_h
        ORDER BY clients DESC`,
    );
    res.json({ rows });
  } catch (e) {
    res.status(500).json({ error: 'Failed to load trainers' });
  }
});

// GET /api/admin/plans — plan library.
router.get('/plans', async (_req, res) => {
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
router.get('/stats/revenue', async (_req, res) => {
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

module.exports = router;
