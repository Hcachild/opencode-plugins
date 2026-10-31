# install.ps1 — Install opencode-plugins to ~/.config/opencode/plugins/
# Usage:
#   .\install.ps1                    # install all plugins (symlink)
#   .\install.ps1 -Copy              # install all plugins (copy)
#   .\install.ps1 -Project           # install to .opencode\plugins\ (project-local)
#   .\install.ps1 -List              # list available plugins
#   .\install.ps1 -Plugin bash-timeout   # install a single plugin

param(
    [switch]$Copy,
    [switch]$Project,
    [switch]$List,
    [string]$Plugin,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PluginsDir = Join-Path $ScriptDir "plugins"

if ($Help) {
    Write-Host "Usage: .\install.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Copy          Copy files instead of symlinking"
    Write-Host "  -Project       Install to .opencode\plugins\ (project-local)"
    Write-Host "  -List          List available plugins"
    Write-Host "  -Plugin NAME   Install a single plugin"
    Write-Host "  -Help          Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\install.ps1                        # Install all plugins globally (symlink)"
    Write-Host "  .\install.ps1 -Copy                  # Install all plugins globally (copy)"
    Write-Host "  .\install.ps1 -Project               # Install to current project"
    Write-Host "  .\install.ps1 -Plugin bash-timeout   # Install only 'bash-timeout'"
    exit 0
}

if ($List) {
    Write-Host "Available plugins:"
    Get-ChildItem $PluginsDir -File -Filter *.js |
        Select-Object -ExpandProperty BaseName | Sort-Object
    exit 0
}

# Determine destination
if ($Project) {
    $Dest = ".opencode\plugins"
} else {
    $Dest = Join-Path $env:USERPROFILE ".config\opencode\plugins"
}

if (!(Test-Path $Dest)) {
    New-Item -ItemType Directory -Path $Dest -Force | Out-Null
}

# Gather plugins to install
if ($Plugin) {
    $src = Join-Path $PluginsDir "$Plugin.js"
    if (!(Test-Path $src)) {
        Write-Host "Error: Plugin '$Plugin' not found in $PluginsDir" -ForegroundColor Red
        Write-Host "Run '.\install.ps1 -List' to see available plugins."
        exit 1
    }
    $PluginsToInstall = @($Plugin)
} else {
    $PluginsToInstall = Get-ChildItem $PluginsDir -File -Filter *.js |
        Select-Object -ExpandProperty BaseName | Sort-Object
}

$mode = if ($Copy) { "copy" } else { "symlink" }
Write-Host "Installing $($PluginsToInstall.Count) plugin(s) to $Dest (mode: $mode)"
Write-Host ""

$installed = 0
$skipped = 0

foreach ($name in $PluginsToInstall) {
    $src = Join-Path $PluginsDir "$name.js"
    $dst = Join-Path $Dest "$name.js"

    if (Test-Path $dst) {
        if ($Copy) {
            Remove-Item $dst -Force
        } else {
            Write-Host "  SKIP  $name.js (already exists)"
            $skipped++
            continue
        }
    }

    if ($Copy) {
        Copy-Item $src $dst -Force
        Write-Host "  COPY  $name.js"
    } else {
        # On Windows, symlinks require admin or Developer Mode
        try {
            New-Item -ItemType SymbolicLink -Path $dst -Target $src -ErrorAction Stop | Out-Null
            Write-Host "  LINK  $name.js"
        } catch {
            # Fallback to copy if symlink fails
            Copy-Item $src $dst -Force
            Write-Host "  COPY  $name.js (symlink failed, copied instead)"
        }
    }
    $installed++
}

Write-Host ""
Write-Host "Done: $installed installed, $skipped skipped."
Write-Host ""
Write-Host "Restart OpenCode for plugins to take effect."
