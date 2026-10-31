# opencode-plugins

Personal collection of opencode plugins.

## Plugins

| Plugin | Description |
|--------|-------------|
| [bash-timeout](plugins/bash-timeout.js) | Defaults bash tool calls to a 60-second timeout when the model does not specify one. Explicit values from the model are preserved, so longer commands can still opt in to more time. |
| [utf8-windows](plugins/utf8-windows.js) | On Windows, prefixes bash commands with UTF-8 console settings and sets `PYTHONIOENCODING=utf-8` so non-ASCII output does not turn into mojibake. |

## Quick Start

```bash
# Clone
git clone https://github.com/Hcachild/opencode-plugins.git
cd opencode-plugins

# Install (symlink to ~/.config/opencode/plugins/)
./install.sh

# Or on Windows
.\install.ps1
```

Restart OpenCode — plugins load automatically.

## Installation

### macOS / Linux

```bash
./install.sh                # symlink all plugins globally
./install.sh --copy         # copy all plugins globally
./install.sh --project      # install to .opencode/plugins/ (project-local)
./install.sh --list         # list available plugins
./install.sh bash-timeout   # install a single plugin
```

### Windows (PowerShell)

```powershell
.\install.ps1                 # symlink all plugins globally
.\install.ps1 -Copy           # copy all plugins globally
.\install.ps1 -Project        # install to .opencode\plugins\ (project-local)
.\install.ps1 -List           # list available plugins
.\install.ps1 -Plugin bash-timeout   # install a single plugin
```

### Manual

Copy `plugins/*.js` into `~/.config/opencode/plugins/` (global) or
`.opencode/plugins/` (project-local), then restart OpenCode.

## Repository Structure

```
opencode-plugins/
├── plugins/             # Plugin files (.js)
├── install.sh           # macOS/Linux installer
├── install.ps1          # Windows installer
├── AGENTS.md            # Project rules
├── LICENSE              # MIT
├── version.json         # Version metadata
└── README.md            # This file
```

## Notes

- Plugins are plain `.js` files with no npm dependencies.
- Config is loaded once at startup; restart OpenCode after installing or updating a plugin.
- Never put API keys or tokens in plugin files.
