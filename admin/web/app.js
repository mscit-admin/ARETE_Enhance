// ARETE admin dashboard — vanilla JS, talks to /api/admin/*.
const token = localStorage.getItem('arete_token');
if (!token) location.replace('index.html');

const user = JSON.parse(localStorage.getItem('arete_user') || '{}');

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

// ---------- Boot ----------
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
  await syncFromServer();
  fillLangSelectors();
  I18N.setLocale(I18N.getLocale()); // apply static translations + dir/lang
  document.getElementById('whoName').textContent = user.name || I18N.t('head.admin');
  document.getElementById('whoAv').textContent = (user.name || 'A').slice(0, 1).toUpperCase();
  loadOverview();
})();
