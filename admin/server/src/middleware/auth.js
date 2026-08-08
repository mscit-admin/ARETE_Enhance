const jwt = require('jsonwebtoken');
const db = require('../db');

const SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';

function signToken(user) {
  return jwt.sign(
    { sub: user.id, role: user.role, name: user.full_name, email: user.email },
    SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '12h' },
  );
}

// Verifies the Bearer token, confirms the account is still active, and
// attaches req.user. The status check makes a freeze take effect immediately
// on the next request, not only at the next sign-in.
async function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Missing token' });

  let payload;
  try {
    payload = jwt.verify(token, SECRET);
  } catch (_) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }

  try {
    const { rows } = await db.query('SELECT status FROM users WHERE id = $1', [payload.sub]);
    if (!rows[0]) return res.status(401).json({ error: 'Account not found' });
    if (rows[0].status === 'suspended') {
      return res
        .status(403)
        .json({ error: 'Your account has been suspended.', code: 'account_suspended' });
    }
  } catch (e) {
    return res.status(500).json({ error: 'Authorization failed' });
  }

  req.user = payload;
  return next();
}

// Requires a specific role (use after requireAuth).
function requireRole(role) {
  return (req, res, next) => {
    if (!req.user || req.user.role !== role) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    return next();
  };
}

module.exports = { signToken, requireAuth, requireRole, SECRET };
