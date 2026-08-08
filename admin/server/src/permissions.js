// Admin-console permissions. Each console section splits into a ".view"
// permission (open the section) and a ".manage" permission (make changes).
// A user's permissions can come from an assigned custom role, a per-user
// override, or — for a full-access admin — NULL (everything).
const SECTIONS = ['members', 'trainers', 'plans', 'billing', 'settings', 'users'];

const PERMISSIONS = SECTIONS.flatMap((s) => [`${s}.view`, `${s}.manage`]);

// Map any older bare keys (e.g. 'members') to the new view+manage pair, and
// drop anything unrecognised. Keeps existing saved permission sets working.
function expandLegacy(list) {
  if (!Array.isArray(list)) return [];
  const out = new Set();
  for (const k of list) {
    if (SECTIONS.includes(k)) {
      out.add(`${k}.view`);
      out.add(`${k}.manage`);
    } else if (PERMISSIONS.includes(k)) {
      out.add(k);
    }
  }
  return [...out];
}

// Keep only valid permission keys from a raw list.
function cleanList(list) {
  if (!Array.isArray(list)) return [];
  return PERMISSIONS.filter((p) => list.includes(p));
}

module.exports = { SECTIONS, PERMISSIONS, expandLegacy, cleanList };
