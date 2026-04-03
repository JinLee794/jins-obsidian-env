---
tags:
  - dashboard
sticker: lucide//calendar
selected_date: 2026-04-02
cssclasses:
  - wide-page
---

# 📅 Day View

> [!abstract]- 📡 Local Data · Last synced from MSX / CRM
> Everything on this dashboard is rendered from **local vault files**. To refresh, ask **@mcaps-iq** in GitHub Copilot Chat or run the **Sidekick** sync command.
> 
> If you have **Sidekick** enabled, try prompting it "help me prep for my day"
 
```meta-bind
INPUT[date:selected_date]
```

---

```dataviewjs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📅 DAY VIEW — all daily context for selected date
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const safeDate = (d) => {
  if (!d) return null;
  try { return typeof d === 'string' ? dv.date(d) : d; } catch(e) { return null; }
};
const safeFmt = (d, fmt) => {
  const dt = safeDate(d);
  return dt ? dv.func.dateformat(dt, fmt) : '';
};

const raw = dv.current().selected_date;
const sel = safeDate(raw) || dv.date('today');
const today = dv.date('today');
const selStr = safeFmt(sel, 'yyyy-MM-dd');
const isToday = selStr === safeFmt(today, 'yyyy-MM-dd');
const isFuture = sel > today;
const isPast = sel < today && !isToday;

const dayLabel = isToday ? '**Today** — ' + safeFmt(sel, 'EEEE, MMMM d, yyyy')
  : isFuture ? safeFmt(sel, 'EEEE, MMMM d, yyyy') + ' *(upcoming)*'
  : safeFmt(sel, 'EEEE, MMMM d, yyyy') + ' *(past)*';

const root = dv.el('div', '', { attr: { style: 'margin:0;' } });

// ── Date header ──
root.createEl('div', { text: dayLabel, attr: { style: 'font-size:1.05em;font-weight:700;margin-bottom:10px;' } });

// Quick nav
const nav = root.createEl('div', { attr: { style: 'display:flex;gap:10px;margin-bottom:14px;font-size:0.78em;' } });
nav.createEl('a', { text: '⬅️ Yesterday', attr: { 'data-href': 'Day View', href: 'Day View', class: 'internal-link', style: 'text-decoration:none;opacity:0.6;' } });
nav.createEl('a', { text: 'Today', attr: { 'data-href': 'Day View', href: 'Day View', class: 'internal-link', style: 'text-decoration:none;font-weight:600;' } });
nav.createEl('a', { text: 'Tomorrow ➡️', attr: { 'data-href': 'Day View', href: 'Day View', class: 'internal-link', style: 'text-decoration:none;opacity:0.6;' } });
nav.createEl('span', { text: '·', attr: { style: 'opacity:0.3;' } });
nav.createEl('a', { text: 'Command Center', attr: { 'data-href': 'Command Center', href: 'Command Center', class: 'internal-link', style: 'text-decoration:none;opacity:0.6;' } });
nav.createEl('a', { text: 'Customer Scorecard', attr: { 'data-href': 'Customer Scorecard', href: 'Customer Scorecard', class: 'internal-link', style: 'text-decoration:none;opacity:0.6;' } });

// ── Daily Note ──
const dailyName = selStr;
const dailyPage = dv.page(`Daily/${dailyName}`);
const dailySection = root.createEl('div', { attr: { style: 'margin-bottom:12px;' } });
if (dailyPage) {
  const link = dailySection.createEl('a', { text: `📓 Daily Note: ${dailyName}`, attr: { 'data-href': dailyName, href: dailyName, class: 'internal-link', style: 'font-weight:600;text-decoration:none;font-size:0.88em;' } });
} else {
  dailySection.createEl('span', { text: `📓 No daily note for ${dailyName}`, attr: { style: 'font-size:0.88em;opacity:0.4;' } });
}

// ── Meetings ──
const meetings = dv.pages('"Meetings"').where(m => m.date && safeFmt(m.date, 'yyyy-MM-dd') === selStr).sort(m => m.file.name, 'asc');
const mtgSection = root.createEl('div', { attr: { style: 'margin-bottom:12px;' } });
mtgSection.createEl('div', { text: `📅 Meetings (${meetings.length})`, attr: { style: 'font-weight:700;font-size:0.88em;margin-bottom:4px;' } });
if (meetings.length === 0) {
  mtgSection.createEl('span', { text: 'No meetings scheduled.', attr: { style: 'font-size:0.82em;opacity:0.4;' } });
} else {
  for (const m of meetings) {
    const row = mtgSection.createEl('div', { attr: { style: `padding:4px 8px;margin:2px 0;border-radius:4px;background:var(--background-secondary);display:flex;justify-content:space-between;align-items:center;font-size:0.82em;${m.status === 'open' ? 'border-left:2px solid #ff9100;' : ''}` } });
    row.createEl('a', { text: m.file.name, attr: { 'data-href': m.file.name, href: m.file.name, class: 'internal-link', style: 'font-weight:500;text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;' } });
    const meta = [];
    if (m.customer) meta.push(typeof m.customer === 'object' && m.customer.path ? m.customer.path.split('/').pop() : String(m.customer));
    if (m.project) meta.push(String(m.project));
    if (meta.length) row.createEl('span', { text: meta.join(' · '), attr: { style: 'font-size:0.85em;opacity:0.45;flex-shrink:0;margin-left:8px;' } });
  }
}

// ── Action Items Due ──
const allPages = dv.pages('"Meetings" OR "Projects" OR "Daily" OR "Customers"');
const dueTasks = allPages.file.tasks.where(t => !t.completed && t.due && safeFmt(t.due, 'yyyy-MM-dd') === selStr);
const dueSection = root.createEl('div', { attr: { style: 'margin-bottom:12px;' } });
dueSection.createEl('div', { text: `✅ Action Items Due (${dueTasks.length})`, attr: { style: 'font-weight:700;font-size:0.88em;margin-bottom:4px;' } });
if (dueTasks.length === 0) {
  dueSection.createEl('span', { text: 'No tasks due.', attr: { style: 'font-size:0.82em;opacity:0.4;' } });
} else {
  for (const t of dueTasks.slice(0, 20)) {
    const row = dueSection.createEl('div', { attr: { style: 'padding:3px 8px;margin:1px 0;border-radius:4px;background:var(--background-secondary);font-size:0.82em;display:flex;gap:6px;align-items:flex-start;' } });
    row.createEl('span', { text: '☐', attr: { style: 'flex-shrink:0;opacity:0.4;' } });
    row.createEl('span', { text: t.text, attr: { style: 'min-width:0;' } });
  }
  if (dueTasks.length > 20) dueSection.createEl('div', { text: `+${dueTasks.length - 20} more`, attr: { style: 'font-size:0.72em;opacity:0.4;margin-top:2px;' } });
}

// ── Open Action Items from day's notes ──
const dayPages = dv.pages('"Daily" OR "Meetings"').where(p =>
  p.file.name === selStr || (p.date && safeFmt(p.date, 'yyyy-MM-dd') === selStr)
);
const openTasks = dayPages.file.tasks.where(t => !t.completed);
const openSection = root.createEl('div', { attr: { style: 'margin-bottom:12px;' } });
openSection.createEl('div', { text: `🔲 Open Items from ${isToday ? "today's" : "this day's"} notes (${openTasks.length})`, attr: { style: 'font-weight:700;font-size:0.88em;margin-bottom:4px;' } });
if (openTasks.length === 0) {
  openSection.createEl('span', { text: 'All clear.', attr: { style: 'font-size:0.82em;opacity:0.4;' } });
} else {
  for (const t of openTasks.slice(0, 20)) {
    const row = openSection.createEl('div', { attr: { style: 'padding:3px 8px;margin:1px 0;border-radius:4px;background:var(--background-secondary);font-size:0.82em;display:flex;gap:6px;align-items:flex-start;' } });
    row.createEl('span', { text: '☐', attr: { style: 'flex-shrink:0;opacity:0.4;' } });
    row.createEl('span', { text: t.text, attr: { style: 'min-width:0;' } });
  }
  if (openTasks.length > 20) openSection.createEl('div', { text: `+${openTasks.length - 20} more`, attr: { style: 'font-size:0.72em;opacity:0.4;margin-top:2px;' } });
}

// ── Projects with target date  ──
const targetProjects = dv.pages('"Projects"').where(p => p.status === 'active' && p.target_date && safeFmt(p.target_date, 'yyyy-MM-dd') === selStr);
if (targetProjects.length > 0) {
  const prjSection = root.createEl('div', { attr: { style: 'margin-bottom:12px;' } });
  prjSection.createEl('div', { text: `🔥 Projects Due (${targetProjects.length})`, attr: { style: 'font-weight:700;font-size:0.88em;margin-bottom:4px;' } });
  for (const p of targetProjects) {
    const row = prjSection.createEl('div', { attr: { style: 'padding:4px 8px;margin:2px 0;border-radius:4px;background:var(--background-secondary);display:flex;justify-content:space-between;align-items:center;font-size:0.82em;' } });
    row.createEl('a', { text: p.file.name, attr: { 'data-href': p.file.name, href: p.file.name, class: 'internal-link', style: 'font-weight:600;text-decoration:none;' } });
    const meta = [p.customer ? String(p.customer) : '', p.type || '', p.priority || ''].filter(Boolean).join(' · ');
    if (meta) row.createEl('span', { text: meta, attr: { style: 'font-size:0.85em;opacity:0.45;flex-shrink:0;margin-left:8px;' } });
  }
}

// ── Notes modified/created on this date ──
const allFiles = dv.pages('"Projects" OR "Meetings" OR "Customers" OR "Daily" OR "People" OR "Inbox"');
const modified = allFiles.where(p => safeFmt(dv.date(p.file.mtime), 'yyyy-MM-dd') === selStr).sort(p => p.file.mtime, 'desc');
const created = allFiles.where(p => safeFmt(dv.date(p.file.ctime), 'yyyy-MM-dd') === selStr).sort(p => p.file.ctime, 'desc');

const activityGrid = root.createEl('div', { attr: { style: 'display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:12px;' } });

// Modified
const modCol = activityGrid.createEl('div');
modCol.createEl('div', { text: `📌 Modified (${modified.length})`, attr: { style: 'font-weight:700;font-size:0.85em;margin-bottom:4px;' } });
if (modified.length === 0) {
  modCol.createEl('span', { text: 'None.', attr: { style: 'font-size:0.78em;opacity:0.4;' } });
} else {
  for (const p of modified.slice(0, 12)) {
    const row = modCol.createEl('div', { attr: { style: 'padding:2px 6px;margin:1px 0;border-radius:3px;background:var(--background-secondary);display:flex;justify-content:space-between;align-items:center;font-size:0.78em;' } });
    row.createEl('a', { text: p.file.name, attr: { 'data-href': p.file.name, href: p.file.name, class: 'internal-link', style: 'text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;' } });
    row.createEl('span', { text: safeFmt(dv.date(p.file.mtime), 'HH:mm'), attr: { style: 'opacity:0.4;flex-shrink:0;margin-left:6px;' } });
  }
  if (modified.length > 12) modCol.createEl('div', { text: `+${modified.length - 12} more`, attr: { style: 'font-size:0.68em;opacity:0.4;margin-top:2px;' } });
}

// Created
const createCol = activityGrid.createEl('div');
createCol.createEl('div', { text: `📝 Created (${created.length})`, attr: { style: 'font-weight:700;font-size:0.85em;margin-bottom:4px;' } });
if (created.length === 0) {
  createCol.createEl('span', { text: 'None.', attr: { style: 'font-size:0.78em;opacity:0.4;' } });
} else {
  for (const p of created.slice(0, 12)) {
    const row = createCol.createEl('div', { attr: { style: 'padding:2px 6px;margin:1px 0;border-radius:3px;background:var(--background-secondary);display:flex;justify-content:space-between;align-items:center;font-size:0.78em;' } });
    row.createEl('a', { text: p.file.name, attr: { 'data-href': p.file.name, href: p.file.name, class: 'internal-link', style: 'text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;' } });
    row.createEl('span', { text: safeFmt(dv.date(p.file.ctime), 'HH:mm'), attr: { style: 'opacity:0.4;flex-shrink:0;margin-left:6px;' } });
  }
  if (created.length > 12) createCol.createEl('div', { text: `+${created.length - 12} more`, attr: { style: 'font-size:0.68em;opacity:0.4;margin-top:2px;' } });
}

// ── Open Meetings from last 7 days (prep / follow-up) ──
const d7 = today - dv.duration('7 days');
const openMeetings = dv.pages('"Meetings"').where(m => m.status === 'open' && m.date && safeDate(m.date) >= d7 && safeDate(m.date) <= sel).sort(m => m.date, 'desc');
if (openMeetings.length > 0) {
  const openMtgSection = root.createEl('div', { attr: { style: 'margin-bottom:12px;' } });
  openMtgSection.createEl('div', { text: `🗓 Open Meetings — Last 7 Days (${openMeetings.length})`, attr: { style: 'font-weight:700;font-size:0.88em;margin-bottom:4px;' } });
  openMtgSection.createEl('div', { text: isFuture ? 'Prep or follow up before this date.' : 'These may need follow-up.', attr: { style: 'font-size:0.75em;opacity:0.4;margin-bottom:4px;' } });
  for (const m of openMeetings.slice(0, 10)) {
    const row = openMtgSection.createEl('div', { attr: { style: 'padding:4px 8px;margin:2px 0;border-radius:4px;background:var(--background-secondary);display:flex;justify-content:space-between;align-items:center;font-size:0.82em;border-left:2px solid #ff9100;' } });
    row.createEl('a', { text: m.file.name, attr: { 'data-href': m.file.name, href: m.file.name, class: 'internal-link', style: 'font-weight:500;text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;' } });
    const meta = [m.customer ? String(typeof m.customer === 'object' && m.customer.path ? m.customer.path.split('/').pop() : m.customer) : '', m.summary || ''].filter(Boolean).join(' · ');
    if (meta) row.createEl('span', { text: meta, attr: { style: 'font-size:0.85em;opacity:0.45;flex-shrink:0;margin-left:8px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:200px;' } });
  }
}

// ── High-Priority Active Projects ──
const hiPri = dv.pages('"Projects"').where(p => p.status === 'active' && p.priority === 'high').sort(p => p.target_date, 'asc');
if (hiPri.length > 0) {
  const hiSection = root.createEl('div', { attr: { style: 'margin-bottom:12px;' } });
  hiSection.createEl('div', { text: `🚀 Active High-Priority Projects (${hiPri.length})`, attr: { style: 'font-weight:700;font-size:0.88em;margin-bottom:4px;' } });
  for (const p of hiPri) {
    const row = hiSection.createEl('div', { attr: { style: 'padding:4px 8px;margin:2px 0;border-radius:4px;background:var(--background-secondary);display:flex;justify-content:space-between;align-items:center;font-size:0.82em;' } });
    row.createEl('a', { text: p.file.name, attr: { 'data-href': p.file.name, href: p.file.name, class: 'internal-link', style: 'font-weight:600;text-decoration:none;' } });
    const meta = [p.customer ? String(p.customer) : '', p.type || '', p.target_date ? safeFmt(p.target_date, 'MMM d') : ''].filter(Boolean).join(' · ');
    if (meta) row.createEl('span', { text: meta, attr: { style: 'font-size:0.85em;opacity:0.45;flex-shrink:0;margin-left:8px;' } });
  }
}

// ── Inbox (only show for today/future) ──
if (isToday || isFuture) {
  const inbox = dv.pages('"Inbox"').sort(p => p.file.ctime, 'desc').slice(0, 10);
  if (inbox.length > 0) {
    const inSection = root.createEl('div', { attr: { style: 'margin-bottom:12px;' } });
    inSection.createEl('div', { text: `📨 Inbox (${inbox.length})`, attr: { style: 'font-weight:700;font-size:0.88em;margin-bottom:4px;' } });
    for (const p of inbox) {
      const row = inSection.createEl('div', { attr: { style: 'padding:3px 8px;margin:1px 0;border-radius:4px;background:var(--background-secondary);font-size:0.82em;' } });
      row.createEl('a', { text: p.file.name, attr: { 'data-href': p.file.name, href: p.file.name, class: 'internal-link', style: 'text-decoration:none;' } });
    }
  }
}
```
