// ARETE admin dashboard — vanilla JS, talks to /api/admin/*.
const token = localStorage.getItem('arete_token');
if (!token) location.replace('index.html');

const user = JSON.parse(localStorage.getItem('arete_user') || '{}');
document.getElementById('whoName').textContent = user.name || 'Admin';
document.getElementById('whoAv').textContent = (user.name || 'A').slice(0, 1).toUpperCase();

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
function money(n) { return '$' + Number(n || 0).toLocaleString(); }
function fmtDate(s) {
  if (!s) return '—';
  return new Date(s).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

// ---------- Navigation ----------
const titles = { overview: 'Overview', members: 'Members', trainers: 'Trainers', plans: 'Plans' };
document.querySelectorAll('.nav a[data-section]').forEach((a) => {
  a.addEventListener('click', () => {
    const s = a.dataset.section;
    document.querySelectorAll('.nav a[data-section]').forEach((x) => x.classList.remove('active'));
    a.classList.add('active');
    document.querySelectorAll('.section').forEach((x) => x.classList.remove('active'));
    document.getElementById('section-' + s).classList.add('active');
    document.getElementById('pageTitle').textContent = titles[s];
    if (s === 'members') loadMembers();
    if (s === 'trainers') loadTrainers();
    if (s === 'plans') loadPlans();
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
      { l: 'Total members', v: o.totalMembers, d: '', c: '' },
      { l: 'Active', v: o.activeMembers, d: 'with active plan', c: 'up' },
      { l: 'Expiring ≤7d', v: o.expiringSoon, d: 'needs follow-up', c: 'down' },
      { l: 'MRR', v: money(o.mrr), d: `${o.trainers} trainers · ${o.sessionsToday} sessions today`, c: 'up' },
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
    }).join('') || '<span class="muted">No data yet</span>';

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
        <td><span class="pill ${m.status || 'expired'}">${m.status || '—'}</span></td>
        <td class="rt">${fmtDate(m.renews_on)}</td>
      </tr>`).join('');
    document.getElementById('membersTable').innerHTML = `
      <thead><tr><th>Member</th><th>Tier</th><th>Trainer</th><th>Status</th><th class="rt">Renews</th></tr></thead>
      <tbody>${body || '<tr><td colspan="5" class="muted">No members found</td></tr>'}</tbody>`;

    const pages = Math.max(1, Math.ceil(data.total / data.pageSize));
    document.getElementById('pageInfo').textContent = `Page ${data.page} of ${pages} · ${data.total} total`;
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
      <thead><tr><th>Trainer</th><th>Specialty</th><th class="rt">Clients</th><th class="rt">Rating</th><th class="rt">Reply</th></tr></thead>
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
      <thead><tr><th>Plan</th><th>Split</th><th class="rt">Days</th><th>Goal</th><th>Level</th></tr></thead>
      <tbody>${body}</tbody>`;
  } catch (e) {
    document.getElementById('plansTable').innerHTML = `<tbody><tr><td class="muted">${e.message}</td></tr></tbody>`;
  }
}

loadOverview();
