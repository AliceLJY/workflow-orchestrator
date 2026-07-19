#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/workflow-orchestrator-test.XXXXXX")"

cleanup() {
  case "$TEST_DIR" in
    "${TMPDIR:-/tmp}"/workflow-orchestrator-test.*) rm -rf "$TEST_DIR" ;;
    *) printf 'warning: refusing to remove unexpected test path: %s\n' "$TEST_DIR" >&2 ;;
  esac
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

skill_files=(
  "$REPO_DIR/skills/workflow-orchestrator/SKILL.md"
  "$REPO_DIR/skills/plan-rework/SKILL.md"
  "$REPO_DIR/skills/multi-role-review/SKILL.md"
  "$REPO_DIR/skills/ideation-map/SKILL.md"
)

for skill_file in "${skill_files[@]}"; do
  grep -q '^name:' "$skill_file" || fail "$skill_file has no name"
  grep -q '^description:' "$skill_file" || fail "$skill_file has no description"
  if grep -q '^allowed-tools:' "$skill_file"; then
    fail "$skill_file contains the unsupported allowed-tools: All declaration"
  fi
  if grep -qE '^(trigger|measurable_outcome):' "$skill_file"; then
    fail "$skill_file contains frontmatter fields that Claude Code does not consume"
  fi
done

orchestrator="$REPO_DIR/skills/workflow-orchestrator/SKILL.md"
review="$REPO_DIR/skills/multi-role-review/SKILL.md"
rework="$REPO_DIR/skills/plan-rework/SKILL.md"
ideation="$REPO_DIR/skills/ideation-map/SKILL.md"

for field in concerns review_round rework_attempt max_rework_attempts; do
  grep -q "${field}:" "$orchestrator" || fail "handoff contract is missing $field"
  grep -q "${field}:" "$review" || fail "review handoff is missing $field"
  grep -q "${field}:" "$rework" || fail "rework handoff is missing $field"
  grep -q "${field}:" "$ideation" || fail "ideation handoff is missing $field"
done

grep -q 'next: await-user-decision' "$review" || fail "review does not pause for a user decision"
grep -q 'next: await-user-decision' "$rework" || fail "rework does not pause for a user decision"

if grep -q 'next: execution | plan-rework' "$review"; then
  fail "review still points directly into the old review/rework cycle"
fi
if grep -q 'next: multi-role-review | execution' "$rework"; then
  fail "rework still points directly into the old review/rework cycle"
fi

if grep -q '| \*\*Research\*\* |' "$REPO_DIR/README.md"; then
  fail "English pipeline documents an unimplemented Research stage"
fi
if grep -q '| \*\*研究\*\* |' "$REPO_DIR/README_CN.md"; then
  fail "Chinese pipeline documents an unimplemented Research stage"
fi

install_target="$TEST_DIR/skills"
bash "$REPO_DIR/install.sh" --skills-dir "$install_target" >"$TEST_DIR/install-first.log"

for skill_file in "${skill_files[@]}"; do
  skill_name="$(basename "$(dirname "$skill_file")")"
  cmp "$skill_file" "$install_target/$skill_name/SKILL.md" || fail "$skill_name was not copied exactly"
done

if bash "$REPO_DIR/install.sh" --skills-dir "$install_target" >"$TEST_DIR/install-second.log" 2>&1; then
  fail "installer overwrote existing skills without confirmation or --force"
fi
grep -q 'rerun with --force' "$TEST_DIR/install-second.log" || fail "installer refusal does not explain --force"

bash "$REPO_DIR/install.sh" --force --skills-dir "$install_target" >"$TEST_DIR/install-force.log"
bash "$REPO_DIR/install.sh" --help >"$TEST_DIR/install-help.log"
grep -q -- '--skills-dir PATH' "$TEST_DIR/install-help.log" || fail "installer help omits --skills-dir"

printf '%s\n' "All workflow contract and installer tests passed."
