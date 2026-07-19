#!/usr/bin/env bash
# Install workflow orchestrator skills into Claude Code.
# Usage: bash install.sh [--force] [--skills-dir PATH]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills"
FORCE=0
SKILL_NAMES=(multi-role-review ideation-map plan-rework workflow-orchestrator)

usage() {
  printf '%s\n' "Usage: bash install.sh [--force] [--skills-dir PATH]"
  printf '%s\n' "  --force             Replace existing same-name skills without prompting."
  printf '%s\n' "  --skills-dir PATH   Install into PATH instead of ~/.claude/skills."
}

while (($# > 0)); do
  case "$1" in
    --force)
      FORCE=1
      shift
      ;;
    --skills-dir)
      if (($# < 2)) || [[ -z "$2" ]]; then
        printf '%s\n' "error: --skills-dir requires a non-empty path" >&2
        exit 2
      fi
      SKILLS_DIR="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

for skill_name in "${SKILL_NAMES[@]}"; do
  source_file="$SCRIPT_DIR/skills/$skill_name/SKILL.md"
  if [[ ! -f "$source_file" ]]; then
    printf 'error: missing source skill: %s\n' "$source_file" >&2
    exit 1
  fi
done

existing=()
for skill_name in "${SKILL_NAMES[@]}"; do
  if [[ -e "$SKILLS_DIR/$skill_name/SKILL.md" ]]; then
    existing+=("$skill_name")
  fi
done

if ((${#existing[@]} > 0 && FORCE == 0)); then
  printf 'Existing skills would be replaced in %s:\n' "$SKILLS_DIR" >&2
  printf '  - %s\n' "${existing[@]}" >&2

  if [[ ! -t 0 ]]; then
    printf '%s\n' "error: refusing to overwrite in a non-interactive session; rerun with --force" >&2
    exit 2
  fi

  printf '%s' "Continue? [y/N] " >&2
  read -r reply
  case "$reply" in
    y|Y|yes|YES|Yes) ;;
    *)
      printf '%s\n' "Installation cancelled."
      exit 2
      ;;
  esac
fi

printf '%s\n' "Installing workflow orchestrator skills..."
printf 'Destination: %s\n\n' "$SKILLS_DIR"

for skill_name in "${SKILL_NAMES[@]}"; do
  destination="$SKILLS_DIR/$skill_name"
  mkdir -p "$destination"
  cp "$SCRIPT_DIR/skills/$skill_name/SKILL.md" "$destination/SKILL.md"
  printf '  [ok] %s\n' "$skill_name"
done

printf '\nDone. %s skills installed to %s/\n' "${#SKILL_NAMES[@]}" "$SKILLS_DIR"
printf '%s\n' "Restart Claude Code to activate."
