#!/bin/bash
set -e

# Salvo — sub-agent swarm for OpenCode
# Usage:
#   salvo init           — install agents into current project
#   salvo init /path     — install agents into target project
#   salvo install        — put 'salvo' command on your PATH

SELF="$0"
[ -L "$SELF" ] && SELF="$(readlink -f "$SELF")"
SCRIPT_DIR="$(cd "$(dirname "$SELF")" && pwd)"
AGENTS_SRC="$SCRIPT_DIR/agents"
CMD="${1:-init}"

case "$CMD" in
  install)
    DEST="${HOME}/.local/bin"
    mkdir -p "$DEST"
    ln -sf "$SCRIPT_DIR/setup.sh" "$DEST/oc-salvo"
    echo "Installed: oc-salvo → $DEST/oc-salvo"
    echo "Run 'oc-salvo init' in any project directory."
    ;;

  init)
    TARGET="${2:-.}"
    DEST="$TARGET/.opencode/agent"

    if [ ! -d "$AGENTS_SRC" ]; then
      echo "Error: agents/ directory not found at $SCRIPT_DIR"
      exit 1
    fi

    mkdir -p "$DEST"

    count=0
    for f in "$AGENTS_SRC"/*.md; do
      cp "$f" "$DEST/"
      count=$((count + 1))
      echo "  + $(basename "$f")"
    done

    echo ""
    echo "Salvo: $count agents installed → $DEST"
    echo ""
    echo "Run 'opencode' — orchestrator is your default agent."
    echo "Type @ to see sub-agents."
    ;;

  *)
    echo "Salvo — sub-agent swarm for OpenCode"
    echo ""
    echo "Usage:"
    echo "  salvo init [dir]   Install agents into a project (default: current dir)"
    echo "  salvo install      Add 'salvo' command to your PATH"
    echo ""
    echo "https://github.com/nicdavidson/salvo"
    ;;
esac
