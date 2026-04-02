---
tags:
  - dashboard
sticker: lucide//person-standing
---

# 👥 People Directory

> [!abstract]- 📡 Local Data · Last synced from MSX / CRM
> Everything on this dashboard is rendered from **local vault files**. To refresh, ask **@mcaps-iq** in GitHub Copilot Chat or run the **Sidekick** sync command.

## Internal (Microsoft)

```dataview
TABLE title, company, email
FROM "People"
WHERE org = "internal"
SORT file.name ASC
```

## Customer Contacts

```dataview
TABLE title, company, customers, email
FROM "People"
WHERE org = "customer"
SORT company ASC
```

## Partners

```dataview
TABLE title, company, email
FROM "People"
WHERE org = "partner"
SORT file.name ASC
```

## All People

```dataview
TABLE title, company, org, customers
FROM "People"
SORT file.name ASC
```
