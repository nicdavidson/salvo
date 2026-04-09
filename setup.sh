#!/bin/bash
set -e

# OpenCode Swarm — agent installer
# Usage: ./setup.sh [target-project-dir]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_SRC="$SCRIPT_DIR/agents"
TARGET="${1:-.}"
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
echo "Installed $count agents → $DEST"
echo ""
echo "Usage:"
echo "  cd $TARGET && opencode"
echo "  - Orchestrator is your default agent (mode: primary)"
echo "  - Type @ to see sub-agents: code-writer, test-writer, etc."
echo "  - Give it a spec or task and let it build."
echo ""
echo "To set a model, add 'model: provider/model-name' to agent frontmatter."
