const jwt = require('jsonwebtoken');

const SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';

function signToken(user) {
  return jwt.sign(
    { sub: user.id, role: user.role, name: user.full_name, email: user.email },
    SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '12h' },
  );
}

// Verifies the Bearer token and attaches req.user.
function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Missing token' });
  try {
    req.user = jwt.verify(token, SECRET);
    return next();
  } catch (_) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
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
