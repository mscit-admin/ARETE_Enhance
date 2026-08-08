// Canonical admin-console permission keys. A user account (role 'admin') can
// be granted any subset; an admin whose permissions column is NULL has full
// access (keeps existing/seed admins working after the column is added).
const PERMISSIONS = ['members', 'trainers', 'plans', 'billing', 'settings', 'users'];

module.exports = { PERMISSIONS };
