#!/bin/bash
# Install workflow orchestrator skills into Claude Code
# Usage: bash install.sh

set -e

SKILLS_DIR="$HOME/.claude/skills"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing workflow orchestrator skills..."
echo ""
echo "NOTE: this installs an archived design (April 2026 snapshot) as-is."
echo "      Existing same-name skills in $SKILLS_DIR will be OVERWRITTEN."
echo ""

# Multi-Role Review
mkdir -p "$SKILLS_DIR/multi-role-review"
cp "$SRC_DIR/skills/multi-role-review/SKILL.md" "$SKILLS_DIR/multi-role-review/SKILL.md"
echo "  [ok] multi-role-review"

# Ideation Map
mkdir -p "$SKILLS_DIR/ideation-map"
cp "$SRC_DIR/skills/ideation-map/SKILL.md" "$SKILLS_DIR/ideation-map/SKILL.md"
echo "  [ok] ideation-map"

# Plan Rework
mkdir -p "$SKILLS_DIR/plan-rework"
cp "$SRC_DIR/skills/plan-rework/SKILL.md" "$SKILLS_DIR/plan-rework/SKILL.md"
echo "  [ok] plan-rework"

# Workflow Orchestrator
mkdir -p "$SKILLS_DIR/workflow-orchestrator"
cp "$SRC_DIR/skills/workflow-orchestrator/SKILL.md" "$SKILLS_DIR/workflow-orchestrator/SKILL.md"
echo "  [ok] workflow-orchestrator"

echo ""
echo "Done. 4 skills installed to $SKILLS_DIR/"
echo ""
echo "  - multi-role-review      4-role parallel plan review"
echo "  - plan-rework            Review-driven plan revision"
echo "  - ideation-map           Cross-domain possibility mapping"
echo "  - workflow-orchestrator   Natural language pipeline routing"
echo ""
echo "Note: The pipeline also depends on the following external skills:"
echo "  - superpowers:brainstorming"
echo "  - superpowers:writing-plans"
echo "  - superpowers:subagent-driven-development"
echo "  - superpowers:requesting-code-review"
echo "  - superpowers:finishing-a-development-branch"
echo "  If missing, the orchestrator will gracefully fallback to manual mode."
echo ""
echo "Restart Claude Code to activate."
