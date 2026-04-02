---
tags:
  - dashboard
cssclasses:
  - wide-page
sticker: lucide//user-check
selected_customer: Stryker
---

# 🏢 Customer Scorecard

> [!abstract]- 📡 Local Data · Last synced from MSX / CRM
> Everything on this dashboard is rendered from **local vault files** (Meetings, Customers, Opportunities, Milestones, Projects).
> To refresh or pull latest data, ask **@mcaps-iq** in GitHub Copilot Chat or run the **Sidekick** sync command.

```meta-bind
INPUT[suggester(optionQuery(#customer), useLinks(false)):selected_customer]
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
  for (let i = 0; i < 5; i++) {
    let qq = curQ + i, fy = curFY; while (qq > 4) { qq -= 4; fy++; }
    const label = `FY${fy} Q${qq}`; const range = getQRange(fy, qq); const qc = qColors[qq];
    const isActive = rangeStart && rangeEnd && Math.abs((rangeStart < rangeEnd ? rangeStart : rangeEnd).getTime() - range.start.getTime()) < 86400000 && Math.abs((rangeStart < rangeEnd ? rangeEnd : rangeStart).getTime() - range.end.getTime()) < 86400000;
    const btn = btnBar.createEl('span', { text: label, attr: { style: `font-size:0.72em;font-weight:600;padding:3px 10px;border-radius:12px;cursor:pointer;background:${isActive ? qc : qc + '22'};color:${isActive ? '#fff' : qc};border:1px solid ${qc}44;transition:all 0.15s;user-select:none;` } });
    btn.addEventListener('click', (e) => { e.stopPropagation(); rangeStart = range.start; rangeEnd = range.end; clicking = false; viewStartMonth = range.start.getMonth(); viewStartYear = range.start.getFullYear(); dispatchRange(); renderCal(); });
  }
  const clearBtn = btnBar.createEl('span', { text: '✕ Clear', attr: { style: 'font-size:0.72em;padding:3px 10px;border-radius:12px;cursor:pointer;background:var(--background-secondary);color:var(--text-muted);border:1px solid var(--background-modifier-border);margin-left:4px;user-select:none;' } });
  clearBtn.addEventListener('click', (e) => { e.stopPropagation(); rangeStart = null; rangeEnd = null; clicking = false; dispatchRange(); renderCal(); });
};
renderCal();
```

---

```dataviewjs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🏢 CUSTOMER SCORECARD — compact, dense layout
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
const isActiveOpp = (o) => o.status === 'Active' || !!o.stage;
const getACR = (o) => Number(o.recurringACR) || Number(o.acr) || 0;
const fmtK = (v) => v >= 1000000 ? `$${(v/1000000).toFixed(1)}M` : v >= 1000 ? `$${(v/1000).toFixed(0)}K` : `$${v}`;

const selected = dv.current().selected_customer;
if (!selected) {
  this.container.createEl('p', { text: 'Select a customer above.', attr: { style: 'font-style:italic;opacity:0.5;' } });
} else {

const today = dv.date('today');
const d7 = today - dv.duration('7 days');
const d14 = today - dv.duration('14 days');
const d30 = today - dv.duration('30 days');

const custPage = dv.page(`Customers/${selected}/${selected}`);
const allMilestones = dv.pages('#milestone').where(m => {
  const parts = m.file.folder.split('/');
  const ci = parts.indexOf('Customers');
  return ci >= 0 && ci + 1 < parts.length && parts[ci + 1] === selected;
});
const allOpportunities = dv.pages('#opportunity').where(o => {
  if (!o.file.folder.includes('opportunities')) return false;
  const parts = o.file.folder.split('/');
  const ci = parts.indexOf('Customers');
  return ci >= 0 && ci + 1 < parts.length && parts[ci + 1] === selected;
});
const projects = dv.pages('"Projects"').where(p => getCust(p.customer) === selected);
const allMeetings = dv.pages('"Meetings"').where(m => getCust(m.customer) === selected && m.date).sort(m => m.date, 'desc');

const inCalRange = (dateVal) => {
  const calRange = window._pipelineDateRange;
  if (!calRange || !dateVal) return true;
  const ts = dateVal.ts || new Date(dateVal).getTime();
  return ts >= calRange.start.getTime() && ts <= calRange.end.getTime();
};

const render = () => {
  this.container.empty();
  const calRange = window._pipelineDateRange;
  const hasRange = !!calRange;

  // Apply calendar filters
  const milestones = hasRange
    ? allMilestones.where(m => m.milestonedate && inCalRange(m.milestonedate))
    : allMilestones;
  const opportunities = hasRange
    ? allOpportunities.where(o => { const cd = safeDate(o.estClose); return cd ? inCalRange(cd) : true; })
    : allOpportunities;
  const meetings = hasRange
    ? allMeetings.where(m => inCalRange(safeDate(m.date)))
    : allMeetings;

  const lastMtgDate = allMeetings.first() ? safeDate(allMeetings.first().date) : null;
  const msOnTrack = milestones.where(m => m.status === 'On Track').length;
  const msAtRisk = milestones.where(m => m.status === 'At Risk').length;
  const msBlocked = milestones.where(m => m.status === 'Blocked').length;
  const msTotal = milestones.length;
  const activeOpps = opportunities.where(o => isActiveOpp(o)).length;
  const mtgsCount = meetings.length;

  // ACR calculations
  const totalACR = opportunities.where(o => isActiveOpp(o)).values.reduce((sum, o) => sum + getACR(o), 0);
  const atRiskOppNames = new Set();
  for (const ms of milestones) {
    if (ms.status === 'At Risk' || ms.status === 'Blocked') {
      if (ms.opportunity) atRiskOppNames.add(ms.opportunity);
    }
  }
  const dollarAtRisk = opportunities.where(o => isActiveOpp(o)).values
    .filter(o => atRiskOppNames.has(o.file.name))
    .reduce((sum, o) => sum + getACR(o), 0);

  // RAG (always based on full data, not filtered)
  const allMsBlocked = allMilestones.where(m => m.status === 'Blocked').length;
  const allMsAtRisk = allMilestones.where(m => m.status === 'At Risk').length;
  let ragColor = '#00c853', ragText = '🟢 Healthy';
  if (allMsBlocked > 0 || !lastMtgDate || lastMtgDate < d14) { ragColor = '#ff1744'; ragText = '🔴 Needs Attention'; }
  else if (allMsAtRisk > 0 || lastMtgDate < d7) { ragColor = '#ff9100'; ragText = '🟡 Monitor'; }

  // Range badge
  const rangeBadge = hasRange
    ? ` · 📅 filtered`
    : '';

  // ━━━ RICH HEADER CARD ━━━
  const header = this.container.createEl('div', {
    attr: { style: `padding:12px 16px;border-radius:10px;background:var(--background-secondary);border-left:4px solid ${ragColor};margin:0 0 10px 0;` }
  });

  const hRow = header.createEl('div', { attr: { style: 'display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:6px;' } });
  const hLeft = hRow.createEl('div', { attr: { style: 'display:flex;align-items:center;gap:10px;' } });
  hLeft.createEl('a', { text: selected, attr: { 'data-href': selected, href: selected, class: 'internal-link', style: 'font-size:1.2em;font-weight:800;text-decoration:none;' } });
  hLeft.createEl('span', { text: ragText, attr: { style: `font-size:0.78em;padding:2px 8px;border-radius:10px;background:${ragColor}22;color:${ragColor};font-weight:600;` } });
  if (hasRange) {
    hLeft.createEl('span', { text: '📅 date range active', attr: { style: 'font-size:0.68em;padding:2px 8px;border-radius:10px;background:var(--text-accent)22;color:var(--text-accent);font-weight:600;' } });
  }
  if (custPage) {
    const meta = [];
    if (custPage.has_unified !== undefined) meta.push(custPage.has_unified ? 'Unified ✅' : 'Not Unified');
    if (custPage.MSX?.account) meta.push(`MSX: ${custPage.MSX.account}`);
    if (meta.length) hLeft.createEl('span', { text: meta.join(' · '), attr: { style: 'font-size:0.72em;opacity:0.45;' } });
  }

  const kpiRow = header.createEl('div', { attr: { style: 'display:flex;gap:20px;margin-top:8px;flex-wrap:wrap;' } });
  const miniCard = (label, value, color) => {
    const c = kpiRow.createEl('div', { attr: { style: 'text-align:center;' } });
    c.createEl('div', { text: String(value), attr: { style: `font-size:1.4em;font-weight:700;color:${color};line-height:1.2;` } });
    c.createEl('div', { text: label, attr: { style: 'font-size:0.65em;text-transform:uppercase;opacity:0.5;' } });
  };
  miniCard('Milestones', msTotal, '#7c4dff');
  miniCard('MS On Track', msOnTrack, '#00c853');
  miniCard('MS At Risk', msAtRisk, '#ff9100');
  miniCard('MS Blocked', msBlocked, '#ff1744');
  miniCard('Active Opps', activeOpps, '#448aff');
  miniCard('Opp ACR', fmtK(totalACR), '#00bcd4');
  miniCard('Opp $ At Risk', dollarAtRisk > 0 ? fmtK(dollarAtRisk) : '—', dollarAtRisk > 0 ? '#ff1744' : '#888');
  miniCard(hasRange ? 'Mtgs (range)' : 'Mtgs (30d)', hasRange ? mtgsCount : allMeetings.where(m => { const d = safeDate(m.date); return d && d >= d30; }).length, '#e040fb');

  if (msTotal > 0) {
    const pct = Math.round((msOnTrack / msTotal) * 100);
    const barWrap = header.createEl('div', { attr: { style: 'margin-top:8px;' } });
    barWrap.createEl('div', { text: `${pct}% on track`, attr: { style: 'font-size:0.65em;opacity:0.45;margin-bottom:2px;' } });
    const bar = barWrap.createEl('div', { attr: { style: 'height:6px;border-radius:3px;background:var(--background-modifier-border);overflow:hidden;display:flex;' } });
    if (msOnTrack > 0) bar.createEl('div', { attr: { style: `width:${(msOnTrack/msTotal)*100}%;background:#00c853;` } });
    if (msAtRisk > 0) bar.createEl('div', { attr: { style: `width:${(msAtRisk/msTotal)*100}%;background:#ff9100;` } });
    if (msBlocked > 0) bar.createEl('div', { attr: { style: `width:${(msBlocked/msTotal)*100}%;background:#ff1744;` } });
  }

  // ━━━ CONTENT ━━━
  const root = this.container.createEl('div', { attr: { style: 'margin:0;' } });

  // ── OPPORTUNITIES ──
  const oppSection = root.createEl('div', { attr: { style: 'margin-bottom:10px;' } });
  oppSection.createEl('div', { text: `🎯 Opportunities (${opportunities.length})`, attr: { style: 'font-weight:700;font-size:0.88em;margin-bottom:3px;' } });

  const oppGrid = oppSection.createEl('div', {
    attr: { style: 'display:grid;grid-template-columns:1fr 1fr;gap:2px 10px;' }
  });

  for (const opp of opportunities) {
    const isStale = opp.last_validated && (today - opp.last_validated) > dv.duration('30 days');
    const oppMs = milestones.where(m => m.opportunity === opp.file.name);
    const oppMsOT = oppMs.where(m => m.status === 'On Track').length;
    const oppMsAR = oppMs.where(m => m.status === 'At Risk').length;
    const oppMsBL = oppMs.where(m => m.status === 'Blocked').length;
    const oppAcr = getACR(opp);
    const oppHasRisk = oppMsAR > 0 || oppMsBL > 0;

    const row = oppGrid.createEl('div', {
      attr: { style: `padding:4px 7px;border-radius:4px;background:var(--background-secondary);font-size:0.82em;${oppHasRisk ? 'border-left:2px solid #ff1744;' : ''}` }
    });
    const titleRow = row.createEl('div', { attr: { style: 'display:flex;align-items:center;gap:4px;' } });
    titleRow.createEl('a', { text: opp.file.name, attr: { 'data-href': opp.file.name, href: opp.file.name, class: 'internal-link', style: 'font-weight:600;text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;' } });
    if (oppAcr > 0) titleRow.createEl('span', { text: fmtK(oppAcr), attr: { style: `font-size:0.72em;font-weight:600;flex-shrink:0;color:${oppHasRisk ? '#ff1744' : '#00bcd4'};` } });
    if (isStale) titleRow.createEl('span', { text: 'STALE', attr: { style: 'font-size:0.7em;color:#ff9100;font-weight:600;flex-shrink:0;' } });
    const metaParts = [opp.salesplay, opp.owner].filter(Boolean);
    if (oppMs.length > 0) metaParts.push(`MS: ${oppMsOT}✅${oppMsAR > 0 ? ' '+oppMsAR+'⚠️' : ''}${oppMsBL > 0 ? ' '+oppMsBL+'🔴' : ''}`);
    row.createEl('div', {
      text: metaParts.join(' · '),
      attr: { style: 'font-size:0.72em;opacity:0.45;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;' }
    });
  }

  // ── MILESTONES ──
  const msSection = root.createEl('div', { attr: { style: 'margin-bottom:10px;' } });
  msSection.createEl('div', { text: `📌 Milestones (${msTotal})`, attr: { style: 'font-weight:700;font-size:0.88em;margin-bottom:3px;' } });

  const sortedMs = milestones.sort(m => m.status === 'Blocked' ? 0 : m.status === 'At Risk' ? 1 : 2);

  const msGrid = msSection.createEl('div', {
    attr: { style: 'display:grid;grid-template-columns:1fr 1fr;gap:2px 10px;' }
  });

  for (const ms of sortedMs) {
    const isOverdue = ms.milestonedate && ms.milestonedate < today;
    const daysUntil = ms.milestonedate ? Math.round((ms.milestonedate - today) / (1000 * 60 * 60 * 24)) : null;
    const icon = ms.status === 'On Track' ? '✅' : ms.status === 'At Risk' ? '⚠️' : '🔴';
    const parentOpp = ms.opportunity ? opportunities.find(o => o.file.name === ms.opportunity) : null;
    const msAcr = parentOpp ? (Number(parentOpp.acr) || 0) : 0;

    const row = msGrid.createEl('div', {
      attr: { style: 'padding:3px 6px;border-radius:4px;background:var(--background-secondary);display:flex;align-items:center;gap:5px;font-size:0.82em;' }
    });
    row.createEl('span', { text: icon, attr: { style: 'flex-shrink:0;font-size:0.85em;' } });
    const info = row.createEl('div', { attr: { style: 'flex:1;min-width:0;display:flex;align-items:baseline;gap:4px;' } });
    info.createEl('a', { text: ms.file.name, attr: { 'data-href': ms.file.name, href: ms.file.name, class: 'internal-link', style: 'font-weight:600;text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;' } });
    if (isOverdue) info.createEl('span', { text: `${Math.abs(daysUntil)}d overdue`, attr: { style: 'font-size:0.72em;color:#d50000;font-weight:600;flex-shrink:0;' } });
    const rightInfo = row.createEl('div', { attr: { style: 'display:flex;align-items:baseline;gap:4px;flex-shrink:0;' } });
    if (ms.owner) rightInfo.createEl('span', { text: String(ms.owner).replace(/\s*\(.*\)/, ''), attr: { style: 'font-size:0.7em;opacity:0.4;white-space:nowrap;' } });
    if (msAcr > 0) rightInfo.createEl('span', { text: fmtK(msAcr), attr: { style: `font-size:0.68em;font-weight:600;color:${ms.status !== 'On Track' ? '#ff1744' : '#00bcd4'};` } });
    rightInfo.createEl('span', {
      text: safeFmt(ms.milestonedate, "MMM d"),
      attr: { style: 'font-size:0.78em;opacity:0.45;white-space:nowrap;' }
    });
  }

  // ── MEETINGS + PROJECTS (side by side) ──
  const bWrap = root.createEl('div', { attr: { style: 'display:grid;grid-template-columns:1fr 1fr;gap:10px;' } });

  const mtgCol = bWrap.createEl('div');
  const displayMtgs = hasRange ? meetings.slice(0, 8) : allMeetings.where(m => { const d = safeDate(m.date); return d && d >= d30; }).slice(0, 8);
  mtgCol.createEl('div', { text: `📅 Meetings (${hasRange ? meetings.length + ' in range' : allMeetings.where(m => { const d = safeDate(m.date); return d && d >= d30; }).length + ' / 30d'})`, attr: { style: 'font-weight:700;font-size:0.85em;margin-bottom:3px;' } });
  if (displayMtgs.length === 0) {
    mtgCol.createEl('div', { text: hasRange ? 'None in range' : 'None in 30d', attr: { style: 'font-size:0.78em;opacity:0.4;' } });
  }
  for (const m of displayMtgs) {
    const row = mtgCol.createEl('div', {
      attr: { style: `padding:3px 7px;margin:1px 0;border-radius:4px;background:var(--background-secondary);display:flex;justify-content:space-between;align-items:center;font-size:0.78em;${m.status === 'open' ? 'border-left:2px solid #ff9100;' : ''}` }
    });
    row.createEl('a', { text: m.file.name, attr: { 'data-href': m.file.name, href: m.file.name, class: 'internal-link', style: 'font-weight:500;text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;' } });
    row.createEl('span', { text: safeFmt(m.date, "MMM d"), attr: { style: 'opacity:0.45;flex-shrink:0;margin-left:4px;' } });
  }

  const prjCol = bWrap.createEl('div');
  const activeProjects = projects.where(p => p.status === 'active');
  prjCol.createEl('div', { text: `🔥 Projects (${activeProjects.length})`, attr: { style: 'font-weight:700;font-size:0.85em;margin-bottom:3px;' } });
  if (activeProjects.length === 0) {
    prjCol.createEl('div', { text: 'None active', attr: { style: 'font-size:0.78em;opacity:0.4;' } });
  }
  for (const p of activeProjects) {
    const priColor = p.priority === 'high' ? '#ff5252' : p.priority === 'medium' ? '#ffab40' : '#69f0ae';
    const row = prjCol.createEl('div', {
      attr: { style: 'padding:3px 7px;margin:1px 0;border-radius:4px;background:var(--background-secondary);display:flex;justify-content:space-between;align-items:center;font-size:0.78em;' }
    });
    row.createEl('a', { text: p.file.name, attr: { 'data-href': p.file.name, href: p.file.name, class: 'internal-link', style: 'font-weight:600;text-decoration:none;' } });
    row.createEl('span', { text: `${p.priority || ''} · ${p.type || ''}`, attr: { style: `opacity:0.5;flex-shrink:0;` } });
  }
};

render();
window.addEventListener('pipeline-date-range', render);
} // end if(selected)
```

```dataviewjs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🎯 OPPORTUNITY TIMELINE — Gantt for selected customer
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const selected = dv.current().selected_customer;
if (!selected) { /* skip */ } else {

const today = dv.date('today');
const safeDate = (d) => {
  if (!d) return null;
  try { return typeof d === 'string' ? dv.date(d) : d; } catch(e) { return null; }
};
const safeFmt = (d, fmt) => {
  if (!d) return '';
  try {
    const dt = typeof d === 'string' ? dv.date(d) : d;
    return dt ? dv.func.dateformat(dt, fmt) : '';
  } catch(e) { return ''; }
};
const fmtK = (v) => v >= 1000000 ? `$${(v/1000000).toFixed(1)}M` : v >= 1000 ? `$${(v/1000).toFixed(0)}K` : `$${v}`;

const allOpps = dv.pages('#opportunity').where(o => {
  if (!o.file.folder.includes('opportunities')) return false;
  const parts = o.file.folder.split('/');
  const ci = parts.indexOf('Customers');
  return ci >= 0 && ci + 1 < parts.length && parts[ci + 1] === selected;
});

const stageColors = {
  'Listen & Consult': '#78909c',
  'Inspire & Design': '#448aff',
  'Empower & Achieve': '#00c853',
  'Manage & Optimize': '#ff9100',
  'Realize Value': '#7c4dff',
};
const stageOrder = ['Listen & Consult', 'Inspire & Design', 'Empower & Achieve', 'Manage & Optimize', 'Realize Value'];

const render = () => {
  this.container.empty();

  const calRange = window._pipelineDateRange;
  let displayOpps = allOpps;
  if (calRange) {
    displayOpps = allOpps.where(o => {
      const cd = safeDate(o.estClose);
      if (!cd) return true; // keep undated opps visible
      const ts = cd.ts || new Date(cd).getTime();
      return ts >= calRange.start.getTime() && ts <= calRange.end.getTime();
    });
  }

  const rangeStart = today - dv.duration('14 days');
  const rangeEnd = today + dv.duration('120 days');
  const rangeDays = Math.round((rangeEnd - rangeStart) / (1000 * 60 * 60 * 24));

  const withDate = displayOpps.where(o => safeDate(o.estClose) != null).sort(o => o.estClose, 'asc');
  const withoutDate = displayOpps.where(o => safeDate(o.estClose) == null);

  if (displayOpps.length === 0) {
    this.container.createEl('p', { text: `No opportunities for ${selected}.`, attr: { style: 'font-style:italic;opacity:0.5;' } });
    return;
  }

  this.container.createEl('h3', { text: `🎯 Opportunity Timeline — ${selected} (${withDate.length} dated · ${withoutDate.length} undated)` });

  if (withDate.length > 0) {
    const wrapper = this.container.createEl('div', { attr: { style: 'overflow-x:auto;margin:8px 0;' } });

    const headerBar = wrapper.createEl('div', {
      attr: { style: 'display:flex;margin-left:10px;height:24px;border-bottom:1px solid var(--background-modifier-border);margin-bottom:8px;position:relative;' }
    });
    let d = new Date(rangeStart.ts || rangeStart);
    const endTs = rangeEnd.ts || rangeEnd;
    const months = new Set();
    while (d <= endTs) {
      const key = `${d.getFullYear()}-${d.getMonth()}`;
      if (!months.has(key)) {
        months.add(key);
        const dayOffset = Math.round((d - (rangeStart.ts ? new Date(rangeStart.ts) : new Date(rangeStart))) / (1000*60*60*24));
        const pctLeft = (dayOffset / rangeDays) * 100;
        headerBar.createEl('span', {
          text: d.toLocaleDateString('en-US', { month: 'short', year: 'numeric' }),
          attr: { style: `position:absolute;left:${pctLeft}%;font-size:0.7em;opacity:0.5;top:4px;` }
        });
      }
      d.setDate(d.getDate() + 7);
    }

    const todayOffset = Math.round(14 / rangeDays * 100);

    const track = wrapper.createEl('div', {
      attr: { style: 'position:relative;height:28px;background:var(--background-modifier-border);border-radius:4px;overflow:hidden;min-width:600px;' }
    });
    track.createEl('div', {
      attr: { style: `position:absolute;left:${todayOffset}%;top:0;bottom:0;width:1px;background:#448aff;opacity:0.5;z-index:2;` }
    });

    for (const opp of withDate) {
      const closeDate = safeDate(opp.estClose);
      if (!closeDate) continue;
      const dayOff = Math.round((closeDate - rangeStart) / (1000*60*60*24));
      if (dayOff < 0 || dayOff > rangeDays) continue;
      const pctLeft = (dayOff / rangeDays) * 100;
      const stage = opp.stage || 'Unknown';
      const acr = Number(opp.recurringACR) || Number(opp.acr) || 0;
      const isOverdue = closeDate < today;
      const dotColor = isOverdue ? '#d50000' : (stageColors[stage] || '#888');
      track.createEl('a', {
        attr: {
          'data-href': opp.file.name, href: opp.file.name, class: 'internal-link',
          title: `${opp.opportunity || opp.file.name}\nStage: ${stage}\nEst Close: ${safeFmt(closeDate, "MMM d, yyyy")}${acr > 0 ? '\nACR: ' + fmtK(acr) : ''}`,
          style: `position:absolute;left:calc(${pctLeft}% - 7px);top:5px;width:14px;height:14px;background:${dotColor};border:2px solid var(--background-primary);z-index:3;cursor:pointer;text-decoration:none;transform:rotate(45deg);`
        }
      });
    }

    const legend = this.container.createEl('div', { attr: { style: 'display:flex;gap:16px;margin-top:8px;flex-wrap:wrap;' } });
    for (const stage of stageOrder) {
      const item = legend.createEl('div', { attr: { style: 'display:flex;align-items:center;gap:4px;' } });
      item.createEl('div', { attr: { style: `width:10px;height:10px;background:${stageColors[stage]};transform:rotate(45deg);` } });
      item.createEl('span', { text: stage, attr: { style: 'font-size:0.72em;opacity:0.6;' } });
    }
    const overdueItem = legend.createEl('div', { attr: { style: 'display:flex;align-items:center;gap:4px;' } });
    overdueItem.createEl('div', { attr: { style: 'width:10px;height:10px;background:#d50000;transform:rotate(45deg);' } });
    overdueItem.createEl('span', { text: 'Past Est Close', attr: { style: 'font-size:0.72em;opacity:0.6;' } });
    const todayItem = legend.createEl('div', { attr: { style: 'display:flex;align-items:center;gap:4px;' } });
    todayItem.createEl('div', { attr: { style: 'width:10px;height:10px;border-radius:50%;background:#448aff;' } });
    todayItem.createEl('span', { text: 'Today', attr: { style: 'font-size:0.72em;opacity:0.6;' } });
  }

  if (withoutDate.length > 0) {
    const undatedWrap = this.container.createEl('div', { attr: { style: 'margin-top:10px;' } });
    undatedWrap.createEl('div', {
      text: `⚠️ ${withoutDate.length} opportunities missing estClose`,
      attr: { style: 'font-size:0.78em;font-weight:600;color:#ff9100;margin-bottom:6px;' }
    });
    const chips = undatedWrap.createEl('div', { attr: { style: 'display:flex;flex-wrap:wrap;gap:6px;' } });
    for (const opp of withoutDate) {
      chips.createEl('a', {
        text: opp.file.name,
        attr: {
          'data-href': opp.file.name, href: opp.file.name, class: 'internal-link',
          style: 'font-size:0.72em;padding:2px 6px;border-radius:4px;background:rgba(255,145,0,0.1);text-decoration:none;white-space:nowrap;'
        }
      });
    }
  }
};

render();
window.addEventListener('pipeline-date-range', render);
} // end if(selected)
```


---

```dataviewjs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📅 MILESTONE TIMELINE — Gantt grouped by Opportunity
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const selected = dv.current().selected_customer;
if (!selected) { /* skip */ } else {

const today = dv.date('today');
const safeFmt = (d, fmt) => {
  if (!d) return '';
  try {
    const dt = typeof d === 'string' ? dv.date(d) : d;
    return dt ? dv.func.dateformat(dt, fmt) : '';
  } catch(e) { return ''; }
};

const allMilestones = dv.pages('#milestone')
  .where(m => {
    if (!m.milestonedate) return false;
    const parts = m.file.folder.split('/');
    const ci = parts.indexOf('Customers');
    return ci >= 0 && ci + 1 < parts.length && parts[ci + 1] === selected;
  })
  .sort(m => m.milestonedate, 'asc');

const render = () => {
  this.container.empty();

  const calRange = window._pipelineDateRange;
  let milestones = allMilestones;
  if (calRange) {
    milestones = allMilestones.where(m => {
      const ts = m.milestonedate.ts || new Date(m.milestonedate).getTime();
      return ts >= calRange.start.getTime() && ts <= calRange.end.getTime();
    });
  }

  const rangeStart = today - dv.duration('14 days');
  const rangeEnd = today + dv.duration('90 days');
  const rangeDays = Math.round((rangeEnd - rangeStart) / (1000 * 60 * 60 * 24));

  if (milestones.length === 0) {
    this.container.createEl('p', { text: `No milestones with dates for ${selected}.`, attr: { style: 'font-style:italic;opacity:0.5;' } });
    return;
  }

  // Group by opportunity
  const byOpp = {};
  for (const ms of milestones) {
    const opp = ms.opportunity || '(unlinked)';
    if (!byOpp[opp]) byOpp[opp] = [];
    byOpp[opp].push(ms);
  }
  const oppEntries = Object.entries(byOpp).sort((a,b) => a[0].localeCompare(b[0]));

  this.container.createEl('h3', { text: `📅 Milestone Timeline — ${selected}` });
  const wrapper = this.container.createEl('div', { attr: { style: 'overflow-x:auto;margin:8px 0;' } });

  const labelWidth = '180px';
  const headerBar = wrapper.createEl('div', {
    attr: { style: `display:flex;margin-left:${labelWidth};height:24px;border-bottom:1px solid var(--background-modifier-border);margin-bottom:8px;position:relative;` }
  });
  let d = new Date(rangeStart.ts || rangeStart);
  const endTs = rangeEnd.ts || rangeEnd;
  const months = new Set();
  while (d <= endTs) {
    const key = `${d.getFullYear()}-${d.getMonth()}`;
    if (!months.has(key)) {
      months.add(key);
      const dayOffset = Math.round((d - (rangeStart.ts ? new Date(rangeStart.ts) : new Date(rangeStart))) / (1000*60*60*24));
      const pctLeft = (dayOffset / rangeDays) * 100;
      headerBar.createEl('span', {
        text: d.toLocaleDateString('en-US', { month: 'short', year: 'numeric' }),
        attr: { style: `position:absolute;left:${pctLeft}%;font-size:0.7em;opacity:0.5;top:4px;` }
      });
    }
    d.setDate(d.getDate() + 7);
  }

  const todayOffset = Math.round(14 / rangeDays * 100);

  for (const [oppName, msList] of oppEntries) {
    const row = wrapper.createEl('div', {
      attr: { style: 'display:flex;align-items:center;margin:2px 0;min-height:26px;' }
    });
    const labelEl = row.createEl('div', {
      attr: { style: `min-width:${labelWidth};max-width:${labelWidth};padding-right:8px;text-align:right;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;` }
    });
    if (oppName === '(unlinked)') {
      labelEl.createEl('span', { text: oppName, attr: { style: 'font-size:0.72em;opacity:0.4;font-style:italic;' } });
    } else {
      labelEl.createEl('a', {
        text: oppName.length > 28 ? oppName.substring(0, 28) + '…' : oppName,
        attr: {
          'data-href': oppName, href: oppName, class: 'internal-link',
          title: oppName,
          style: 'font-size:0.72em;font-weight:500;text-decoration:none;'
        }
      });
    }
    const track = row.createEl('div', {
      attr: { style: 'flex:1;position:relative;height:22px;background:var(--background-modifier-border);border-radius:4px;overflow:hidden;min-width:500px;' }
    });
    track.createEl('div', {
      attr: { style: `position:absolute;left:${todayOffset}%;top:0;bottom:0;width:1px;background:#448aff;opacity:0.5;z-index:2;` }
    });
    for (const ms of msList) {
      const msDate = ms.milestonedate;
      const dayOff = Math.round((msDate - rangeStart) / (1000*60*60*24));
      if (dayOff < 0 || dayOff > rangeDays) continue;
      const pctLeft = (dayOff / rangeDays) * 100;
      const isOverdue = msDate < today;
      const statusColor = ms.status === 'Blocked' ? '#ff1744' : ms.status === 'At Risk' ? '#ff9100' : isOverdue ? '#d50000' : '#00c853';
      track.createEl('a', {
        attr: {
          'data-href': ms.file.name, href: ms.file.name, class: 'internal-link',
          title: `${ms.file.name}\n${ms.status} — ${safeFmt(msDate, "MMM d, yyyy")}`,
          style: `position:absolute;left:calc(${pctLeft}% - 6px);top:3px;width:16px;height:16px;border-radius:50%;background:${statusColor};border:2px solid var(--background-primary);z-index:3;cursor:pointer;text-decoration:none;`
        }
      });
    }
  }

  const legend = this.container.createEl('div', { attr: { style: 'display:flex;gap:16px;margin-top:8px;flex-wrap:wrap;' } });
  for (const [label, color] of [['On Track','#00c853'],['At Risk','#ff9100'],['Blocked','#ff1744'],['Overdue','#d50000'],['Today','#448aff']]) {
    const item = legend.createEl('div', { attr: { style: 'display:flex;align-items:center;gap:4px;' } });
    item.createEl('div', { attr: { style: `width:10px;height:10px;border-radius:50%;background:${color};` } });
    item.createEl('span', { text: label, attr: { style: 'font-size:0.72em;opacity:0.6;' } });
  }
};

render();
window.addEventListener('pipeline-date-range', render);
} // end if(selected)
```

---

> [!tip] Navigation
> [[Command Center]] · [[Day View]] · [[People Directory]]
