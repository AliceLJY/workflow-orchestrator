#!/bin/bash
# Install workflow orchestrator skills into Claude Code
# Usage: bash install.sh

set -e

SKILLS_DIR="$HOME/.claude/skills"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing workflow orchestrator skills..."
echo ""

# Multi-Role Review
mkdir -p "$SKILLS_DIR/multi-role-review"
cp "$SRC_DIR/skills/multi-role-review/SKILL.md" "$SKILLS_DIR/multi-role-review/SKILL.md"
echo "  [ok] multi-role-review"

# Ideation Map
mkdir -p "$SKILLS_DIR/ideation-map"
cp "$SRC_DIR/skills/ideation-map/SKILL.md" "$SKILLS_DIR/ideation-map/SKILL.md"
echo "  [ok] ideation-map"

# Workflow Orchestrator
mkdir -p "$SKILLS_DIR/workflow-orchestrator"
cp "$SRC_DIR/skills/workflow-orchestrator/SKILL.md" "$SKILLS_DIR/workflow-orchestrator/SKILL.md"
echo "  [ok] workflow-orchestrator"

echo ""
echo "Done. 3 skills installed to $SKILLS_DIR/"
echo ""
echo "  - multi-role-review      4-role parallel plan review"
echo "  - ideation-map           Cross-domain possibility mapping"
echo "  - workflow-orchestrator   Natural language pipeline routing"
echo ""
echo "Restart Claude Code to activate."
