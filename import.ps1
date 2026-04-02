#Requires -Version 5.1
<#
.SYNOPSIS
    Import Obsidian environment from this repo into a vault.
.EXAMPLE
    ./import.ps1 "C:\Users\Jin\Documents\MyVault"
#>
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$VaultPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BackupDir = Join-Path $ScriptDir 'obsidian-config'

if (-not (Test-Path $VaultPath -PathType Container)) {
    Write-Error "Vault directory does not exist: $VaultPath"
}

if (-not (Test-Path $BackupDir -PathType Container)) {
    Write-Error "No exported config found at $BackupDir`nRun ./export.ps1 first to export a config."
}

$ObsidianDir = Join-Path $VaultPath '.obsidian'

# If .obsidian already exists, back it up
if (Test-Path $ObsidianDir -PathType Container) {
    $Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $BackupPath = Join-Path $VaultPath ".obsidian-backup-$Timestamp"
    Write-Host "Existing .obsidian found. Backing up to: $BackupPath" -ForegroundColor Yellow
    Copy-Item $ObsidianDir -Destination $BackupPath -Recurse -Force
    Remove-Item $ObsidianDir -Recurse -Force
}

New-Item -Path $ObsidianDir -ItemType Directory -Force | Out-Null

Write-Host "Importing Obsidian config into: $VaultPath"

# Copy all exported items into .obsidian
Get-ChildItem -Path $BackupDir -Force | ForEach-Object {
    if ($_.PSIsContainer) {
        Copy-Item $_.FullName -Destination (Join-Path $ObsidianDir $_.Name) -Recurse -Force
    } else {
        Copy-Item $_.FullName -Destination $ObsidianDir -Force
    }
}

# Summary
$jsonCount    = @(Get-ChildItem -Path $ObsidianDir -Filter '*.json' -File -ErrorAction SilentlyContinue).Count
$pluginDir    = Join-Path $ObsidianDir 'plugins'
$pluginCount  = if (Test-Path $pluginDir) { @(Get-ChildItem -Path $pluginDir -Directory -ErrorAction SilentlyContinue).Count } else { 0 }
$themeDir     = Join-Path $ObsidianDir 'themes'
$themeCount   = if (Test-Path $themeDir) { @(Get-ChildItem -Path $themeDir -Directory -ErrorAction SilentlyContinue).Count } else { 0 }
$snippetDir   = Join-Path $ObsidianDir 'snippets'
$snippetCount = if (Test-Path $snippetDir) { @(Get-ChildItem -Path $snippetDir -Filter '*.css' -File -ErrorAction SilentlyContinue).Count } else { 0 }

Write-Host ""
Write-Host "Imported successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Imported contents:"
Write-Host "  Config files:  $jsonCount JSON files"
Write-Host "  Plugins:       $pluginCount plugins"
Write-Host "  Themes:        $themeCount themes"
Write-Host "  Snippets:      $snippetCount CSS snippets"
Write-Host ""
Write-Host "Restart Obsidian (or reopen the vault) to apply changes."
