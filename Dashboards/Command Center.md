---
tags: [dashboard]
cssclasses:
  - wide-page
sticker: lucide//radar
---

# 🎯 Command Center

> Pipeline health, milestone timelines, and action items — all in one view.
> [[Day View]] · [[Customer Scorecard]] · [[People Directory]]

> [!abstract]- 📡 Local Data · Last synced from MSX / CRM
> Everything on this dashboard is rendered from **local vault files** (Meetings, Customers, Opportunities, Milestones, Projects).
> To refresh or pull latest data, ask **@mcaps-iq** in GitHub Copilot Chat or run the **Sidekick** sync command.

---

```dataviewjs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📊 KPI CARDS — 2×4 grid with inline insights
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const getCust = (v) => {
  if (!v) return null;
  if (Array.isArray(v)) return getCust(v[0]);
  if (typeof v === 'object' && v.path) return v.path.split('/').pop();
  const s = String(v).trim();
  return s && s !== 'null' && s !== 'undefined' ? s : null;
};
const safeDate = (d) => {
  if (!d) return null;
  try { return typeof d === 'string' ? dv.date(d) : d; } catch(e) { return null; }
};
const safeFmt = (d, fmt) => {
  const dt = safeDate(d);
  return dt ? dv.func.dateformat(dt, fmt) : '';
};
const meetings = dv.pages('"Meetings"');
const projects = dv.pages('"Projects"');
const milestones = dv.pages('#milestone');
const opportunities = dv.pages('#opportunity').where(o => o.file.folder.includes('opportunities'));
const today = dv.date('today');
const d7 = today - dv.duration('7 days');
const d14 = today - dv.duration('14 days');
const d30 = today - dv.duration('30 days');

const msOnTrack = milestones.where(m => m.status === 'On Track').length;
const msAtRisk  = milestones.where(m => m.status === 'At Risk').length;
const msBlocked = milestones.where(m => m.status === 'Blocked').length;
const msTotal   = milestones.length;
const msPastDue = milestones.where(m => m.milestonedate && safeDate(m.milestonedate) < today && m.status !== 'Blocked').length;

const isActiveOpp = (o) => o.status === 'Active' || !!o.stage;
const getACR = (o) => Number(o.recurringACR) || Number(o.acr) || 0;
const fmtK = (v) => v >= 1000000 ? `$${(v/1000000).toFixed(1)}M` : v >= 1000 ? `$${(v/1000).toFixed(0)}K` : `$${v}`;
const activeOppsList = opportunities.where(o => isActiveOpp(o));
const activeOpps = activeOppsList.length;
const totalOpps = opportunities.length;
const oppsWithACR = activeOppsList.where(o => getACR(o) > 0).length;
const totalACR = activeOppsList.values.reduce((sum, o) => sum + getACR(o), 0);

const atRiskOppNames = new Set();
for (const ms of milestones) {
  if (ms.status === 'At Risk' || ms.status === 'Blocked') {
    if (ms.opportunity) atRiskOppNames.add(ms.opportunity);
  }
}
const atRiskOpps = activeOppsList.where(o => atRiskOppNames.has(o.file.name));
const dollarAtRisk = atRiskOpps.values.reduce((sum, o) => sum + getACR(o), 0);

const allCustomers = dv.pages('"Customers"').where(c => c.tags && dv.func.contains(c.tags, 'customer'));
const custLastMtg = {};
meetings.forEach(m => {
  const c = getCust(m.customer);
  const d = safeDate(m.date);
  if (c && d && (!custLastMtg[c] || d > custLastMtg[c])) custLastMtg[c] = d;
});
const staleCustomersList = allCustomers.filter(c => { const last = custLastMtg[c.file.name]; return !last || last < d14; });
const staleCust = staleCustomersList.length;

// ─── 2×4 grid ───
const grid = this.container.createEl('div');
grid.style.cssText = 'display:grid;grid-template-columns:repeat(4, 1fr);gap:10px;margin:8px 0 0 0;width:100%;';

// Shared detail area below the grid
const detailArea = this.container.createEl('div');
detailArea.style.cssText = 'margin:0 0 12px 0;display:none;';
let activeCardId = null;
const allCardEls = [];

const makeCard = (color, id) => {
  const el = grid.createEl('div', {
    attr: { style: `padding:12px 14px;border-radius:10px;background:var(--background-secondary);border-left:4px solid ${color};min-width:0;overflow:hidden;cursor:pointer;transition:outline 0.15s,box-shadow 0.15s;`, 'data-card-id': id }
  });
  allCardEls.push({ el, color, id });
  return el;
};
const cardTitle = (parent, label) => {
  parent.createEl('div', { text: label, attr: { style: 'font-size:0.65em;text-transform:uppercase;letter-spacing:0.04em;opacity:0.5;margin-bottom:2px;' } });
};
const cardValue = (parent, value, color) => {
  parent.createEl('div', { text: String(value), attr: { style: `font-size:1.5em;font-weight:700;color:${color};line-height:1.2;margin-bottom:4px;` } });
};
const cardLink = (parent, name, meta) => {
  const row = parent.createEl('div', { attr: { style: 'display:flex;justify-content:space-between;align-items:center;padding:2px 0;font-size:0.72em;' } });
  row.createEl('a', { text: name, attr: { 'data-href': name, href: name, class: 'internal-link', style: 'text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;' } });
  if (meta) row.createEl('span', { text: meta, attr: { style: 'opacity:0.5;flex-shrink:0;margin-left:6px;font-size:0.9em;' } });
};

// ── Row 1 ──

// All card data for drilldown
const cardData = {};

// Card 1: Milestones On Track
const c1 = makeCard('#00c853', 'on-track');
cardData['on-track'] = { label: '✅ Milestones On Track', color: '#00c853', items: milestones.where(m => m.status === 'On Track') };
cardTitle(c1, '✅ Milestones On Track');
cardValue(c1, msOnTrack, '#00c853');
// Show stacked bar of all MS
const msBar = c1.createEl('div', { attr: { style: 'display:flex;border-radius:4px;overflow:hidden;height:8px;margin-bottom:6px;' } });
if (msOnTrack > 0) msBar.createEl('div', { attr: { style: `width:${(msOnTrack/msTotal)*100}%;background:#00c853;` } });
if (msAtRisk > 0) msBar.createEl('div', { attr: { style: `width:${(msAtRisk/msTotal)*100}%;background:#ff9100;` } });
if (msBlocked > 0) msBar.createEl('div', { attr: { style: `width:${(msBlocked/msTotal)*100}%;background:#ff1744;` } });
c1.createEl('div', { text: `${msOnTrack} on track · ${msAtRisk} at risk · ${msBlocked} blocked`, attr: { style: 'font-size:0.65em;opacity:0.45;' } });

// Card 2: At Risk
const c2 = makeCard('#ff9100', 'at-risk');
cardData['at-risk'] = { label: '⚠️ Milestones At Risk', color: '#ff9100', items: milestones.where(m => m.status === 'At Risk') };
cardTitle(c2, '⚠️ Milestones At Risk');
cardValue(c2, msAtRisk, '#ff9100');
const msAtRiskList = milestones.where(m => m.status === 'At Risk');
for (const ms of msAtRiskList.slice(0, 3)) {
  const parts = ms.file.folder.split('/');
  const ci = parts.indexOf('Customers');
  const cust = (ci >= 0 && ci + 1 < parts.length) ? parts[ci + 1] : '';
  cardLink(c2, ms.file.name, cust);
}
if (msAtRiskList.length > 3) c2.createEl('div', { text: `+${msAtRiskList.length - 3} more`, attr: { style: 'font-size:0.65em;opacity:0.4;margin-top:2px;' } });

// Card 3: Blocked
const c3 = makeCard('#ff1744', 'blocked');
cardData['blocked'] = { label: '🔴 Milestones Blocked', color: '#ff1744', items: milestones.where(m => m.status === 'Blocked') };
cardTitle(c3, '🔴 Milestones Blocked');
cardValue(c3, msBlocked, '#ff1744');
const msBlockedList = milestones.where(m => m.status === 'Blocked');
for (const ms of msBlockedList.slice(0, 3)) {
  const parts = ms.file.folder.split('/');
  const ci = parts.indexOf('Customers');
  const cust = (ci >= 0 && ci + 1 < parts.length) ? parts[ci + 1] : '';
  cardLink(c3, ms.file.name, cust);
}
if (msBlockedList.length > 3) c3.createEl('div', { text: `+${msBlockedList.length - 3} more`, attr: { style: 'font-size:0.65em;opacity:0.4;margin-top:2px;' } });

// Card 4: Past Due
const c4 = makeCard('#d50000', 'past-due');
cardData['past-due'] = { label: '⏰ Milestones Past Due', color: '#d50000', items: milestones.where(m => m.milestonedate && safeDate(m.milestonedate) < today && m.status !== 'Blocked') };
cardTitle(c4, '⏰ Milestones Past Due');
cardValue(c4, msPastDue, '#d50000');
const msPastDueList = milestones.where(m => m.milestonedate && safeDate(m.milestonedate) < today && m.status !== 'Blocked').sort(m => m.milestonedate, 'asc');
for (const ms of msPastDueList.slice(0, 3)) {
  const days = Math.round((today - ms.milestonedate) / (1000 * 60 * 60 * 24));
  cardLink(c4, ms.file.name, `${days}d`);
}
if (msPastDueList.length > 3) c4.createEl('div', { text: `+${msPastDueList.length - 3} more`, attr: { style: 'font-size:0.65em;opacity:0.4;margin-top:2px;' } });

// ── Row 2 ──

// Card 5: Total ACR
const c5 = makeCard('#00bcd4', 'acr');
cardData['acr'] = { label: '💰 Pipeline ACR', color: '#00bcd4', items: activeOppsList };
cardTitle(c5, `💰 Pipeline ACR (${oppsWithACR}/${activeOpps} opps)`);
cardValue(c5, totalACR > 0 ? fmtK(totalACR) : '—', '#00bcd4');
// Top 3 opps by ACR
const topByACR = activeOppsList.sort(o => getACR(o), 'desc').slice(0, 3);
for (const o of topByACR) {
  const acr = getACR(o);
  if (acr > 0) cardLink(c5, o.file.name, fmtK(acr));
}

// Card 6: $ At Risk
const c6 = makeCard(dollarAtRisk > 0 ? '#ff1744' : '#888', 'acr-risk');
cardData['acr-risk'] = { label: '🔥 ACR At Risk', color: dollarAtRisk > 0 ? '#ff1744' : '#888', items: atRiskOpps };
cardTitle(c6, `🔥 ACR At Risk (${atRiskOpps.length} opps)`);
cardValue(c6, dollarAtRisk > 0 ? fmtK(dollarAtRisk) : '—', dollarAtRisk > 0 ? '#ff1744' : '#888');
for (const o of atRiskOpps.slice(0, 3)) {
  const acr = getACR(o);
  cardLink(c6, o.file.name, acr > 0 ? fmtK(acr) : '');
}

// Card 7: Active Opportunities
const c7 = makeCard('#448aff', 'opps');
cardData['opps'] = { label: '🎯 Active Opportunities', color: '#448aff', items: activeOppsList };
cardTitle(c7, '🎯 Active Opportunities');
cardValue(c7, `${activeOpps}/${totalOpps}`, '#448aff');
// Stage breakdown inline
const stageCounts = {};
for (const o of activeOppsList) {
  const stage = o.stage || 'Unknown';
  stageCounts[stage] = (stageCounts[stage] || 0) + 1;
}
const stageList = c7.createEl('div', { attr: { style: 'font-size:0.68em;opacity:0.55;line-height:1.5;' } });
for (const [stage, cnt] of Object.entries(stageCounts).sort((a,b) => b[1] - a[1])) {
  stageList.createEl('div', { text: `${stage.split(' & ')[0]}: ${cnt}` });
}

// Card 8: Stale Accounts
const c8 = makeCard('#ff6d00', 'stale');
cardData['stale'] = { label: '👻 Stale Accounts', color: '#ff6d00', items: staleCustomersList };
cardTitle(c8, '👻 Stale Accounts');
cardValue(c8, staleCust, '#ff6d00');
for (const c of staleCustomersList.slice(0, 3)) {
  const last = custLastMtg[c.file.name];
  const days = last ? Math.round((today - last) / (1000 * 60 * 60 * 24)) : null;
  cardLink(c8, c.file.name, days ? `${days}d ago` : 'never');
}
if (staleCust > 3) c8.createEl('div', { text: `+${staleCust - 3} more`, attr: { style: 'font-size:0.65em;opacity:0.4;margin-top:2px;' } });

// ── Click handler: expand detail below grid ──
for (const { el, color, id } of allCardEls) {
  el.addEventListener('click', (e) => {
    // Don't intercept link clicks
    if (e.target.closest('a')) return;

    // Toggle off if same card
    if (activeCardId === id) {
      detailArea.style.display = 'none';
      detailArea.empty();
      activeCardId = null;
      allCardEls.forEach(c => { c.el.style.outline = 'none'; c.el.style.boxShadow = 'none'; });
      return;
    }
    activeCardId = id;

    // Highlight
    allCardEls.forEach(c => { c.el.style.outline = 'none'; c.el.style.boxShadow = 'none'; });
    el.style.outline = `2px solid ${color}`;
    el.style.boxShadow = `0 0 0 1px ${color}44`;

    // Render
    detailArea.empty();
    detailArea.style.display = 'block';
    const cd = cardData[id];
    if (!cd || !cd.items || cd.items.length === 0) {
      detailArea.createEl('div', { text: 'No items.', attr: { style: 'padding:10px;font-size:0.82em;opacity:0.4;' } });
      return;
    }

    const panel = detailArea.createEl('div', {
      attr: { style: `padding:12px 16px;border-radius:10px;background:var(--background-secondary);border-left:4px solid ${cd.color};margin-top:10px;` }
    });
    panel.createEl('div', { text: `${cd.label} — ${cd.items.length} items`, attr: { style: `font-size:0.78em;font-weight:700;color:${cd.color};margin-bottom:8px;text-transform:uppercase;letter-spacing:0.03em;` } });

    const listWrap = panel.createEl('div', {
      attr: { style: 'display:grid;grid-template-columns:1fr 1fr;gap:4px 16px;' }
    });
    for (const item of cd.items) {
      const row = listWrap.createEl('div', { attr: { style: 'display:flex;justify-content:space-between;align-items:center;padding:4px 8px;border-radius:4px;background:var(--background-primary);min-width:0;' } });
      row.createEl('a', {
        text: item.file.name,
        attr: { 'data-href': item.file.name, href: item.file.name, class: 'internal-link', style: 'text-decoration:none;font-size:0.8em;font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;min-width:0;' }
      });
      // Context-aware meta
      const parts = item.file.folder.split('/');
      const ci = parts.indexOf('Customers');
      const cust = (ci >= 0 && ci + 1 < parts.length) ? parts[ci + 1] : '';
      const stage = item.stage || item.status || '';
      const acr = getACR(item);
      const metaParts = [];
      if (cust) metaParts.push(cust);
      if (stage) metaParts.push(stage);
      if (acr > 0) metaParts.push(fmtK(acr));
      if (item.milestonedate) {
        const days = Math.round((today - item.milestonedate) / (1000 * 60 * 60 * 24));
        if (days > 0) metaParts.push(`${days}d overdue`);
        else if (days < 0) metaParts.push(safeFmt(item.milestonedate, 'MMM d'));
      }
      const metaText = metaParts.join(' · ');
      if (metaText) row.createEl('span', { text: metaText, attr: { style: 'font-size:0.72em;opacity:0.5;flex-shrink:0;margin-left:8px;white-space:nowrap;' } });
    }
  });
}
```

---

```dataviewjs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🏥 CUSTOMER HEALTH + 🚨 ACTION STREAM (shared queries)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const getCust = (v) => {
  if (!v) return null;
  if (Array.isArray(v)) return getCust(v[0]);
  if (typeof v === 'object' && v.path) return v.path.split('/').pop();
  const s = String(v).trim();
  return s && s !== 'null' && s !== 'undefined' ? s : null;
};
const safeDate = (d) => {
  if (!d) return null;
  try { return typeof d === 'string' ? dv.date(d) : d; } catch(e) { return null; }
};
const safeFmt = (d, fmt) => {
  const dt = safeDate(d);
  return dt ? dv.func.dateformat(dt, fmt) : '';
};
const meetings = dv.pages('"Meetings"');
const milestones = dv.pages('#milestone');
const opps = dv.pages('#opportunity').where(o => o.file.folder.includes('opportunities'));
const projects = dv.pages('"Projects"').where(p => p.status === 'active');
const today = dv.date('today');
const d7 = today - dv.duration('7 days');
const d14 = today - dv.duration('14 days');
const d30 = today - dv.duration('30 days');
const d60 = today - dv.duration('60 days');
const getACR = (o) => Number(o.recurringACR) || Number(o.acr) || 0;
const fmtK = (v) => v >= 1000000 ? `$${(v/1000000).toFixed(1)}M` : v >= 1000 ? `$${(v/1000).toFixed(0)}K` : `$${v}`;

const allCustomers = dv.pages('"Customers"')
  .where(c => c.tags && dv.func.contains(c.tags, 'customer'));
const custNames = allCustomers.map(c => c.file.name);

const data = {};
for (const c of custNames) data[c] = { last: null, mtgs30: 0, ms: { ot: 0, ar: 0, bl: 0, total: 0 }, opps: 0, acr: 0, projects: 0 };

for (const m of meetings) {
  const c = getCust(m.customer);
  const d = safeDate(m.date);
  if (!c || !d || !data[c]) continue;
  if (!data[c].last || d > data[c].last) data[c].last = d;
  if (d >= d30) data[c].mtgs30++;
}
for (const ms of milestones) {
  const parts = ms.file.folder.split('/');
  const ci = parts.indexOf('Customers');
  if (ci < 0 || ci + 1 >= parts.length) continue;
  const cn = parts[ci + 1];
  if (!data[cn]) continue;
  data[cn].ms.total++;
  if (ms.status === 'On Track') data[cn].ms.ot++;
  else if (ms.status === 'At Risk') data[cn].ms.ar++;
  else if (ms.status === 'Blocked') data[cn].ms.bl++;
}
for (const o of opps) {
  const parts = o.file.folder.split('/');
  const ci = parts.indexOf('Customers');
  if (ci < 0 || ci + 1 >= parts.length) continue;
  const cn = parts[ci + 1];
  if (data[cn] && (o.status === 'Active' || !!o.stage)) {
    data[cn].opps++;
    data[cn].acr += getACR(o);
  }
}
for (const p of projects) {
  const c = getCust(p.customer);
  if (c && data[c]) data[c].projects++;
}

// RAG: Red = blocked MS OR no meetings in 60d; Yellow = at-risk MS OR stale 30d; Green = rest
const getRag = (s) => {
  if (s.ms.bl > 0) return 'red';
  if (!s.last || s.last < d60) return 'red';
  if (s.ms.ar > 0) return 'yellow';
  if (s.last < d30) return 'yellow';
  return 'green';
};
const ragColors = { red: '#ff1744', yellow: '#ff9100', green: '#00c853' };

const sorted = Object.entries(data).sort((a, b) => {
  const ragOrd = s => getRag(s) === 'red' ? 0 : getRag(s) === 'yellow' ? 1 : 2;
  return ragOrd(a[1]) - ragOrd(b[1]) || ((b[1].last || 0) - (a[1].last || 0));
});

const redCount = sorted.filter(([,s]) => getRag(s) === 'red').length;
const yellowCount = sorted.filter(([,s]) => getRag(s) === 'yellow').length;
const greenCount = sorted.filter(([,s]) => getRag(s) === 'green').length;
const staleList = allCustomers.filter(c => { const s = data[c.file.name]; return !s || !s.last || s.last < d14; });

dv.header(2, '🏥 Customer Health');
const summary = dv.el('div', '', { attr: { style: 'display:flex;gap:16px;margin-bottom:12px;' } });
for (const [label, cnt, color] of [['🔴 Needs Attention', redCount, '#ff1744'], ['🟡 Monitor', yellowCount, '#ff9100'], ['🟢 Healthy', greenCount, '#00c853']]) {
  const pill = summary.createEl('div', { attr: { style: `display:flex;align-items:center;gap:4px;padding:4px 12px;border-radius:12px;background:${color}18;` } });
  pill.createEl('span', { text: label, attr: { style: `font-size:0.75em;font-weight:600;color:${color};` } });
  pill.createEl('span', { text: String(cnt), attr: { style: `font-size:0.85em;font-weight:700;color:${color};` } });
}

const tableWrap = dv.el('div', '', { attr: { style: 'margin:0;border:1px solid var(--background-modifier-border);border-radius:8px;overflow:hidden;' } });

const hdr = tableWrap.createEl('div', { attr: { style: 'display:flex;align-items:center;padding:6px 10px;background:var(--background-secondary);border-bottom:1px solid var(--background-modifier-border);font-size:0.68em;font-weight:600;text-transform:uppercase;letter-spacing:0.04em;opacity:0.5;' } });
hdr.createEl('div', { text: 'Customer', attr: { style: 'flex:1;min-width:0;' } });
hdr.createEl('div', { text: 'Last Mtg', attr: { style: 'width:80px;text-align:center;' } });
hdr.createEl('div', { text: 'Milestones', attr: { style: 'width:110px;text-align:center;' } });
hdr.createEl('div', { text: 'Opps', attr: { style: 'width:50px;text-align:center;' } });
hdr.createEl('div', { text: 'ACR', attr: { style: 'width:70px;text-align:right;' } });
hdr.createEl('div', { text: '30d', attr: { style: 'width:40px;text-align:center;' } });

for (const [name, s] of sorted) {
  const rag = getRag(s);
  const color = ragColors[rag];
  const lastStr = s.last ? safeFmt(s.last, "MMM d") : '—';
  const isStale = !s.last || s.last < d30;
  const rowBg = rag === 'red' ? 'rgba(255,23,68,0.04)' : rag === 'yellow' ? 'rgba(255,145,0,0.03)' : '';

  const row = tableWrap.createEl('div', {
    attr: { style: `display:flex;align-items:center;padding:5px 10px;border-bottom:1px solid var(--background-modifier-border);font-size:0.8em;background:${rowBg};border-left:3px solid ${color};` }
  });

  const nameCell = row.createEl('div', { attr: { style: 'flex:1;min-width:0;' } });
  nameCell.createEl('a', { text: name, attr: { 'data-href': name, href: name, class: 'internal-link', style: 'font-weight:600;text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;' } });

  const lastColor = !s.last || s.last < d60 ? '#d50000' : s.last < d30 ? '#ff9100' : 'var(--text-muted)';
  row.createEl('div', { text: lastStr, attr: { style: `width:80px;text-align:center;color:${lastColor};font-weight:${isStale ? '600' : '400'};font-size:0.9em;flex-shrink:0;` } });

  const msCell = row.createEl('div', { attr: { style: 'width:110px;text-align:center;flex-shrink:0;' } });
  if (s.ms.total === 0) {
    msCell.createEl('span', { text: '—', attr: { style: 'opacity:0.25;' } });
  } else {
    const pw = msCell.createEl('span', { attr: { style: 'display:inline-flex;gap:2px;font-size:0.88em;' } });
    if (s.ms.ot > 0) pw.createEl('span', { text: `${s.ms.ot}✅` });
    if (s.ms.ar > 0) pw.createEl('span', { text: `${s.ms.ar}⚠️` });
    if (s.ms.bl > 0) pw.createEl('span', { text: `${s.ms.bl}🔴` });
  }

  row.createEl('div', { text: s.opps > 0 ? String(s.opps) : '—', attr: { style: `width:50px;text-align:center;flex-shrink:0;${s.opps === 0 ? 'opacity:0.25;' : ''}` } });
  row.createEl('div', { text: s.acr > 0 ? fmtK(s.acr) : '—', attr: { style: `width:70px;text-align:right;flex-shrink:0;font-weight:${s.acr > 0 ? '600' : '400'};color:${s.acr > 0 ? '#00bcd4' : 'var(--text-muted)'};${s.acr === 0 ? 'opacity:0.25;' : ''}` } });
  row.createEl('div', { text: String(s.mtgs30), attr: { style: `width:40px;text-align:center;flex-shrink:0;${s.mtgs30 === 0 ? 'color:#d50000;font-weight:600;' : ''}` } });
}

// ── ACTION STREAM (reuses queries from above) ──
dv.header(2, '🚨 Action Stream');
const actionItems = [];

// reuse milestones already queried
for (const ms of milestones.where(m => m.status === 'Blocked')) {
  const parts = ms.file.folder.split('/');
  const ci = parts.indexOf('Customers');
  const cust = (ci >= 0 && ci + 1 < parts.length) ? parts[ci + 1] : '';
  actionItems.push({ pri: 1, icon: '🔴', text: `Blocked: ${ms.file.name}`, detail: cust, link: ms.file.name, sort: 0 });
}
for (const ms of milestones.where(m => m.milestonedate && m.milestonedate < today && m.status !== 'Blocked')) {
  const parts = ms.file.folder.split('/');
  const ci = parts.indexOf('Customers');
  const cust = (ci >= 0 && ci + 1 < parts.length) ? parts[ci + 1] : '';
  const days = Math.round((today - ms.milestonedate) / (1000 * 60 * 60 * 24));
  actionItems.push({ pri: 2, icon: '⏰', text: `Overdue ${days}d: ${ms.file.name}`, detail: cust, link: ms.file.name, sort: -days });
}
for (const ms of milestones.where(m => m.status === 'At Risk')) {
  const parts = ms.file.folder.split('/');
  const ci = parts.indexOf('Customers');
  const cust = (ci >= 0 && ci + 1 < parts.length) ? parts[ci + 1] : '';
  actionItems.push({ pri: 3, icon: '⚠️', text: `At Risk: ${ms.file.name}`, detail: cust, link: ms.file.name, sort: 0 });
}
for (const c of staleList) {
  const lastM = data[c.file.name] ? data[c.file.name].last : null;
  const days = lastM ? Math.round((today - lastM) / (1000 * 60 * 60 * 24)) : 999;
  actionItems.push({ pri: 4, icon: '👻', text: `Stale: ${c.file.name}`, detail: lastM ? `Last meeting ${days}d ago` : 'No meetings', link: c.file.name, sort: -days });
}
const todayTasks = dv.pages('"Meetings" OR "Projects" OR "Daily"').file.tasks
  .where(t => !t.completed && t.due && safeFmt(t.due, 'yyyy-MM-dd') === safeFmt(today, 'yyyy-MM-dd'));
for (const t of todayTasks) {
  actionItems.push({ pri: 5, icon: '✅', text: t.text, detail: '', link: '', sort: 0 });
}
const todayMtgs = meetings.where(m => m.date && safeFmt(m.date, 'yyyy-MM-dd') === safeFmt(today, 'yyyy-MM-dd'));
for (const m of todayMtgs) {
  const cust = getCust(m.customer);
  actionItems.push({ pri: 6, icon: '📅', text: m.file.name, detail: cust || '', link: m.file.name, sort: 0 });
}

actionItems.sort((a, b) => a.pri - b.pri || a.sort - b.sort);
const actionContainer = dv.el('div', '', { attr: { style: 'max-height:400px;overflow-y:auto;scrollbar-width:thin;' } });
if (actionItems.length === 0) {
  actionContainer.createEl('p', { text: 'All clear! No action items. 🎉', attr: { style: 'opacity:0.5;' } });
} else {
  for (const item of actionItems.slice(0, 30)) {
    const aRow = actionContainer.createEl('div', {
      attr: { style: `display:flex;align-items:flex-start;gap:10px;padding:7px 12px;margin:3px 0;border-radius:6px;background:var(--background-secondary);border-left:3px solid ${item.pri === 1 ? '#ff1744' : item.pri === 2 ? '#d50000' : item.pri === 3 ? '#ff9100' : item.pri === 4 ? '#ff6d00' : item.pri === 5 ? '#7c4dff' : '#448aff'};` }
    });
    aRow.createEl('span', { text: item.icon, attr: { style: 'font-size:1em;flex-shrink:0;' } });
    const body = aRow.createEl('div', { attr: { style: 'flex:1;min-width:0;' } });
    if (item.link) {
      body.createEl('a', { text: item.text, attr: { 'data-href': item.link, href: item.link, class: 'internal-link', style: 'font-size:0.85em;font-weight:500;text-decoration:none;' } });
    } else {
      body.createEl('span', { text: item.text, attr: { style: 'font-size:0.85em;' } });
    }
    if (item.detail) body.createEl('div', { text: item.detail, attr: { style: 'font-size:0.75em;opacity:0.5;margin-top:1px;' } });
  }
}
```

---

## 📅 Date Range

```dataviewjs
// ━━ CALENDAR RANGE PICKER ━━
const MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
const DOW = ['Mo','Tu','We','Th','Fr','Sa','Su'];
const qColors = { 1: '#42a5f5', 2: '#ab47bc', 3: '#66bb6a', 4: '#ff9800' };
const getFQ = (m, y) => { const fy = m >= 6 ? y + 1 : y; const q = m >= 6 ? Math.floor((m - 6) / 3) + 1 : Math.floor((m + 6) / 3) + 1; return { fy, q }; };
const getQRange = (fy, q) => { const qS = { 1:[6,1],2:[9,1],3:[0,1],4:[3,1] }, qE = { 1:[8,30],2:[11,31],3:[2,31],4:[5,30] }; const sy = q <= 2 ? fy-1 : fy; return { start: new Date(sy,qS[q][0],qS[q][1]), end: new Date(sy,qE[q][0],qE[q][1],23,59,59) }; };
const now = new Date();
const todayStr = `${now.getFullYear()}-${now.getMonth()}-${now.getDate()}`;
let viewStartMonth = now.getMonth(), viewStartYear = now.getFullYear();
let rangeStart = null, rangeEnd = null, clicking = false;
window._pipelineDateRange = null;
const dispatchRange = () => {
  if (rangeStart && rangeEnd) { const s = rangeStart < rangeEnd ? rangeStart : rangeEnd; const e = rangeStart < rangeEnd ? rangeEnd : rangeStart; window._pipelineDateRange = { start: s, end: new Date(e.getFullYear(), e.getMonth(), e.getDate(), 23, 59, 59) }; }
  else { window._pipelineDateRange = null; }
  window.dispatchEvent(new CustomEvent('pipeline-date-range'));
};
const isInRange = (date) => { if (!rangeStart || !rangeEnd) return false; const s = rangeStart < rangeEnd ? rangeStart : rangeEnd; const e = rangeStart < rangeEnd ? rangeEnd : rangeStart; return date >= s && date <= e; };
const isRangeEndpoint = (date) => { if (!rangeStart && !rangeEnd) return false; const ds = date.getTime(); return (rangeStart && ds === rangeStart.getTime()) || (rangeEnd && ds === rangeEnd.getTime()); };

const toggleBtn = this.container.createEl('div', { attr: { style: 'display:inline-flex;align-items:center;gap:6px;cursor:pointer;padding:6px 14px;border-radius:8px;background:var(--background-secondary);border:1px solid var(--background-modifier-border);margin-bottom:8px;user-select:none;' } });
toggleBtn.createEl('span', { text: '📅', attr: { style: 'font-size:1em;' } });
toggleBtn.createEl('span', { text: 'Calendar Range', attr: { style: 'font-size:0.82em;font-weight:600;' } });
const rangeLabel = toggleBtn.createEl('span', { attr: { style: 'font-size:0.75em;opacity:0.6;margin-left:6px;' } });
const chevron = toggleBtn.createEl('span', { text: '▸', attr: { style: 'font-size:0.8em;opacity:0.4;margin-left:auto;transition:transform 0.2s;' } });
const calContainer = this.container.createEl('div', { attr: { style: 'display:none;' } });
let calOpen = false;
toggleBtn.addEventListener('click', () => { calOpen = !calOpen; calContainer.style.display = calOpen ? 'block' : 'none'; chevron.style.transform = calOpen ? 'rotate(90deg)' : 'rotate(0deg)'; });

const renderCal = () => {
  calContainer.empty();
  if (rangeStart && rangeEnd) { const s = rangeStart < rangeEnd ? rangeStart : rangeEnd; const e = rangeStart < rangeEnd ? rangeEnd : rangeStart; rangeLabel.textContent = `${MONTHS[s.getMonth()]} ${s.getDate()} – ${MONTHS[e.getMonth()]} ${e.getDate()}, ${e.getFullYear()}`; rangeLabel.style.color = 'var(--text-accent)'; }
  else if (rangeStart && clicking) { rangeLabel.textContent = `${MONTHS[rangeStart.getMonth()]} ${rangeStart.getDate()} → pick end…`; rangeLabel.style.color = 'var(--text-accent)'; }
  else { rangeLabel.textContent = 'click to pick dates'; rangeLabel.style.color = ''; }

  const nav = calContainer.createEl('div', { attr: { style: 'display:flex;align-items:center;justify-content:space-between;padding:6px 0 4px 0;' } });
  const prevBtn = nav.createEl('span', { text: '◀', attr: { style: 'cursor:pointer;padding:4px 12px;font-size:0.85em;border-radius:6px;background:var(--background-secondary);border:1px solid var(--background-modifier-border);user-select:none;' } });
  const navLabel = nav.createEl('span', { attr: { style: 'font-weight:600;font-size:0.85em;' } });
  const nextBtn = nav.createEl('span', { text: '▶', attr: { style: 'cursor:pointer;padding:4px 12px;font-size:0.85em;border-radius:6px;background:var(--background-secondary);border:1px solid var(--background-modifier-border);user-select:none;' } });
  const monthList = [];
  for (let i = 0; i < 4; i++) { let m = viewStartMonth + i, y = viewStartYear; while (m > 11) { m -= 12; y++; } while (m < 0) { m += 12; y--; } monthList.push({ month: m, year: y }); }
  navLabel.textContent = `${MONTHS[monthList[0].month]} ${monthList[0].year} — ${MONTHS[monthList[3].month]} ${monthList[3].year}`;
  prevBtn.addEventListener('click', (e) => { e.stopPropagation(); viewStartMonth -= 2; if (viewStartMonth < 0) { viewStartMonth += 12; viewStartYear--; } renderCal(); });
  nextBtn.addEventListener('click', (e) => { e.stopPropagation(); viewStartMonth += 2; if (viewStartMonth > 11) { viewStartMonth -= 12; viewStartYear++; } renderCal(); });

  const gridWrap = calContainer.createEl('div', { attr: { style: 'display:flex;gap:14px;overflow-x:auto;padding:4px 0 10px 0;' } });
  for (const { month, year } of monthList) {
    const { fy, q } = getFQ(month, year); const qc = qColors[q];
    const mEl = gridWrap.createEl('div', { attr: { style: 'min-width:195px;flex:1;' } });
    const mHdr = mEl.createEl('div', { attr: { style: `display:flex;justify-content:space-between;align-items:center;padding:5px 8px;border-radius:6px 6px 0 0;background:${qc}15;border-bottom:2px solid ${qc};` } });
    mHdr.createEl('span', { text: `${MONTHS[month]} ${year}`, attr: { style: 'font-weight:700;font-size:0.78em;' } });
    mHdr.createEl('span', { text: `FY${fy} Q${q}`, attr: { style: `font-size:0.65em;font-weight:600;color:${qc};opacity:0.8;` } });
    const dowRow = mEl.createEl('div', { attr: { style: 'display:grid;grid-template-columns:repeat(7,1fr);gap:1px;padding:4px 2px 2px 2px;' } });
    for (const d of DOW) dowRow.createEl('div', { text: d, attr: { style: 'font-size:0.6em;text-align:center;opacity:0.35;font-weight:700;' } });
    const daysGrid = mEl.createEl('div', { attr: { style: 'display:grid;grid-template-columns:repeat(7,1fr);gap:1px;padding:0 2px 4px 2px;' } });
    const firstDay = new Date(year, month, 1); let startDow = firstDay.getDay(); startDow = startDow === 0 ? 6 : startDow - 1;
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    for (let i = 0; i < startDow; i++) daysGrid.createEl('div');
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(year, month, day); const dateStr = `${year}-${month}-${day}`;
      const isToday = dateStr === todayStr; const inRange = isInRange(date); const isEnd = isRangeEndpoint(date);
      let bg = 'transparent', color = 'var(--text-normal)', fw = '400', border = 'none';
      if (isEnd) { bg = qc; color = '#fff'; fw = '700'; } else if (inRange) { bg = `${qc}30`; fw = '500'; }
      if (isToday) { border = '2px solid var(--text-accent)'; fw = '700'; }
      const cell = daysGrid.createEl('div', { text: String(day), attr: { style: `font-size:0.68em;text-align:center;padding:3px 1px;border-radius:4px;cursor:pointer;background:${bg};color:${color};font-weight:${fw};border:${border};opacity:0.85;transition:background 0.1s;line-height:1.4;` } });
      cell.addEventListener('mouseenter', () => { if (!isEnd && !inRange) cell.style.background = `${qc}20`; });
      cell.addEventListener('mouseleave', () => { if (!isEnd && !inRange) cell.style.background = bg === 'transparent' ? 'transparent' : bg; });
      cell.addEventListener('click', (e) => { e.stopPropagation(); if (!clicking) { rangeStart = date; rangeEnd = null; clicking = true; renderCal(); } else { rangeEnd = date; clicking = false; dispatchRange(); renderCal(); } });
    }
  }
  const btnBar = calContainer.createEl('div', { attr: { style: 'display:flex;gap:6px;flex-wrap:wrap;padding:4px 0 2px 0;align-items:center;' } });
  btnBar.createEl('span', { text: 'Quick:', attr: { style: 'font-size:0.7em;opacity:0.4;font-weight:600;' } });
  const { fy: curFY, q: curQ } = getFQ(now.getMonth(), now.getFullYear());
  for (let i = -1; i < 5; i++) {
    let qq = curQ + i, fy = curFY; while (qq > 4) { qq -= 4; fy++; } while (qq < 1) { qq += 4; fy--; }
    const hint = i === -1 ? ' (Prev)' : i === 0 ? ' (Now)' : i === 1 ? ' (Next)' : '';
    const label = `FY${fy} Q${qq}${hint}`; const range = getQRange(fy, qq); const qc = qColors[qq];
    const isActive = rangeStart && rangeEnd && Math.abs((rangeStart < rangeEnd ? rangeStart : rangeEnd).getTime() - range.start.getTime()) < 86400000 && Math.abs((rangeStart < rangeEnd ? rangeEnd : rangeStart).getTime() - range.end.getTime()) < 86400000;
    const btn = btnBar.createEl('span', { text: label, attr: { style: `font-size:0.72em;font-weight:600;padding:3px 10px;border-radius:12px;cursor:pointer;background:${isActive ? qc : qc + '22'};color:${isActive ? '#fff' : qc};border:1px solid ${qc}44;transition:all 0.15s;user-select:none;` } });
    btn.addEventListener('click', (e) => { e.stopPropagation(); rangeStart = range.start; rangeEnd = range.end; clicking = false; viewStartMonth = range.start.getMonth(); viewStartYear = range.start.getFullYear(); dispatchRange(); renderCal(); });
  }
  const clearBtn = btnBar.createEl('span', { text: '✕ Clear', attr: { style: 'font-size:0.72em;padding:3px 10px;border-radius:12px;cursor:pointer;background:var(--background-secondary);color:var(--text-muted);border:1px solid var(--background-modifier-border);margin-left:4px;user-select:none;' } });
  clearBtn.addEventListener('click', (e) => { e.stopPropagation(); rangeStart = null; rangeEnd = null; clicking = false; dispatchRange(); renderCal(); });
};
renderCal();
```


```dataviewjs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🎯📅 TIMELINES — Filterable Opportunity + Milestone
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const today = dv.date('today');
const safeDate = (d) => { if (!d) return null; try { return typeof d === 'string' ? dv.date(d) : d; } catch(e) { return null; } };
const safeFmt = (d, fmt) => { if (!d) return ''; try { const dt = typeof d === 'string' ? dv.date(d) : d; return dt ? dv.func.dateformat(dt, fmt) : ''; } catch(e) { return ''; } };
const fmtK = (v) => v >= 1000000 ? `$${(v/1000000).toFixed(1)}M` : v >= 1000 ? `$${(v/1000).toFixed(0)}K` : `$${v}`;
const getACR = (o) => Number(o.recurringACR) || Number(o.acr) || 0;

const allMilestones = dv.pages('#milestone').where(m => m.status !== 'Completed' && m.status !== 'Cancelled' && m.status !== 'Closed as Incomplete');
const allOpps = dv.pages('#opportunity').where(o => o.file.folder.includes('opportunities') && o.status !== 'Completed' && o.status !== 'Cancelled' && o.status !== 'Won' && o.status !== 'Lost');

// Collect customer names
const custSet = new Set();
for (const ms of allMilestones) { const p = ms.file.folder.split('/'); const ci = p.indexOf('Customers'); if (ci >= 0 && ci + 1 < p.length) custSet.add(p[ci + 1]); }
for (const o of allOpps) { const p = o.file.folder.split('/'); const ci = p.indexOf('Customers'); if (ci >= 0 && ci + 1 < p.length) custSet.add(p[ci + 1]); }

// ─── Filter Bar ───
const selStyle = 'font-size:0.8em;padding:4px 8px;border-radius:6px;border:1px solid var(--background-modifier-border);background:var(--background-secondary);color:var(--text-normal);';
const filterWrap = this.container.createEl('div');
filterWrap.style.cssText = 'display:flex;gap:12px;align-items:center;flex-wrap:wrap;padding:8px 0 12px 0;border-bottom:1px solid var(--background-modifier-border);margin-bottom:12px;';

filterWrap.createEl('span', { text: 'Customer:', attr: { style: 'font-size:0.75em;font-weight:600;opacity:0.5;' } });
const custSelect = filterWrap.createEl('select', { attr: { style: selStyle } });
custSelect.createEl('option', { text: 'All Customers', attr: { value: '' } });
for (const c of [...custSet].sort()) custSelect.createEl('option', { text: c, attr: { value: c } });

filterWrap.createEl('span', { text: 'Opp Stage:', attr: { style: 'font-size:0.75em;font-weight:600;opacity:0.5;margin-left:8px;' } });
const oppStageSelect = filterWrap.createEl('select', { attr: { style: selStyle } });
for (const [t, v] of [['All Stages',''],['Listen & Consult','Listen & Consult'],['Inspire & Design','Inspire & Design'],['Empower & Achieve','Empower & Achieve'],['Manage & Optimize','Manage & Optimize'],['Realize Value','Realize Value'],['Past Est Close','past-close']]) oppStageSelect.createEl('option', { text: t, attr: { value: v } });

filterWrap.createEl('span', { text: 'MS Status:', attr: { style: 'font-size:0.75em;font-weight:600;opacity:0.5;margin-left:8px;' } });
const statusSelect = filterWrap.createEl('select', { attr: { style: selStyle } });
for (const [t, v] of [['All Statuses',''],['On Track','On Track'],['At Risk','At Risk'],['Blocked','Blocked'],['Overdue Only','overdue']]) statusSelect.createEl('option', { text: t, attr: { value: v } });

filterWrap.createEl('span', { text: 'Quarter:', attr: { style: 'font-size:0.75em;font-weight:600;opacity:0.5;margin-left:8px;' } });
const fqSelect = filterWrap.createEl('select', { attr: { style: selStyle } });
fqSelect.createEl('option', { text: 'All Quarters', attr: { value: '' } });
const getFQ = (date) => { const m = date.getMonth(); const y = date.getFullYear(); const fy = m >= 6 ? y + 1 : y; const q = m >= 6 ? Math.floor((m - 6) / 3) + 1 : Math.floor((m + 6) / 3) + 1; return { fy, q }; };
const quarters = [];
const { fy: curFY, q: curQ } = getFQ(new Date());
for (let i = -1; i < 5; i++) {
  let q = curQ + i, fy = curFY;
  while (q > 4) { q -= 4; fy++; }
  while (q < 1) { q += 4; fy--; }
  const qStarts = { 1: [6, 1], 2: [9, 1], 3: [0, 1], 4: [3, 1] };
  const qEnds = { 1: [8, 30], 2: [11, 31], 3: [2, 31], 4: [5, 30] };
  const sy = q <= 2 ? fy - 1 : fy;
  quarters.push({ label: `FY${fy} Q${q}`, start: new Date(sy, qStarts[q][0], qStarts[q][1]), end: new Date(sy, qEnds[q][0], qEnds[q][1]) });
  const hint = i === -1 ? ' (Previous)' : i === 0 ? ' (Current)' : i === 1 ? ' (Next)' : '';
  fqSelect.createEl('option', { text: `FY${fy} Q${q}${hint}`, attr: { value: `${fy}-${q}` } });
}

const countDisplay = filterWrap.createEl('span', { attr: { style: 'font-size:0.75em;opacity:0.45;margin-left:auto;' } });

// Render containers
const timelineWrap = this.container.createEl('div');

const renderMonthHeaders = (parent, rangeStart, rangeEnd, rangeDays, leftMargin) => {
  const hb = parent.createEl('div', { attr: { style: `display:flex;margin-left:${leftMargin};height:24px;border-bottom:1px solid var(--background-modifier-border);margin-bottom:8px;position:relative;` } });
  const startD = new Date(rangeStart.ts || rangeStart);
  const endD = new Date(rangeEnd.ts || rangeEnd);
  const step = rangeDays > 730 ? 6 : rangeDays > 365 ? 3 : rangeDays > 180 ? 2 : 1;
  let d = new Date(startD);
  let monthIdx = 0;
  const months = new Set();
  while (d <= endD) {
    const key = `${d.getFullYear()}-${d.getMonth()}`;
    if (!months.has(key)) {
      months.add(key);
      if (monthIdx % step === 0) {
        const off = Math.round((d - startD) / 86400000);
        hb.createEl('span', { text: d.toLocaleDateString('en-US', { month: 'short', year: 'numeric' }), attr: { style: `position:absolute;left:${(off/rangeDays)*100}%;font-size:0.7em;opacity:0.5;top:4px;white-space:nowrap;` } });
      }
      monthIdx++;
    }
    d.setDate(d.getDate() + 7);
  }
};

const getCustFromFolder = (folder) => { const p = folder.split('/'); const ci = p.indexOf('Customers'); return (ci >= 0 && ci + 1 < p.length) ? p[ci + 1] : 'Unknown'; };

const matchesQuarter = (dateVal, fqVal) => {
  if (!fqVal || !dateVal) return true;
  const [fy, q] = fqVal.split('-').map(Number);
  const fq = quarters.find(f => f.label === `FY${fy} Q${q}`);
  if (!fq) return true;
  const ts = dateVal.ts || new Date(dateVal).getTime();
  return ts >= fq.start.getTime() && ts <= fq.end.getTime();
};

const custColors = {
  'Stryker':'#00c853','BD':'#448aff','Cencora':'#7c4dff','R1':'#ff9100','Omnicell':'#00bcd4','Cigna':'#e040fb',
  'Rogers':'#ff5252','Fiserv':'#ffab40','EPIC':'#69f0ae','BlueKC':'#448aff','WPS':'#7c4dff','Asurion':'#ff6d00',
  'Eli Lilly':'#e91e63','Illumina':'#009688','Optum':'#3f51b5','TTEC Digital':'#795548','Bank of America':'#607d8b',
  'UHG':'#2196f3','CareFirst':'#8bc34a','CHCO':'#ff7043','Incyte':'#ab47bc','MGB':'#26a69a',
};
const stageColors = { 'Listen & Consult':'#78909c','Inspire & Design':'#448aff','Empower & Achieve':'#00c853','Manage & Optimize':'#ff9100','Realize Value':'#7c4dff' };
const stageOrder = ['Listen & Consult','Inspire & Design','Empower & Achieve','Manage & Optimize','Realize Value'];

const renderTimelines = () => {
  timelineWrap.empty();
  const cf = custSelect.value;
  const sf = statusSelect.value;
  const osf = oppStageSelect.value;
  const fqf = fqSelect.value;
  const calRange = window._pipelineDateRange;

  // ═══ OPPORTUNITY TIMELINE ═══
  const todayMs = today.ts || Date.now();
  let oppRangeStart, oppRangeEnd;
  if (calRange) {
    oppRangeStart = new Date(calRange.start.getTime() - 7 * 86400000);
    oppRangeEnd = new Date(calRange.end.getTime() + 7 * 86400000);
  } else if (fqf) {
    const [fy, q] = fqf.split('-').map(Number);
    const fq = quarters.find(f => f.label === `FY${fy} Q${q}`);
    if (fq) { oppRangeStart = new Date(fq.start.getTime() - 7 * 86400000); oppRangeEnd = new Date(fq.end.getTime() + 7 * 86400000); }
    else { oppRangeStart = new Date(todayMs - 14 * 86400000); oppRangeEnd = new Date(todayMs + 120 * 86400000); }
  } else {
    oppRangeStart = new Date(todayMs - 14 * 86400000);
    oppRangeEnd = new Date(todayMs + 120 * 86400000);
  }
  let filteredOpps = allOpps.where(o => safeDate(o.estClose) != null);
  if (cf) filteredOpps = filteredOpps.where(o => getCustFromFolder(o.file.folder) === cf);
  if (osf === 'past-close') filteredOpps = filteredOpps.where(o => { const cd = safeDate(o.estClose); return cd && cd < today; });
  else if (osf) filteredOpps = filteredOpps.where(o => o.stage === osf);
  if (fqf) filteredOpps = filteredOpps.where(o => matchesQuarter(safeDate(o.estClose), fqf));
  if (calRange) filteredOpps = filteredOpps.where(o => { const cd = safeDate(o.estClose); if (!cd) return false; const ts = cd.ts || new Date(cd).getTime(); return ts >= calRange.start.getTime() && ts <= calRange.end.getTime(); });
  filteredOpps = filteredOpps.sort(o => o.estClose, 'asc');
  const undatedOpps = allOpps.where(o => safeDate(o.estClose) == null && (!cf || getCustFromFolder(o.file.folder) === cf));

  // Extend axis to encompass all filtered items (past-due included)
  for (const o of filteredOpps) { const cd = safeDate(o.estClose); if (cd) { const ts = cd.ts || new Date(cd).getTime(); if (ts < oppRangeStart.getTime()) oppRangeStart = new Date(ts - 7 * 86400000); if (ts > oppRangeEnd.getTime()) oppRangeEnd = new Date(ts + 7 * 86400000); } }
  const oppRangeDays = Math.round((oppRangeEnd - oppRangeStart) / 86400000);

  const oppByCustomer = {};
  for (const opp of filteredOpps) { const c = getCustFromFolder(opp.file.folder); if (!oppByCustomer[c]) oppByCustomer[c] = []; oppByCustomer[c].push(opp); }

  const oppHeader = timelineWrap.createEl('h2', { text: `🎯 Opportunity Timeline (${filteredOpps.length} dated · ${undatedOpps.length} undated)`, attr: { style: 'margin-top:0;' } });
  const oppWrap = timelineWrap.createEl('div', { attr: { style: 'overflow-x:auto;margin:8px 0;' } });
  renderMonthHeaders(oppWrap, oppRangeStart, oppRangeEnd, oppRangeDays, '120px');
  const oppTodayDays = Math.round((todayMs - oppRangeStart.getTime()) / 86400000);
  const oppTodayOff = (oppTodayDays >= 0 && oppTodayDays <= oppRangeDays) ? (oppTodayDays / oppRangeDays * 100) : -10;

  for (const [cust, oppList] of Object.entries(oppByCustomer).sort((a,b) => a[0].localeCompare(b[0]))) {
    const row = oppWrap.createEl('div', { attr: { style: 'display:flex;align-items:center;margin:3px 0;min-height:28px;' } });
    row.createEl('a', { text: cust, attr: { 'data-href': cust, href: cust, class: 'internal-link', style: 'min-width:110px;max-width:110px;font-size:0.78em;font-weight:600;text-decoration:none;padding-right:10px;text-align:right;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;' } });
    const track = row.createEl('div', { attr: { style: 'flex:1;position:relative;height:24px;background:var(--background-modifier-border);border-radius:4px;overflow:hidden;min-width:600px;' } });
    track.createEl('div', { attr: { style: `position:absolute;left:${oppTodayOff}%;top:0;bottom:0;width:1px;background:#448aff;opacity:0.5;z-index:2;` } });
    for (const opp of oppList) {
      const cd = safeDate(opp.estClose); if (!cd) continue;
      const dayOff = Math.round((cd - oppRangeStart) / (1000*60*60*24));
      if (dayOff < 0 || dayOff > oppRangeDays) continue;
      const pct = (dayOff / oppRangeDays) * 100;
      const stage = opp.stage || 'Unknown'; const acr = getACR(opp); const over = cd < today;
      const dc = over ? '#d50000' : (stageColors[stage] || '#888');
      track.createEl('a', { attr: { 'data-href': opp.file.name, href: opp.file.name, class: 'internal-link', title: `${opp.opportunity || opp.file.name}\nStage: ${stage}\nEst Close: ${safeFmt(cd, "MMM d, yyyy")}${acr > 0 ? '\nACR: ' + fmtK(acr) : ''}`, style: `position:absolute;left:calc(${pct}% - 7px);top:3px;width:14px;height:14px;background:${dc};border:2px solid var(--background-primary);z-index:3;cursor:pointer;text-decoration:none;transform:rotate(45deg);` } });
    }
  }

  // Opp legend
  const oLeg = timelineWrap.createEl('div', { attr: { style: 'display:flex;gap:16px;margin-top:12px;flex-wrap:wrap;' } });
  for (const s of stageOrder) { const i = oLeg.createEl('div', { attr: { style: 'display:flex;align-items:center;gap:4px;' } }); i.createEl('div', { attr: { style: `width:10px;height:10px;background:${stageColors[s]};transform:rotate(45deg);` } }); i.createEl('span', { text: s, attr: { style: 'font-size:0.72em;opacity:0.6;' } }); }
  const ooi = oLeg.createEl('div', { attr: { style: 'display:flex;align-items:center;gap:4px;' } }); ooi.createEl('div', { attr: { style: 'width:10px;height:10px;background:#d50000;transform:rotate(45deg);' } }); ooi.createEl('span', { text: 'Past Est Close', attr: { style: 'font-size:0.72em;opacity:0.6;' } });
  const oti = oLeg.createEl('div', { attr: { style: 'display:flex;align-items:center;gap:4px;' } }); oti.createEl('div', { attr: { style: 'width:10px;height:10px;border-radius:50%;background:#448aff;' } }); oti.createEl('span', { text: 'Today', attr: { style: 'font-size:0.72em;opacity:0.6;' } });

  if (undatedOpps.length > 0) {
    const uw = timelineWrap.createEl('div', { attr: { style: 'margin-top:16px;' } });
    uw.createEl('div', { text: `⚠️ ${undatedOpps.length} opportunities missing estClose`, attr: { style: 'font-size:0.78em;font-weight:600;color:#ff9100;margin-bottom:8px;' } });
    const ubc = {};
    for (const opp of undatedOpps) { const c = getCustFromFolder(opp.file.folder); if (!ubc[c]) ubc[c] = []; ubc[c].push(opp); }
    for (const [cust, ops] of Object.entries(ubc).sort((a,b) => a[0].localeCompare(b[0]))) {
      const cr = uw.createEl('div', { attr: { style: 'display:flex;align-items:flex-start;gap:8px;margin:4px 0;padding:6px 10px;border-radius:6px;background:var(--background-secondary);border-left:3px solid #ff9100;' } });
      cr.createEl('a', { text: cust, attr: { 'data-href': cust, href: cust, class: 'internal-link', style: 'min-width:90px;font-size:0.78em;font-weight:600;text-decoration:none;' } });
      const ol = cr.createEl('div', { attr: { style: 'display:flex;flex-wrap:wrap;gap:6px;' } });
      for (const opp of ops) ol.createEl('a', { text: opp.file.name, attr: { 'data-href': opp.file.name, href: opp.file.name, class: 'internal-link', style: 'font-size:0.72em;padding:2px 6px;border-radius:4px;background:rgba(255,145,0,0.1);text-decoration:none;white-space:nowrap;' } });
    }
  }

  // ═══ MILESTONE TIMELINE ═══
  let msRangeStart, msRangeEnd;
  if (calRange) {
    msRangeStart = new Date(calRange.start.getTime() - 7 * 86400000);
    msRangeEnd = new Date(calRange.end.getTime() + 7 * 86400000);
  } else if (fqf) {
    const [fy, q] = fqf.split('-').map(Number);
    const fq = quarters.find(f => f.label === `FY${fy} Q${q}`);
    if (fq) { msRangeStart = new Date(fq.start.getTime() - 7 * 86400000); msRangeEnd = new Date(fq.end.getTime() + 7 * 86400000); }
    else { msRangeStart = new Date(todayMs - 14 * 86400000); msRangeEnd = new Date(todayMs + 90 * 86400000); }
  } else {
    msRangeStart = new Date(todayMs - 14 * 86400000);
    msRangeEnd = new Date(todayMs + 90 * 86400000);
  }
  let filteredMs = allMilestones.where(m => m.milestonedate);
  if (cf) filteredMs = filteredMs.where(m => getCustFromFolder(m.file.folder) === cf);
  if (sf === 'overdue') filteredMs = filteredMs.where(m => m.milestonedate < today && m.status !== 'Blocked');
  else if (sf) filteredMs = filteredMs.where(m => m.status === sf);
  if (fqf) filteredMs = filteredMs.where(m => matchesQuarter(m.milestonedate, fqf));
  if (calRange) filteredMs = filteredMs.where(m => { const ts = m.milestonedate.ts || new Date(m.milestonedate).getTime(); return ts >= calRange.start.getTime() && ts <= calRange.end.getTime(); });
  filteredMs = filteredMs.sort(m => m.milestonedate, 'asc');

  // Extend axis to encompass all filtered milestones (past-due included)
  for (const m of filteredMs) { const md = m.milestonedate; if (md) { const ts = md.ts || new Date(md).getTime(); if (ts < msRangeStart.getTime()) msRangeStart = new Date(ts - 7 * 86400000); if (ts > msRangeEnd.getTime()) msRangeEnd = new Date(ts + 7 * 86400000); } }
  const msRangeDays = Math.round((msRangeEnd - msRangeStart) / 86400000);

  countDisplay.textContent = `${filteredOpps.length} opps · ${filteredMs.length} milestones`;

  const tree = {};
  for (const ms of filteredMs) {
    const cust = getCustFromFolder(ms.file.folder);
    const opp = ms.opportunity || '(unlinked)';
    if (!tree[cust]) tree[cust] = {};
    if (!tree[cust][opp]) tree[cust][opp] = [];
    tree[cust][opp].push(ms);
  }

  timelineWrap.createEl('h2', { text: `📅 Milestone Timeline (${filteredMs.length})` });
  const msWrap = timelineWrap.createEl('div', { attr: { style: 'overflow-x:auto;margin:8px 0;' } });
  const labelWidth = '200px';
  renderMonthHeaders(msWrap, msRangeStart, msRangeEnd, msRangeDays, labelWidth);
  const msTodayDays = Math.round((todayMs - msRangeStart.getTime()) / 86400000);
  const msTodayOff = (msTodayDays >= 0 && msTodayDays <= msRangeDays) ? (msTodayDays / msRangeDays * 100) : -10;

  for (const [cust, opps] of Object.entries(tree).sort((a,b) => a[0].localeCompare(b[0]))) {
    const color = custColors[cust] || '#888';
    const custH = msWrap.createEl('div', { attr: { style: 'margin-top:8px;margin-bottom:2px;' } });
    custH.createEl('a', { text: `▸ ${cust}`, attr: { 'data-href': cust, href: cust, class: 'internal-link', style: `font-size:0.82em;font-weight:700;text-decoration:none;color:${color};` } });
    for (const [oppName, msList] of Object.entries(opps).sort((a,b) => a[0].localeCompare(b[0]))) {
      const row = msWrap.createEl('div', { attr: { style: 'display:flex;align-items:center;margin:2px 0;min-height:26px;' } });
      const lbl = row.createEl('div', { attr: { style: `min-width:${labelWidth};max-width:${labelWidth};padding-left:14px;padding-right:8px;text-align:right;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;` } });
      if (oppName === '(unlinked)') lbl.createEl('span', { text: oppName, attr: { style: 'font-size:0.72em;opacity:0.4;font-style:italic;' } });
      else lbl.createEl('a', { text: oppName.length > 28 ? oppName.substring(0, 28) + '…' : oppName, attr: { 'data-href': oppName, href: oppName, class: 'internal-link', title: oppName, style: 'font-size:0.72em;font-weight:500;text-decoration:none;' } });
      const track = row.createEl('div', { attr: { style: 'flex:1;position:relative;height:22px;background:var(--background-modifier-border);border-radius:4px;overflow:hidden;min-width:600px;' } });
      track.createEl('div', { attr: { style: `position:absolute;left:${msTodayOff}%;top:0;bottom:0;width:1px;background:#448aff;opacity:0.5;z-index:2;` } });
      for (const ms of msList) {
        const msDate = ms.milestonedate;
        const dayOff = Math.round((msDate - msRangeStart) / (1000*60*60*24));
        if (dayOff < 0 || dayOff > msRangeDays) continue;
        const pct = (dayOff / msRangeDays) * 100;
        const over = msDate < today;
        const sc = ms.status === 'Blocked' ? '#ff1744' : ms.status === 'At Risk' ? '#ff9100' : over ? '#d50000' : color;
        track.createEl('a', { attr: { 'data-href': ms.file.name, href: ms.file.name, class: 'internal-link', title: `${ms.file.name}\n${ms.status} — ${safeFmt(msDate, "MMM d, yyyy")}`, style: `position:absolute;left:calc(${pct}% - 6px);top:3px;width:16px;height:16px;border-radius:50%;background:${sc};border:2px solid var(--background-primary);z-index:3;cursor:pointer;text-decoration:none;` } });
      }
    }
  }

  const mLeg = timelineWrap.createEl('div', { attr: { style: 'display:flex;gap:16px;margin-top:12px;flex-wrap:wrap;' } });
  for (const [l, c] of [['On Track','#00c853'],['At Risk','#ff9100'],['Blocked','#ff1744'],['Overdue','#d50000'],['Today','#448aff']]) {
    const i = mLeg.createEl('div', { attr: { style: 'display:flex;align-items:center;gap:4px;' } });
    i.createEl('div', { attr: { style: `width:10px;height:10px;border-radius:50%;background:${c};` } });
    i.createEl('span', { text: l, attr: { style: 'font-size:0.72em;opacity:0.6;' } });
  }
};

custSelect.addEventListener('change', renderTimelines);
oppStageSelect.addEventListener('change', renderTimelines);
statusSelect.addEventListener('change', renderTimelines);
fqSelect.addEventListener('change', renderTimelines);
window.addEventListener('pipeline-date-range', renderTimelines);
renderTimelines();
```

---

> [!tip] Navigation
> [[Day View]] · [[Customer Scorecard]] · [[People Directory]]
