// ARETE admin dashboard — vanilla JS, talks to /api/admin/*.
const token = localStorage.getItem('arete_token');
if (!token) location.replace('index.html');

const user = JSON.parse(localStorage.getItem('arete_user') || '{}');
let me = null; // { id, name, email, role, permissions, allPermissions, sections }

// Hide nav sections the signed-in admin lacks permission for. A null
// permissions list (older server / super admin) shows everything.
function applyNavVisibility() {
  const need = {
    members: 'members.view', trainers: 'trainers.view', plans: 'plans.view',
    settings: 'settings.view', users: 'users.view', roles: 'users.view', audit: 'users.view',
  };
  const perms = me && me.permissions ? me.permissions : null;
  document.querySelectorAll('.nav a[data-section]').forEach((a) => {
    const key = need[a.dataset.section];
    const allowed = !key || !perms || perms.includes(key);
    a.style.display = allowed ? '' : 'none';
  });
}

async function api(path) {
  const res = await fetch(`/api${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (res.status === 401) {
    logout();
    throw new Error('Session expired');
  }
  if (!res.ok) throw new Error((await res.json()).error || 'Request failed');
  return res.json();
}

async function apiSend(method, path, body) {
  const res = await fetch(`/api${path}`, {
    method,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (res.status === 401) {
    logout();
    throw new Error('Session expired');
  }
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || 'Request failed');
  return data;
}

function logout() {
  localStorage.removeItem('arete_token');
  localStorage.removeItem('arete_user');
  location.replace('index.html');
}
document.getElementById('logout').addEventListener('click', logout);

function initials(name) {
  const p = (name || '?').trim().split(/\s+/);
  return ((p[0]?.[0] || '') + (p.length > 1 ? p[p.length - 1][0] : '')).toUpperCase();
}
const money = (n) => I18N.money(n);
function fmtDate(s) {
  if (!s) return '—';
  const opts = { month: 'short', day: 'numeric' };
  try {
    return new Date(s).toLocaleDateString(I18N.getLocale(), opts);
  } catch (_) {
    return new Date(s).toLocaleDateString(undefined, opts);
  }
}

// ---------- Language ----------
const langSel = document.getElementById('lang');
function fillLangSelectors() {
  langSel.innerHTML = I18N.available()
    .map((l) => `<option value="${l.code}">${l.name}</option>`)
    .join('');
  langSel.value = I18N.getLocale();
}
langSel.addEventListener('change', () => {
  I18N.setLocale(langSel.value); // applies static data-i18n + sets dir/lang
  refreshActive(); // re-render JS-built content in the new language
});

function refreshActive() {
  const active = document.querySelector('.nav a.active')?.dataset.section || 'overview';
  document.getElementById('pageTitle').textContent = I18N.t('nav.' + active);
  document.getElementById('whoName').textContent = user.name || I18N.t('head.admin');
  document.getElementById('whoAv').textContent = (user.name || 'A').slice(0, 1).toUpperCase();
  if (active === 'overview') loadOverview();
  else if (active === 'members') loadMembers();
  else if (active === 'trainers') loadTrainers();
  else if (active === 'plans') loadPlans();
  else if (active === 'users') loadUsers();
  else if (active === 'roles') loadRoles();
  else if (active === 'audit') loadAudit();
  else if (active === 'settings') loadSettings();
}

// ---------- Navigation ----------
document.querySelectorAll('.nav a[data-section]').forEach((a) => {
  a.addEventListener('click', () => {
    const s = a.dataset.section;
    document.querySelectorAll('.nav a[data-section]').forEach((x) => x.classList.remove('active'));
    a.classList.add('active');
    document.querySelectorAll('.section').forEach((x) => x.classList.remove('active'));
    document.getElementById('section-' + s).classList.add('active');
    document.getElementById('pageTitle').textContent = I18N.t('nav.' + s);
    if (s === 'members') loadMembers();
    if (s === 'trainers') loadTrainers();
    if (s === 'plans') loadPlans();
    if (s === 'users') loadUsers();
    if (s === 'roles') loadRoles();
    if (s === 'audit') loadAudit();
    if (s === 'settings') loadSettings();
  });
});

// ---------- Overview ----------
async function loadOverview() {
  try {
    const [o, growth] = await Promise.all([
      api('/admin/overview'),
      api('/admin/stats/growth'),
    ]);

    const kpis = [
      { l: I18N.t('kpi.totalMembers'), v: o.totalMembers, d: '', c: '' },
      { l: I18N.t('kpi.active'), v: o.activeMembers, d: I18N.t('kpi.activeDesc'), c: 'up' },
      { l: I18N.t('kpi.expiring'), v: o.expiringSoon, d: I18N.t('kpi.expiringDesc'), c: 'down' },
      { l: I18N.t('kpi.mrr'), v: money(o.mrr), d: I18N.t('kpi.mrrDesc', { trainers: o.trainers, sessions: o.sessionsToday }), c: 'up' },
    ];
    document.getElementById('kpis').innerHTML = kpis.map((k) => `
      <div class="kpi"><div class="l">${k.l}</div>
        <div class="v tabular">${k.v}</div>
        <div class="d ${k.c}">${k.d}</div></div>`).join('');

    const max = Math.max(1, ...growth.rows.map((r) => r.signups));
    document.getElementById('growth').innerHTML = growth.rows.map((r, i) => {
      const h = Math.round((r.signups / max) * 100);
      const last = i === growth.rows.length - 1 ? 'last' : '';
      return `<div class="b ${last}" style="height:${h}%" title="${r.week}: ${r.signups}"></div>`;
    }).join('') || `<span class="muted">${I18N.t('common.noData')}</span>`;

    const total = o.byTier.reduce((s, t) => s + t.n, 0) || 1;
    const order = { elite: 0, gold: 1, silver: 2, basic: 3 };
    const rows = [...o.byTier].sort((a, b) => order[a.tier] - order[b.tier]);
    document.getElementById('tiers').innerHTML = rows.map((t) => `
      <tr><td style="text-transform:capitalize">${t.tier}</td>
        <td class="rt tabular">${t.n}</td>
        <td class="rt muted tabular">${Math.round((t.n / total) * 100)}%</td></tr>`).join('');
  } catch (e) {
    document.getElementById('kpis').innerHTML = `<div class="muted">${e.message}</div>`;
  }
}

// ---------- Members ----------
let page = 1;
let membersState = { total: 0, pageSize: 10 };

async function loadMembers() {
  const q = document.getElementById('q').value.trim();
  const status = document.getElementById('statusFilter').value;
  try {
    const data = await api(
      `/admin/members?query=${encodeURIComponent(q)}&status=${status}&page=${page}`,
    );
    membersState = data;
    const body = data.rows.map((m) => `
      <tr>
        <td><div class="who2"><div class="a">${initials(m.full_name)}</div>
          <div><div>${m.full_name}</div><div class="muted" style="font-size:11px">${m.email}</div></div></div></td>
        <td style="text-transform:capitalize">${m.tier || '—'}</td>
        <td>${m.trainer_name || '<span class="muted">—</span>'}</td>
        <td><span class="pill ${m.status || 'expired'}">${m.status ? I18N.t('status.' + m.status) : '—'}</span></td>
        <td class="rt">${fmtDate(m.renews_on)}</td>
      </tr>`).join('');
    document.getElementById('membersTable').innerHTML = `
      <thead><tr><th>${I18N.t('table.member')}</th><th>${I18N.t('table.tier')}</th><th>${I18N.t('table.trainer')}</th><th>${I18N.t('table.status')}</th><th class="rt">${I18N.t('table.renews')}</th></tr></thead>
      <tbody>${body || `<tr><td colspan="5" class="muted">${I18N.t('members.none')}</td></tr>`}</tbody>`;

    const pages = Math.max(1, Math.ceil(data.total / data.pageSize));
    document.getElementById('pageInfo').textContent =
      I18N.t('pager.info', { page: data.page, pages, total: data.total });
    document.getElementById('prev').disabled = page <= 1;
    document.getElementById('next').disabled = page >= pages;
  } catch (e) {
    document.getElementById('membersTable').innerHTML = `<tbody><tr><td class="muted">${e.message}</td></tr></tbody>`;
  }
}
let searchTimer;
document.getElementById('q').addEventListener('input', () => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => { page = 1; loadMembers(); }, 250);
});
document.getElementById('statusFilter').addEventListener('change', () => { page = 1; loadMembers(); });
document.getElementById('prev').addEventListener('click', () => { if (page > 1) { page--; loadMembers(); } });
document.getElementById('next').addEventListener('click', () => { page++; loadMembers(); });

// ---------- Trainers ----------
async function loadTrainers() {
  try {
    const data = await api('/admin/trainers');
    const body = data.rows.map((t) => `
      <tr><td><div class="who2"><div class="a">${initials(t.full_name)}</div>${t.full_name}</div></td>
        <td>${t.specialty || '—'}</td>
        <td class="rt tabular">${t.clients}</td>
        <td class="rt tabular">${Number(t.rating).toFixed(1)}</td>
        <td class="rt tabular">~${t.avg_response_h}h</td></tr>`).join('');
    document.getElementById('trainersTable').innerHTML = `
      <thead><tr><th>${I18N.t('table.trainer')}</th><th>${I18N.t('table.specialty')}</th><th class="rt">${I18N.t('table.clients')}</th><th class="rt">${I18N.t('table.rating')}</th><th class="rt">${I18N.t('table.reply')}</th></tr></thead>
      <tbody>${body}</tbody>`;
  } catch (e) {
    document.getElementById('trainersTable').innerHTML = `<tbody><tr><td class="muted">${e.message}</td></tr></tbody>`;
  }
}

// ---------- Plans ----------
async function loadPlans() {
  try {
    const data = await api('/admin/plans');
    const body = data.rows.map((p) => `
      <tr><td>${p.name}</td><td>${p.split || '—'}</td>
        <td class="rt tabular">${p.days_per_week}</td>
        <td style="text-transform:capitalize">${(p.goal || '').replace('_', ' ')}</td>
        <td style="text-transform:capitalize">${p.experience || '—'}</td></tr>`).join('');
    document.getElementById('plansTable').innerHTML = `
      <thead><tr><th>${I18N.t('table.plan')}</th><th>${I18N.t('table.split')}</th><th class="rt">${I18N.t('table.days')}</th><th>${I18N.t('table.goal')}</th><th>${I18N.t('table.level')}</th></tr></thead>
      <tbody>${body}</tbody>`;
  } catch (e) {
    document.getElementById('plansTable').innerHTML = `<tbody><tr><td class="muted">${e.message}</td></tr></tbody>`;
  }
}

// ---------- Settings ----------
function loadSettings() {
  const cur = I18N.getCurrency();
  const sel = document.getElementById('currencySel');
  sel.innerHTML = I18N.CURRENCIES.map((c) => `<option value="${c.code}">${c.code} — ${c.symbol}</option>`).join('');
  sel.value = cur.code;
  document.getElementById('currencyPos').value = cur.position;
  renderCustomLangs();
}

document.getElementById('saveCurrency').addEventListener('click', async () => {
  const msg = document.getElementById('currencyMsg');
  const code = document.getElementById('currencySel').value;
  const symbol = (I18N.CURRENCIES.find((c) => c.code === code) || {}).symbol || '$';
  const position = document.getElementById('currencyPos').value;
  try {
    await apiSend('PUT', '/admin/settings', { currency: { code, symbol, position } });
    I18N.setCurrency({ code, symbol, position });
    msg.textContent = I18N.t('settings.saved');
    msg.className = 'ok-msg show';
    setTimeout(() => msg.classList.remove('show'), 2000);
  } catch (e) {
    msg.textContent = e.message || I18N.t('settings.saveFailed');
    msg.className = 'ok-msg show err';
  }
});

document.getElementById('dlTemplate').addEventListener('click', () => {
  I18N.download('arete-translations-template.csv', I18N.buildTemplateCSV());
});

document.getElementById('uploadLang').addEventListener('click', async () => {
  const msg = document.getElementById('langMsg');
  const code = document.getElementById('langCode').value.trim().toLowerCase();
  const name = document.getElementById('langName').value.trim();
  const dir = document.getElementById('langDir').value;
  const file = document.getElementById('langCsv').files[0];
  const fail = (key) => { msg.textContent = I18N.t(key); msg.className = 'ok-msg show err'; };

  if (!code || !name) return fail('settings.needCode');
  if (!file) return fail('settings.badCsv');
  try {
    const text = await file.text();
    const strings = I18N.stringsFromCSV(text);
    if (!strings) return fail('settings.badCsv');
    await apiSend('POST', '/admin/locales', { code, name, dir, strings });
    I18N.upsertCustom(code, { name, dir, strings });
    fillLangSelectors();
    renderCustomLangs();
    document.getElementById('langCode').value = '';
    document.getElementById('langName').value = '';
    document.getElementById('langCsv').value = '';
    msg.textContent = I18N.t('settings.uploaded');
    msg.className = 'ok-msg show';
  } catch (e) {
    msg.textContent = e.message;
    msg.className = 'ok-msg show err';
  }
});

function renderCustomLangs() {
  const base = ['en', 'ar', 'fr'];
  const items = I18N.available().filter((l) => !base.includes(l.code));
  const el = document.getElementById('customLangs');
  if (!items.length) {
    el.innerHTML = `<div class="muted">${I18N.t('settings.noCustom')}</div>`;
    return;
  }
  el.innerHTML = items.map((l) => `
    <div class="lang-row">
      <span>${l.name} <span class="muted">(${l.code} · ${l.dir})</span></span>
      <button class="btn ghost sm" data-del="${l.code}">${I18N.t('settings.delete')}</button>
    </div>`).join('');
  el.querySelectorAll('[data-del]').forEach((b) => {
    b.addEventListener('click', async () => {
      if (!confirm(I18N.t('settings.confirmDelete'))) return;
      try {
        await apiSend('DELETE', `/admin/locales/${b.dataset.del}`);
        I18N.removeCustom(b.dataset.del);
        if (I18N.getLocale() === b.dataset.del) I18N.setLocale('en');
        fillLangSelectors();
        renderCustomLangs();
      } catch (e) {
        alert(e.message);
      }
    });
  });
}

// ---------- Shared helpers: permission matrix + role cache ----------
let rolesCache = []; // [{key,name,permissions,is_system,users}]

function sectionsOf() {
  return (me && me.sections) || ['members', 'trainers', 'plans', 'billing', 'settings', 'users'];
}
function tOr(key, fallback) {
  const v = I18N.t(key);
  return v === key ? fallback : v;
}

// A per-section grid of View + Manage checkboxes. Manage auto-implies View.
function buildPermMatrix(containerId, selected) {
  const set = new Set(selected || []);
  document.getElementById(containerId).innerHTML = sectionsOf().map((s) => `
    <div class="perm-sec">
      <div class="perm-sec-name">${I18N.t('perm.' + s)}</div>
      <label><input type="checkbox" data-perm="${s}.view" ${set.has(s + '.view') ? 'checked' : ''}/> ${I18N.t('common.view')}</label>
      <label><input type="checkbox" data-perm="${s}.manage" ${set.has(s + '.manage') ? 'checked' : ''}/> ${I18N.t('common.manage')}</label>
    </div>`).join('');
  document.querySelectorAll(`#${containerId} input[data-perm$=".manage"]`).forEach((mb) => {
    mb.addEventListener('change', () => {
      if (mb.checked) {
        const v = mb.closest('.perm-sec').querySelector('input[data-perm$=".view"]');
        if (v) v.checked = true;
      }
    });
  });
}
function readPermMatrix(containerId) {
  return [...document.querySelectorAll(`#${containerId} input[data-perm]:checked`)].map((i) => i.dataset.perm);
}
function sectionsSummary(perms) {
  const p = perms || [];
  const out = sectionsOf()
    .filter((s) => p.includes(s + '.view') || p.includes(s + '.manage'))
    .map((s) => I18N.t('perm.' + s) + (p.includes(s + '.manage') ? ' ✎' : ''));
  return out.length ? out.join(', ') : '—';
}

async function fetchRoles() {
  try {
    const d = await api('/admin/roles');
    rolesCache = d.rows || [];
  } catch (_) {
    rolesCache = [];
  }
}

// ---------- Users ----------
let editingUserId = null;

function roleBadge(role) {
  return `<span class="role-badge ${role}">${I18N.t('role.' + role)}</span>`;
}
function permsSummary(u) {
  if (u.role !== 'admin') return `<span class="muted">${I18N.t('users.noConsole')}</span>`;
  if (u.role_key) {
    const r = rolesCache.find((x) => x.key === u.role_key);
    return `<span class="role-badge admin">${r ? r.name : u.role_key}</span>`;
  }
  const p = u.permissions;
  if (p == null) return I18N.t('users.fullAccess');
  if (!p.length) return `<span class="muted">${I18N.t('users.noConsole')}</span>`;
  return sectionsSummary(p);
}

function fillAccessSelect(u) {
  const opts = [`<option value="__full__">${I18N.t('users.fullAccessOpt')}</option>`];
  rolesCache.filter((r) => !r.is_system).forEach((r) => {
    opts.push(`<option value="role:${r.key}">${r.name}</option>`);
  });
  opts.push(`<option value="__custom__">${I18N.t('users.customOpt')}</option>`);
  const sel = document.getElementById('uAccess');
  sel.innerHTML = opts.join('');
  let val = '__full__';
  if (u && u.role === 'admin') {
    if (u.role_key) val = 'role:' + u.role_key;
    else if (u.permissions != null) val = '__custom__';
  }
  sel.value = [...sel.options].some((o) => o.value === val) ? val : '__full__';
}

function updateAccessUI(currentPerms) {
  const v = document.getElementById('uAccess').value;
  document.getElementById('uMatrixWrap').style.display = v === '__custom__' ? '' : 'none';
  if (v === '__custom__') buildPermMatrix('uPerms', currentPerms || []);
}
function toggleUserAccessBlock() {
  const role = document.getElementById('uRole').value;
  document.getElementById('uPermsWrap').style.display = role === 'admin' ? '' : 'none';
}

function showUserForm(u) {
  editingUserId = u ? u.id : null;
  document.getElementById('userFormTitle').textContent = I18N.t(u ? 'users.edit' : 'users.add');
  document.getElementById('uName').value = u ? u.full_name : '';
  document.getElementById('uEmail').value = u ? u.email : '';
  document.getElementById('uEmail').disabled = !!u; // email is the identity — immutable on edit
  document.getElementById('uRole').value = u ? u.role : 'admin';
  document.getElementById('uStatus').value = u ? u.status || 'active' : 'active';
  document.getElementById('uPassword').value = '';
  document.getElementById('uPwLabel').textContent = I18N.t(u ? 'users.newPassword' : 'users.password');
  document.getElementById('uPwHint').style.display = u ? '' : 'none';
  fillAccessSelect(u);
  toggleUserAccessBlock();
  updateAccessUI(u && u.role === 'admin' ? u.permissions || [] : []);
  const msg = document.getElementById('userMsg');
  msg.className = 'ok-msg';
  msg.textContent = '';
  document.getElementById('userFormCard').style.display = '';
}
function hideUserForm() {
  document.getElementById('userFormCard').style.display = 'none';
  editingUserId = null;
}

// Build the { roleKey?, permissions? } body from the access selector.
function accessBody(role) {
  if (role !== 'admin') return {};
  const v = document.getElementById('uAccess').value;
  if (v.startsWith('role:')) return { roleKey: v.slice(5) };
  if (v === '__custom__') return { roleKey: '', permissions: readPermMatrix('uPerms') };
  return { roleKey: '' }; // full access
}

async function loadUsers() {
  const q = document.getElementById('uq').value.trim();
  const role = document.getElementById('uRoleFilter').value;
  try {
    const data = await api(`/admin/users?query=${encodeURIComponent(q)}&role=${role}`);
    const body = data.rows.map((u) => `
      <tr>
        <td><div class="who2"><div class="a">${initials(u.full_name)}</div>
          <div><div>${u.full_name}</div><div class="muted" style="font-size:11px">${u.email}</div></div></div></td>
        <td>${roleBadge(u.role)}</td>
        <td>${permsSummary(u)}</td>
        <td><span class="pill ${u.status === 'active' ? 'active' : 'expired'}">${I18N.t('status.' + (u.status || 'active'))}</span></td>
        <td class="rt">${fmtDate(u.created_at)}</td>
        <td class="rt"><div class="row-actions">
          <button class="btn ghost" data-edit="${u.id}">${I18N.t('users.edit')}</button>
          <button class="btn ghost" data-del="${u.id}">${I18N.t('users.delete')}</button>
        </div></td>
      </tr>`).join('');
    document.getElementById('usersTable').innerHTML = `
      <thead><tr><th>${I18N.t('users.name')}</th><th>${I18N.t('users.role')}</th><th>${I18N.t('users.permissions')}</th><th>${I18N.t('users.status')}</th><th class="rt">${I18N.t('users.created')}</th><th class="rt">${I18N.t('users.actions')}</th></tr></thead>
      <tbody>${body || `<tr><td colspan="6" class="muted">${I18N.t('users.none')}</td></tr>`}</tbody>`;

    const table = document.getElementById('usersTable');
    table.querySelectorAll('[data-edit]').forEach((b) => {
      b.addEventListener('click', () => {
        const u = data.rows.find((x) => x.id === b.dataset.edit);
        if (u) showUserForm(u);
      });
    });
    table.querySelectorAll('[data-del]').forEach((b) => {
      b.addEventListener('click', () => deleteUser(b.dataset.del));
    });
  } catch (e) {
    document.getElementById('usersTable').innerHTML = `<tbody><tr><td class="muted">${e.message}</td></tr></tbody>`;
  }
}

async function deleteUser(id) {
  if (!confirm(I18N.t('users.confirmDelete'))) return;
  try {
    await apiSend('DELETE', `/admin/users/${id}`);
    loadUsers();
  } catch (e) {
    alert(e.message);
  }
}

async function saveUser() {
  const msg = document.getElementById('userMsg');
  const fail = (m) => { msg.textContent = m; msg.className = 'ok-msg show err'; };
  const name = document.getElementById('uName').value.trim();
  const email = document.getElementById('uEmail').value.trim();
  const role = document.getElementById('uRole').value;
  const status = document.getElementById('uStatus').value;
  const password = document.getElementById('uPassword').value;
  try {
    if (editingUserId) {
      const body = { name, role, status, ...accessBody(role) };
      if (password) body.password = password;
      await apiSend('PATCH', `/admin/users/${editingUserId}`, body);
    } else {
      await apiSend('POST', '/admin/users', { name, email, password, role, status, ...accessBody(role) });
    }
    hideUserForm();
    loadUsers();
  } catch (e) {
    fail(e.message);
  }
}

document.getElementById('addUser').addEventListener('click', () => showUserForm(null));
document.getElementById('cancelUser').addEventListener('click', hideUserForm);
document.getElementById('saveUser').addEventListener('click', saveUser);
document.getElementById('uRole').addEventListener('change', () => {
  toggleUserAccessBlock();
  updateAccessUI([]);
});
document.getElementById('uAccess').addEventListener('change', () => updateAccessUI([]));
let uSearchTimer;
document.getElementById('uq').addEventListener('input', () => {
  clearTimeout(uSearchTimer);
  uSearchTimer = setTimeout(loadUsers, 250);
});
document.getElementById('uRoleFilter').addEventListener('change', loadUsers);

// ---------- Roles (permission bundles) ----------
let editingRoleKey = null;

async function loadRoles() {
  try {
    const data = await api('/admin/roles');
    rolesCache = data.rows || [];
    const body = data.rows.map((r) => `
      <tr>
        <td>${r.name} ${r.is_system ? `<span class="pill active">${I18N.t('roles.system')}</span>` : ''}</td>
        <td class="muted">${r.key}</td>
        <td>${sectionsSummary(r.permissions || [])}</td>
        <td class="rt tabular">${r.users || 0}</td>
        <td class="rt"><div class="row-actions">
          ${r.is_system ? '' : `<button class="btn ghost" data-redit="${r.key}">${I18N.t('roles.edit')}</button>
          <button class="btn ghost" data-rdel="${r.key}">${I18N.t('roles.delete')}</button>`}
        </div></td>
      </tr>`).join('');
    document.getElementById('rolesTable').innerHTML = `
      <thead><tr><th>${I18N.t('roles.name')}</th><th>${I18N.t('roles.key')}</th><th>${I18N.t('roles.permissions')}</th><th class="rt">${I18N.t('roles.usersCount')}</th><th class="rt">${I18N.t('users.actions')}</th></tr></thead>
      <tbody>${body || `<tr><td colspan="5" class="muted">${I18N.t('roles.none')}</td></tr>`}</tbody>`;

    const t = document.getElementById('rolesTable');
    t.querySelectorAll('[data-redit]').forEach((b) => {
      b.addEventListener('click', () => {
        const r = rolesCache.find((x) => x.key === b.dataset.redit);
        if (r) showRoleForm(r);
      });
    });
    t.querySelectorAll('[data-rdel]').forEach((b) => {
      b.addEventListener('click', () => deleteRole(b.dataset.rdel));
    });
  } catch (e) {
    document.getElementById('rolesTable').innerHTML = `<tbody><tr><td class="muted">${e.message}</td></tr></tbody>`;
  }
}

function showRoleForm(r) {
  editingRoleKey = r ? r.key : null;
  document.getElementById('roleFormTitle').textContent = I18N.t(r ? 'roles.edit' : 'roles.add');
  document.getElementById('rName').value = r ? r.name : '';
  document.getElementById('rKey').value = r ? r.key : '';
  document.getElementById('rKey').disabled = !!r;
  buildPermMatrix('rPerms', r ? r.permissions || [] : []);
  const msg = document.getElementById('roleMsg');
  msg.className = 'ok-msg';
  msg.textContent = '';
  document.getElementById('roleFormCard').style.display = '';
}
function hideRoleForm() {
  document.getElementById('roleFormCard').style.display = 'none';
  editingRoleKey = null;
}

async function saveRole() {
  const msg = document.getElementById('roleMsg');
  const name = document.getElementById('rName').value.trim();
  const key = document.getElementById('rKey').value.trim();
  const permissions = readPermMatrix('rPerms');
  try {
    if (editingRoleKey) {
      await apiSend('PATCH', `/admin/roles/${editingRoleKey}`, { name, permissions });
    } else {
      await apiSend('POST', '/admin/roles', { name, key, permissions });
    }
    hideRoleForm();
    loadRoles();
  } catch (e) {
    msg.textContent = e.message;
    msg.className = 'ok-msg show err';
  }
}

async function deleteRole(key) {
  if (!confirm(I18N.t('roles.confirmDelete'))) return;
  try {
    await apiSend('DELETE', `/admin/roles/${key}`);
    loadRoles();
  } catch (e) {
    alert(e.message);
  }
}

document.getElementById('addRole').addEventListener('click', () => showRoleForm(null));
document.getElementById('cancelRole').addEventListener('click', hideRoleForm);
document.getElementById('saveRole').addEventListener('click', saveRole);

// ---------- Activity / audit log ----------
let auditPage = 1;
function fmtDateTime(s) {
  if (!s) return '—';
  const o = { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' };
  try {
    return new Date(s).toLocaleString(I18N.getLocale(), o);
  } catch (_) {
    return new Date(s).toLocaleString(undefined, o);
  }
}
async function loadAudit() {
  try {
    const data = await api(`/admin/audit?page=${auditPage}`);
    const body = data.rows.map((a) => `
      <tr>
        <td>${a.admin_name ? `${a.admin_name} <span class="muted" style="font-size:11px">${a.admin_email || ''}</span>` : '<span class="muted">—</span>'}</td>
        <td>${tOr('action.' + a.action, a.action)}</td>
        <td>${a.entity ? tOr('entity.' + a.entity, a.entity) : '—'}</td>
        <td class="rt">${fmtDateTime(a.at)}</td>
      </tr>`).join('');
    document.getElementById('auditTable').innerHTML = `
      <thead><tr><th>${I18N.t('audit.who')}</th><th>${I18N.t('audit.action')}</th><th>${I18N.t('audit.entity')}</th><th class="rt">${I18N.t('audit.when')}</th></tr></thead>
      <tbody>${body || `<tr><td colspan="4" class="muted">${I18N.t('audit.none')}</td></tr>`}</tbody>`;
    const pages = Math.max(1, Math.ceil(data.total / data.pageSize));
    document.getElementById('aPageInfo').textContent = I18N.t('pager.info', { page: data.page, pages, total: data.total });
    document.getElementById('aPrev').disabled = auditPage <= 1;
    document.getElementById('aNext').disabled = auditPage >= pages;
  } catch (e) {
    document.getElementById('auditTable').innerHTML = `<tbody><tr><td class="muted">${e.message}</td></tr></tbody>`;
  }
}
document.getElementById('aPrev').addEventListener('click', () => { if (auditPage > 1) { auditPage--; loadAudit(); } });
document.getElementById('aNext').addEventListener('click', () => { auditPage++; loadAudit(); });

// ---------- Boot ----------
async function loadMe() {
  try {
    me = await api('/admin/me');
  } catch (_) {
    me = null; // older server without /me → treat as full access
  }
  applyNavVisibility();
}

async function syncFromServer() {
  try {
    const s = await api('/admin/settings');
    if (s.currency) I18N.setCurrency(s.currency);
    const map = {};
    for (const l of s.locales || []) {
      try {
        const full = await api(`/admin/locales/${l.code}`);
        map[l.code] = { name: full.name, dir: full.dir, strings: full.strings || {} };
      } catch (_) {}
    }
    I18N.setCustomLocales(map);
  } catch (_) {
    // Offline / not reachable — fall back to whatever is cached locally.
  }
}

(async function boot() {
  await loadMe();
  await fetchRoles(); // so the Users table can show role names
  await syncFromServer();
  fillLangSelectors();
  I18N.setLocale(I18N.getLocale()); // apply static translations + dir/lang
  document.getElementById('whoName').textContent = user.name || I18N.t('head.admin');
  document.getElementById('whoAv').textContent = (user.name || 'A').slice(0, 1).toUpperCase();
  loadOverview();
})();
