const path = require('path');
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');

const app = express();

app.use(cors());
app.use(express.json());

// Health check
app.get('/api/health', (_req, res) => res.json({ ok: true }));

// API
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);

// Serve the static admin web dashboard from ../../web
const webDir = path.join(__dirname, '..', '..', 'web');
app.use(express.static(webDir));
app.get('/', (_req, res) => res.sendFile(path.join(webDir, 'index.html')));

module.exports = app;
