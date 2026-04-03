---
tags:
  - dashboard
cssclasses:
  - wide-page
sticker: lucide//person-standing
---

# 👥 People Directory

> [!abstract]- 📡 Local Data · Last synced from MSX / CRM
> Everything on this dashboard is rendered from **local vault files**. To refresh, ask **@mcaps-iq** in GitHub Copilot Chat or run the **Sidekick** sync command.

```dataviewjs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 👥 PEOPLE DIRECTORY — filterable, searchable
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const allPeople = dv.pages('"People"').where(p => p.tags && dv.func.contains(p.tags, 'people'));
const selStyle = 'font-size:0.8em;padding:4px 8px;border-radius:6px;border:1px solid var(--background-modifier-border);background:var(--background-secondary);color:var(--text-normal);';

// Collect filter values
const orgSet = new Set();
const customerSet = new Set();
const titleSet = new Set();

for (const p of allPeople) {
  if (p.org) orgSet.add(String(p.org).trim());
  const custs = p.customers;
  if (custs && Array.isArray(custs)) {
    for (const c of custs) {
      const cs = String(c).replace(/"/g, '').trim();
      if (cs && cs !== 'null' && cs !== 'undefined') customerSet.add(cs);
    }
  }
  if (p.title) {
    const t = String(p.title).replace(/"/g, '').trim();
    if (t && t !== 'null') titleSet.add(t);
  }
}

// ─── Filter Bar ───
const filterWrap = this.container.createEl('div');
filterWrap.style.cssText = 'display:flex;gap:10px;align-items:center;flex-wrap:wrap;padding:8px 0 12px 0;border-bottom:1px solid var(--background-modifier-border);margin-bottom:12px;';

// Search
filterWrap.createEl('span', { text: '🔍', attr: { style: 'font-size:1em;' } });
const searchInput = filterWrap.createEl('input', { attr: { type: 'text', placeholder: 'Search name or email…', style: 'font-size:0.8em;padding:5px 10px;border-radius:6px;border:1px solid var(--background-modifier-border);background:var(--background-secondary);color:var(--text-normal);min-width:180px;' } });

// Org filter
filterWrap.createEl('span', { text: 'Org:', attr: { style: 'font-size:0.75em;font-weight:600;opacity:0.5;margin-left:4px;' } });
const orgSelect = filterWrap.createEl('select', { attr: { style: selStyle } });
orgSelect.createEl('option', { text: 'All', attr: { value: '' } });
for (const o of [...orgSet].sort()) orgSelect.createEl('option', { text: o, attr: { value: o } });

// Customer filter
filterWrap.createEl('span', { text: 'Customer:', attr: { style: 'font-size:0.75em;font-weight:600;opacity:0.5;margin-left:4px;' } });
const customerSelect = filterWrap.createEl('select', { attr: { style: selStyle } });
customerSelect.createEl('option', { text: 'All', attr: { value: '' } });
for (const c of [...customerSet].sort()) customerSelect.createEl('option', { text: c, attr: { value: c } });

// Title filter
filterWrap.createEl('span', { text: 'Role:', attr: { style: 'font-size:0.75em;font-weight:600;opacity:0.5;margin-left:4px;' } });
const titleSelect = filterWrap.createEl('select', { attr: { style: selStyle } });
titleSelect.createEl('option', { text: 'All', attr: { value: '' } });
for (const t of [...titleSet].sort()) titleSelect.createEl('option', { text: t, attr: { value: t } });

const countDisplay = filterWrap.createEl('span', { attr: { style: 'font-size:0.75em;opacity:0.45;margin-left:auto;' } });

// ─── Results ───
const resultsWrap = this.container.createEl('div');
const detailPanel = this.container.createEl('div');
detailPanel.style.display = 'none';
let activeCard = null;

const orgColors = { 'internal': '#448aff', 'customer': '#00c853', 'partner': '#ff9800' };

const normalize = (s) => s ? String(s).replace(/"/g, '').trim().toLowerCase() : '';
const getCusts = (p) => {
  if (!p.customers || !Array.isArray(p.customers)) return [];
  return p.customers.map(c => String(c).replace(/"/g, '').trim()).filter(c => c && c !== 'null');
};

const render = () => {
  resultsWrap.empty();
  detailPanel.empty();
  detailPanel.style.display = 'none';
  activeCard = null;

  const search = searchInput.value.toLowerCase().trim();
  const orgF = orgSelect.value;
  const custF = customerSelect.value;
  const titleF = titleSelect.value;

  let filtered = allPeople;
  if (search) filtered = filtered.where(p =>
    normalize(p.file.name).includes(search) ||
    normalize(p.email).includes(search) ||
    normalize(p.title).includes(search) ||
    normalize(p.company).includes(search)
  );
  if (orgF) filtered = filtered.where(p => normalize(p.org) === orgF.toLowerCase());
  if (custF) filtered = filtered.where(p => {
    const custs = getCusts(p);
    return custs.some(c => c.toLowerCase() === custF.toLowerCase());
  });
  if (titleF) filtered = filtered.where(p => normalize(p.title) === titleF.toLowerCase());

  filtered = filtered.sort(p => p.file.name, 'asc');
  countDisplay.textContent = `${filtered.length} of ${allPeople.length} people`;

  if (filtered.length === 0) {
    resultsWrap.createEl('div', { text: 'No people match the current filters.', attr: { style: 'padding:20px;text-align:center;opacity:0.4;font-size:0.88em;' } });
    return;
  }

  // Group by org
  const groups = {};
  for (const p of filtered) {
    const org = normalize(p.org) || 'other';
    if (!groups[org]) groups[org] = [];
    groups[org].push(p);
  }
  const orgOrder = ['internal', 'customer', 'partner', 'other'];
  const orgLabels = { 'internal': '🔵 Internal (Microsoft)', 'customer': '🟢 Customer Contacts', 'partner': '🟠 Partners', 'other': '⚪ Other' };

  for (const orgKey of orgOrder) {
    if (!groups[orgKey]) continue;
    const people = groups[orgKey];

    const section = resultsWrap.createEl('div', { attr: { style: 'margin-bottom:16px;' } });
    const oc = orgColors[orgKey] || '#888';
    const hdr = section.createEl('div', { attr: { style: `display:flex;justify-content:space-between;align-items:center;padding:6px 10px;border-radius:6px;background:${oc}15;border-left:3px solid ${oc};margin-bottom:6px;` } });
    hdr.createEl('span', { text: orgLabels[orgKey] || orgKey, attr: { style: `font-size:0.82em;font-weight:700;color:${oc};` } });
    hdr.createEl('span', { text: String(people.length), attr: { style: `font-size:0.75em;padding:2px 8px;border-radius:10px;background:${oc}22;color:${oc};font-weight:600;` } });

    const grid = section.createEl('div', {
      attr: { style: 'display:grid;grid-template-columns:repeat(auto-fill, minmax(280px, 1fr));gap:6px;' }
    });

    for (const p of people) {
      const custs = getCusts(p);
      const title = p.title ? String(p.title).replace(/"/g, '').trim() : '';
      const company = p.company ? String(p.company).replace(/"/g, '').trim() : '';
      const email = p.email ? String(p.email).replace(/"/g, '').trim() : '';

      const card = grid.createEl('div', {
        attr: { 'data-person': p.file.name, style: 'padding:8px 10px;border-radius:6px;background:var(--background-secondary);border:1px solid var(--background-modifier-border);cursor:pointer;transition:outline 0.15s;' }
      });

      // Name row
      const nameRow = card.createEl('div', { attr: { style: 'display:flex;align-items:center;gap:6px;' } });
      nameRow.createEl('a', { text: p.file.name, attr: { 'data-href': p.file.name, href: p.file.name, class: 'internal-link', style: 'font-weight:600;font-size:0.85em;text-decoration:none;' } });

      // Title + company
      if (title && title !== 'null') {
        card.createEl('div', { text: title, attr: { style: 'font-size:0.72em;opacity:0.55;margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;' } });
      }

      // Meta row: company + customers
      const metaRow = card.createEl('div', { attr: { style: 'display:flex;justify-content:space-between;align-items:center;margin-top:3px;gap:6px;' } });
      if (company) {
        metaRow.createEl('span', { text: company, attr: { style: `font-size:0.7em;font-weight:500;color:${oc};opacity:0.7;` } });
      }
      if (custs.length > 0) {
        const custChips = metaRow.createEl('div', { attr: { style: 'display:flex;gap:3px;flex-wrap:wrap;justify-content:flex-end;' } });
        for (const c of custs.slice(0, 3)) {
          custChips.createEl('a', { text: c, attr: { 'data-href': c, href: c, class: 'internal-link', style: 'font-size:0.62em;padding:1px 5px;border-radius:8px;background:var(--background-modifier-border);text-decoration:none;white-space:nowrap;' } });
        }
        if (custs.length > 3) custChips.createEl('span', { text: `+${custs.length - 3}`, attr: { style: 'font-size:0.6em;opacity:0.4;' } });
      }

      // Click to expand detail
      card.addEventListener('click', (e) => {
        if (e.target.closest('a')) return;
        if (activeCard === p.file.name) {
          detailPanel.empty();
          detailPanel.style.display = 'none';
          activeCard = null;
          resultsWrap.querySelectorAll('[data-person]').forEach(el => { el.style.outline = 'none'; });
          return;
        }
        activeCard = p.file.name;
        resultsWrap.querySelectorAll('[data-person]').forEach(el => { el.style.outline = 'none'; });
        card.style.outline = `2px solid ${oc}`;

        detailPanel.empty();
        detailPanel.style.display = 'block';
        const dp = detailPanel.createEl('div', {
          attr: { style: `margin-top:10px;padding:14px 18px;border-radius:10px;background:var(--background-secondary);border-left:4px solid ${oc};` }
        });

        const dpHdr = dp.createEl('div', { attr: { style: 'display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:8px;' } });
        const dpLeft = dpHdr.createEl('div');
        dpLeft.createEl('a', { text: p.file.name, attr: { 'data-href': p.file.name, href: p.file.name, class: 'internal-link', style: 'font-weight:700;font-size:1.05em;text-decoration:none;' } });
        if (title && title !== 'null') dpLeft.createEl('div', { text: title, attr: { style: 'font-size:0.82em;opacity:0.6;margin-top:2px;' } });
        dpHdr.createEl('span', { text: orgKey, attr: { style: `font-size:0.72em;font-weight:600;padding:3px 10px;border-radius:10px;background:${oc}22;color:${oc};` } });

        const grid = dp.createEl('div', { attr: { style: 'display:grid;grid-template-columns:1fr 1fr;gap:4px 20px;margin-bottom:8px;' } });
        const addField = (label, value) => {
          if (!value) return;
          const row = grid.createEl('div', { attr: { style: 'display:flex;justify-content:space-between;padding:3px 0;border-bottom:1px solid var(--background-modifier-border);' } });
          row.createEl('span', { text: label, attr: { style: 'font-size:0.78em;opacity:0.5;' } });
          row.createEl('span', { text: value, attr: { style: 'font-size:0.78em;font-weight:500;' } });
        };
        addField('Company', company);
        addField('Email', email);
        if (p.alias) addField('Alias', String(p.alias));

        if (custs.length > 0) {
          const custRow = dp.createEl('div', { attr: { style: 'margin-top:4px;' } });
          custRow.createEl('span', { text: 'Customers: ', attr: { style: 'font-size:0.78em;opacity:0.5;' } });
          for (const c of custs) {
            custRow.createEl('a', { text: c, attr: { 'data-href': c, href: c, class: 'internal-link', style: 'font-size:0.78em;margin-right:6px;text-decoration:none;' } });
          }
        }

        // Recent meetings
        const meetings = dv.pages('"Meetings"').where(m => {
          if (!m.file.tasks) return false;
          const content = m.file.name;
          return false;
        });
        // Search by attendees file link
        const personMeetings = dv.pages('"Meetings"').where(m => {
          const links = m.file.outlinks;
          return links && links.some(l => l.path && l.path.endsWith(p.file.name + '.md'));
        }).sort(m => m.date, 'desc').slice(0, 5);

        if (personMeetings.length > 0) {
          const mtgSection = dp.createEl('div', { attr: { style: 'margin-top:8px;' } });
          mtgSection.createEl('div', { text: `📅 Recent Meetings (${personMeetings.length})`, attr: { style: 'font-size:0.78em;font-weight:600;opacity:0.5;margin-bottom:4px;' } });
          for (const m of personMeetings) {
            const row = mtgSection.createEl('div', { attr: { style: 'display:flex;justify-content:space-between;padding:2px 0;' } });
            row.createEl('a', { text: m.file.name, attr: { 'data-href': m.file.name, href: m.file.name, class: 'internal-link', style: 'font-size:0.78em;text-decoration:none;' } });
            if (m.date) {
              try {
                const dt = typeof m.date === 'string' ? dv.date(m.date) : m.date;
                row.createEl('span', { text: dt ? dv.func.dateformat(dt, 'MMM d') : '', attr: { style: 'font-size:0.72em;opacity:0.45;' } });
              } catch(e) {}
            }
          }
        }
      });
    }
  }
};

searchInput.addEventListener('input', render);
orgSelect.addEventListener('change', render);
customerSelect.addEventListener('change', render);
titleSelect.addEventListener('change', render);
render();
```
