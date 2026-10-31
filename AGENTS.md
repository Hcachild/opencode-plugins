# AGENTS.md — Project rules for opencode-plugins

## Project Overview

This repository contains a collection of opencode plugins. Each plugin lives in `plugins/<name>.js` and is a single JavaScript file with no npm dependencies.

## Conventions

- All plugins are in the `plugins/` directory (flat structure)
- Each plugin exports a named `async` function that returns OpenCode plugin hooks
- Keep plugins dependency-free; use the OpenCode plugin API only
- Never commit secrets, API keys, or tokens
- Shell scripts (`.sh`) require `#!/usr/bin/env bash` shebang and `set -euo pipefail`

## Key Files

- `install.sh` / `install.ps1` — Installation scripts
- `plugins/` — All plugin files
- `version.json` — Version metadata

## Do Not

- Do not commit `node_modules/`, cache directories, or editor state
- Do not add runtime configuration that belongs in `opencode.json`
