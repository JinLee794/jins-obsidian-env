# Jin's Obsidian Environment

Portable export/import of Obsidian vault configuration — themes, plugins, plugin settings, hotkeys, appearance, and CSS snippets.

## Getting Started

### 1. Install Obsidian

Download and install Obsidian from [obsidian.md/download](https://obsidian.md/download).

### 2. Create or open a vault

- Launch Obsidian and either **Create new vault** or **Open folder as vault**.
- Choose a location you'll remember — you'll need the path in the next step.

**Where is my vault?** Your vault is just a regular folder on disk. You can find the path from Obsidian: click the vault switcher (bottom-left vault name) → the path is shown under each vault. Common locations:

| OS | Typical path |
|---|---|
| macOS | `~/obsidian/MyVault` |
| Windows | `C:\Users\YourName\obsidian\MyVault` |
| Linux | `~/obsidian/MyVault` |

### 3. Clone this repo

```bash
git clone <this-repo-url>
cd jins-obsidian-env
```

### 4. Import the config into your vault

**Close Obsidian first** to avoid conflicts.

**macOS / Linux:**
```bash
./import.sh ~/obsidian/MyVault
```

**Windows (PowerShell):**
```powershell
./import.ps1 "C:\Users\YourName\obsidian\MyVault"
```

The import script will:
- Back up your existing `.obsidian/` folder (if any) with a timestamp
- Copy all themes, plugins, snippets, and settings into your vault
- Print a summary of what was imported

### 5. Reopen the vault in Obsidian

Launch Obsidian and open your vault. You'll be prompted to **Trust the author and enable plugins** — click **Trust** to activate the community plugins.

### 6. (Optional) Add the dashboard templates

Copy the `Dashboards/` folder into your vault to get pre-built data visualizations:

**macOS / Linux:**
```bash
cp -r Dashboards/ ~/obsidian/MyVault/Dashboards/
```

**Windows (PowerShell):**
```powershell
Copy-Item -Path Dashboards -Destination "C:\Users\YourName\obsidian\MyVault\Dashboards" -Recurse
```

See the [Dashboard Templates](#dashboard-templates) section below for details on each dashboard.

---

## What gets synced

| Item | Path inside `.obsidian/` |
|---|---|
| App settings | `app.json` |
| Appearance (theme, font, etc.) | `appearance.json` |
| Core plugin toggles | `core-plugins.json`, `core-plugins-migration.json` |
| Community plugin list | `community-plugins.json` |
| Community plugins + configs | `plugins/*/` |
| Themes | `themes/*/` |
| CSS snippets | `snippets/*.css` |
| Hotkeys | `hotkeys.json` |
| Templates, graph, etc. | various `.json` files |

**Excluded** (machine-specific): `workspace.json`, `workspace-mobile.json`

## Usage

### Export from a vault

```bash
./export.sh ~/path/to/your/vault
```

This copies the `.obsidian` config into `obsidian-config/` in this repo. Commit and push to save.

### Import into a vault

```bash
./import.sh ~/path/to/target/vault
```

This copies the saved config into the vault's `.obsidian/` folder. If one already exists, it's backed up first with a timestamp. Restart Obsidian after importing.

### Typical workflow

```bash
# First time: export your current setup
./export.sh ~/obsidian/MyVault
git add -A && git commit -m "initial obsidian env export"
git push

# On a new machine: clone and import
git clone <this-repo>
./import.sh ~/obsidian/MyVault

# After changing plugins/themes: re-export and commit
./export.sh ~/obsidian/MyVault
git add -A && git commit -m "update plugins"
git push
```

## Dashboard Templates

The `Dashboards/` folder contains ready-to-use Obsidian notes with rich data visualizations powered by the **Dataview** and **Meta Bind** plugins (both included in this config).

| Dashboard | Description |
|---|---|
| **Command Center** | Pipeline health, milestone timelines, KPI cards, and action items |
| **Customer Scorecard** | Per-customer metrics with a calendar range picker and engagement stats |
| **Day View** | Daily agenda — meetings, tasks, and follow-ups for a selected date |
| **People Directory** | Searchable directory of internal, customer, and partner contacts |

The dashboards query folders like `People/`, `Customers/`, `Opportunities/`, and `Meetings/` in your vault. Create those folders and populate them with notes for the visualizations to display data.

## MCAPS-IQ Agent

The dashboards and Sidekick plugin are designed to work with [**MCAPS-IQ**](https://github.com/microsoft/MCAPS-IQ) — a GitHub Copilot agent that syncs CRM/MSX data into your vault and powers the dashboard visualizations.

To set it up:

1. Follow the [MCAPS-IQ repo](https://github.com/microsoft/MCAPS-IQ) instructions to install the **@mcaps-iq** agent in GitHub Copilot Chat.
2. Configure the **Sidekick** plugin (included in this config) with the agent prompts from the MCAPS-IQ repo to enable vault sync commands.
3. Use `@mcaps-iq` in GitHub Copilot Chat or the Sidekick sync command in Obsidian to pull latest data from MSX/CRM into your vault.

Once synced, the dashboards will automatically render your pipeline, customer, and people data.

## Notes

- Close Obsidian before importing to avoid conflicts.
- Plugin JS code is included so imports work offline — no need to re-download from the community registry.
- The import script automatically backs up any existing `.obsidian` folder before overwriting.
