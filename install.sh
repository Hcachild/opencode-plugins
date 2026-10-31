#!/usr/bin/env bash
# install.sh — Install opencode-plugins to ~/.config/opencode/plugins/
# Usage:
#   ./install.sh                    # install all plugins (symlink)
#   ./install.sh --copy             # install all plugins (copy)
#   ./install.sh --project          # install to .opencode/plugins/ (project-local)
#   ./install.sh --list             # list available plugins
#   ./install.sh <plugin-name>      # install a single plugin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$SCRIPT_DIR/plugins"
MODE="symlink"
SCOPE="global"
TARGET_PLUGIN=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --copy)    MODE="copy"; shift ;;
        --project) SCOPE="project"; shift ;;
        --list)
            echo "Available plugins:"
            find "$PLUGINS_DIR" -maxdepth 1 -mindepth 1 -type f -name '*.js' -exec basename {} .js \; | sort
            exit 0
            ;;
        --help|-h)
            echo "Usage: ./install.sh [OPTIONS] [PLUGIN_NAME]"
            echo ""
            echo "Options:"
            echo "  --copy       Copy files instead of symlinking"
            echo "  --project    Install to .opencode/plugins/ (project-local)"
            echo "  --list       List available plugins"
            echo "  --help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./install.sh                    # Install all plugins globally (symlink)"
            echo "  ./install.sh --copy             # Install all plugins globally (copy)"
            echo "  ./install.sh --project          # Install to current project"
            echo "  ./install.sh bash-timeout       # Install only 'bash-timeout'"
            exit 0
            ;;
        *)         TARGET_PLUGIN="$1"; shift ;;
    esac
done

# Determine destination
if [[ "$SCOPE" == "project" ]]; then
    DEST=".opencode/plugins"
else
    DEST="$HOME/.config/opencode/plugins"
fi

mkdir -p "$DEST"

# Gather plugins to install
if [[ -n "$TARGET_PLUGIN" ]]; then
    if [[ ! -f "$PLUGINS_DIR/$TARGET_PLUGIN.js" ]]; then
        echo "Error: Plugin '$TARGET_PLUGIN' not found in $PLUGINS_DIR"
        echo "Run './install.sh --list' to see available plugins."
        exit 1
    fi
    PLUGINS=("$TARGET_PLUGIN")
else
    mapfile -t PLUGINS < <(find "$PLUGINS_DIR" -maxdepth 1 -mindepth 1 -type f -name '*.js' -exec basename {} .js \; | sort)
fi

echo "Installing ${#PLUGINS[@]} plugin(s) to $DEST (mode: $MODE)"
echo ""

installed=0
skipped=0
for plugin in "${PLUGINS[@]}"; do
    src="$PLUGINS_DIR/$plugin.js"
    dst="$DEST/$plugin.js"

    if [[ -e "$dst" || -L "$dst" ]]; then
        if [[ "$MODE" == "copy" ]]; then
            rm -f "$dst"
        else
            echo "  SKIP  $plugin.js (already exists at $dst)"
            ((skipped++))
            continue
        fi
    fi

    if [[ "$MODE" == "symlink" ]]; then
        ln -s "$src" "$dst"
        echo "  LINK  $plugin.js -> $dst"
    else
        cp "$src" "$dst"
        echo "  COPY  $plugin.js -> $dst"
    fi
    ((installed++))
done

echo ""
echo "Done: $installed installed, $skipped skipped."
echo ""
echo "Restart OpenCode for plugins to take effect."
