const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../db');
const { signToken } = require('../middleware/auth');

const router = express.Router();

// POST /api/auth/login  { email, password }
router.post('/login', async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }
  try {
    const { rows } = await db.query(
      'SELECT id, email, full_name, role, password_hash FROM users WHERE email = $1',
      [String(email).trim().toLowerCase()],
    );
    const user = rows[0];
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });

    // The web console is admin-only.
    if (user.role !== 'admin') {
      return res.status(403).json({ error: 'This console is for admins only' });
    }

    const token = signToken(user);
    return res.json({
      token,
      user: { id: user.id, name: user.full_name, email: user.email, role: user.role },
    });
  } catch (e) {
    return res.status(500).json({ error: 'Login failed' });
  }
});

module.exports = router;
