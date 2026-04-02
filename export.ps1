#Requires -Version 5.1
<#
.SYNOPSIS
    Export Obsidian environment from a vault to this repo.
.EXAMPLE
    ./export.ps1 "C:\Users\Jin\Documents\MyVault"
#>
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$VaultPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BackupDir = Join-Path $ScriptDir 'obsidian-config'
$ObsidianDir = Join-Path $VaultPath '.obsidian'

if (-not (Test-Path $ObsidianDir -PathType Container)) {
    Write-Error "No .obsidian folder found at $ObsidianDir`nMake sure the path points to an Obsidian vault."
}

Write-Host "Exporting Obsidian config from: $VaultPath"

# Clean previous export
if (Test-Path $BackupDir) {
    Remove-Item $BackupDir -Recurse -Force
}
New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null

# Files/folders to skip (machine-specific)
$Excludes = @(
    'workspace.json'
    'workspace-mobile.json'
    '.obsidian-git-data'
    '.trash'
    'cache'
    '.DS_Store'
)

# Binary file extensions to exclude (bloat the repo, not useful in version control)
$BinaryExtensions = @(
    '.wasm','.node','.dylib','.so','.dll','.exe',
    '.png','.jpg','.jpeg','.gif','.ico','.bmp','.webp',
    '.ttf','.woff','.woff2','.eot','.otf',
    '.zip','.tar','.gz','.7z','.rar',
    '.pdf','.mp3','.mp4','.wav','.ogg'
)

# Copy everything except excluded items
Get-ChildItem -Path $ObsidianDir -Force | Where-Object {
    $Excludes -notcontains $_.Name
} | ForEach-Object {
    if ($_.PSIsContainer) {
        Copy-Item $_.FullName -Destination (Join-Path $BackupDir $_.Name) -Recurse -Force
    } else {
        Copy-Item $_.FullName -Destination $BackupDir -Force
    }
}

# Remove binary files from the export
$binaryCount = 0
Get-ChildItem -Path $BackupDir -Recurse -File | Where-Object {
    $BinaryExtensions -contains $_.Extension.ToLower()
} | ForEach-Object {
    Remove-Item $_.FullName -Force
    $binaryCount++
}
if ($binaryCount -gt 0) {
    Write-Host "Removed $binaryCount binary files"
}

# Remove any remaining binary files detected by content (catches extensionless binaries)
$binCount = 0
Get-ChildItem -Path $BackupDir -Recurse -File | ForEach-Object {
    $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
    if ($bytes.Length -gt 0 -and ($bytes -contains 0)) {
        Remove-Item $_.FullName -Force
        $binCount++
    }
}
if ($binCount -gt 0) {
    Write-Host "Removed $binCount binary files (detected by content)"
}

# Remove all plugin data.json files — these contain vault-specific state,
# cached file paths, tokens, and other data that shouldn't be committed.
# Plugin settings will reset to defaults on import.
$pluginsDir = Join-Path $BackupDir 'plugins'
$dataFiles = Get-ChildItem -Path $pluginsDir -Filter 'data.json' -Recurse -ErrorAction SilentlyContinue
$dataCount = ($dataFiles | Measure-Object).Count
$dataFiles | Remove-Item -Force
# Also remove cursor-positions and other known state files
Get-ChildItem -Path $pluginsDir -Filter 'cursor-positions.json' -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force
Write-Host "Removed $dataCount plugin data.json files (vault-specific state)"

# Summary
$jsonCount   = (Get-ChildItem -Path $BackupDir -Filter '*.json' -File -ErrorAction SilentlyContinue).Count
$pluginDir   = Join-Path $BackupDir 'plugins'
$pluginCount = if (Test-Path $pluginDir) { (Get-ChildItem -Path $pluginDir -Directory -ErrorAction SilentlyContinue).Count } else { 0 }
$themeDir    = Join-Path $BackupDir 'themes'
$themeCount  = if (Test-Path $themeDir) { (Get-ChildItem -Path $themeDir -Directory -ErrorAction SilentlyContinue).Count } else { 0 }
$snippetDir  = Join-Path $BackupDir 'snippets'
$snippetCount = if (Test-Path $snippetDir) { (Get-ChildItem -Path $snippetDir -Filter '*.css' -File -ErrorAction SilentlyContinue).Count } else { 0 }

Write-Host ""
Write-Host "Exported to: $BackupDir" -ForegroundColor Green
Write-Host ""
Write-Host "Exported contents:"
Write-Host "  Config files:  $jsonCount JSON files"
Write-Host "  Plugins:       $pluginCount plugins"
Write-Host "  Themes:        $themeCount themes"
Write-Host "  Snippets:      $snippetCount CSS snippets"
Write-Host ""
Write-Host "Now commit and push to save your environment."
