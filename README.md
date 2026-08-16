# Workflow Orchestrator

**Natural language pipeline orchestration for Claude Code.**

> [!IMPORTANT]
> **This repo is a record of workflow *design thinking* -- and how it evolved.** The ideas are the through-line: natural-language pipeline routing, four-role parallel plan review, cross-domain ideation mapping. It tracks them from their first implementation (April 2026) to the lighter forms still in service today -- see the [Design Evolution Log](#design-evolution-log) for where each idea lives now.
>
> **How to read the skills.** They're a snapshot of that April 2026 implementation, since retired from the author's own setup as the ideas moved on. Two honest caveats on the original design: the headline -- "speak naturally, AI routes every message" -- needed a prompt-interception hook layer that was planned (`docs/research.md`, P2) but never shipped. What ships here are plain skills that Claude Code loads by semantically matching their descriptions, which is probabilistic -- not guaranteed message-level routing. The old aspirational `trigger:` regexes were removed because Claude Code did not consume them.
>
> `install.sh` still works. It installs the maintained April 2026 design snapshot and asks before replacing same-name skills in `~/.claude/skills/`; unattended installs must pass `--force`. The SKILL.md files remain useful as design references for handoff, review, and orchestration patterns.

Speak naturally. The AI detects your intent and routes you through the right pipeline stage -- from early ideation all the way to shipping and knowledge capture. No slash commands to memorize, no manual stage management.

## Design Evolution Log

The workflow design is the through-line of this repo; skill implementations are snapshots. This log tracks how the ideas have moved.

| When | What happened |
|------|---------------|
| 2026-04 | v1 shipped: natural-language pipeline routing, 4-role parallel plan review, cross-domain ideation map. v2.0 added stage handoff contracts, capability detection, and quality gates. |
| 2026-05 | The skills were retired from the author's own setup. The ideas moved on in lighter forms: **stage handoff contract** → a personal pipeline protocol used across projects; **multi-role review** → a triangle of one human plus two mutually-checking AI agents (Claude Code + Codex), with [agent-room-cli](https://github.com/AliceLJY/agent-room-cli) as runtime; **ideation map** → an on-demand template. |
| 2026-06 | README realigned with reality after a "clinical significance" audit -- judging the project by whether it actually works for its audience, not by whether the code is well-formed. Future workflow shifts will be appended here. |
| 2026-07 | The archived contracts were repaired: review and rework now stop at an explicit user-decision state, round counters cap rework, concerns are distinct from external blockers, and installation no longer overwrites silently. |
| 2026-08 | Multi-role review widened again — from one human plus two mutually-checking agents to a four-way panel (Claude Code, Codex, Kimi, Antigravity). Two things changed beyond the headcount: roles stopped being tied to a tool (whichever agent is currently in conversation acts as owner, the rest review), and the owner lost the right to pick the lineup — everyone reviews, the owner only adjudicates. Reviewers read cold and stay isolated from each other's findings, so the runtime moved from a shared room to separate headless calls. Rounds are capped, and unresolved disagreement is reported as disagreement rather than averaged away. |

## How It Works

```
You say: "I have an idea for a caching layer"

                    +-------------------+
                    |  You speak naturally |
                    +---------+---------+
                              |
                              v
                    +---------+---------+
                    | Intent Detection   |
                    | (orchestrator)     |
                    +---------+---------+
                              |
          +-------------------+-------------------+
          |           |           |           |
          v           v           v           v
     +---------+ +---------+ +---------+ +---------+
     | Ideate  | | Plan    | | Review  | | Execute |
     | (map)   | | (spec)  | | (4-role)| | (code)  |
     +---------+ +---------+ +---------+ +---------+
          |           |           |           |
          +-------------------+-------------------+
                              |
                              v
                    +---------+---------+
                    |   Ship + Compound  |
                    +-------------------+
```

### The Pipeline

| Stage | What Happens | Trigger |
|-------|-------------|---------|
| **Ideate** | Scan possibility space across domains, output a map of directions | "I want to build..." / "I have an idea" |
| **Plan** | Turn spec into implementation steps | "Let's plan this out" |
| **Review** | 4 parallel sub-agents challenge the plan from different angles | Auto after planning |
| **Execute** | Parallel sub-agents implement the plan | User confirms after review |
| **Ship** | Merge, test, release | "Ship it" |
| **Compound** | Capture learnings for future sessions | Auto after shipping |

**Key rule:** Production steps auto-advance. Decision steps wait for you.

### v2.0: Stage Handoff Contracts

Every pipeline stage now emits a structured handoff when it completes:

```yaml
handoff:
  from: writing-plans
  status: ok              # ok | blocked | rework
  artifact: docs/plan.md  # what was produced
  blockers: []            # external issues that prevented this stage from finishing
  concerns: []            # quality issues in a completed artifact
  next: multi-role-review # recommended next stage
  decisions_needed: []    # what needs human judgment
  review_round: 0         # increments for review and lightweight re-review
  rework_attempt: 0       # plan-rework attempts already used
  max_rework_attempts: 1  # workflow cap before returning control to the user
```

This replaces the previous descriptive state tracking with an enforced protocol. No handoff = stage not complete. Combined with RecallNest checkpoints at every handoff (requires the separate [RecallNest](https://github.com/AliceLJY/recallnest) MCP -- not bundled here), pipeline state survives compacts and window switches.

`blocked` means the current stage could not finish because an input, permission, dependency, or external service is unavailable. Review findings belong in `concerns`; `rework` means the review finished but the artifact must change before execution. `await-user-decision` is a waiting state, not another automatically dispatched stage.

## What's Inside

### 1. Workflow Orchestrator (skill: `workflow-orchestrator`)

The routing layer. Parses your natural language, figures out which pipeline stage you're at, and dispatches the right skill. Handles stage transitions, backtracking ("this direction is wrong"), and skip-ahead ("just start coding, I have a plan").

**v2.0 additions:**
- **Stage Handoff Contract** -- every stage must emit a structured handoff before the pipeline advances
- **Capability Detection** -- checks if downstream skills exist before routing; gracefully falls back to manual mode if missing
- **Checkpoint discipline** -- persistent state at every handoff and before every human decision point

### 2. Multi-Role Review (skill: `multi-role-review`)

Four independent sub-agents review your plan in parallel, each from a distinct perspective:

| Role | Focus |
|------|-------|
| **User Advocate** | Does this actually solve the user's problem? Over-engineering? |
| **Architect** | Clean boundaries? Right abstractions? Extensible? |
| **Risk Hunter** | What breaks? Security holes? Dependency risks? |
| **Pragmatist** | Is there a simpler way? YAGNI violations? |

After individual reviews, the system cross-examines for blind spots and extracts core tensions -- the trade-offs that need your judgment. Inspired by the three-perspective cross-examination pattern from the author's content-creation pipeline.

**v2.0 additions:**
- **Strict mode is now default** -- any "Needs rework" verdict blocks execution automatically
- **Quality gate escalation** -- 2+ "Go with concerns" with shared issues also requires explicit user response
- **Shallow review detection** -- all 4 roles saying "Go" with zero concerns triggers a depth warning

### 3. Plan Rework (skill: `plan-rework`) *NEW*

Consumes the review report and revises the plan. Keeps review and revision as separate responsibilities (the reviewer doesn't fix, the fixer doesn't judge).

- Extracts only the must-fix items from the review report
- Modifies the plan with annotated changes
- Runs a lightweight 2-role re-review to verify fixes
- Returns to the user after at most 1 rework attempt; it does not invoke the full review again automatically

### 4. Ideation Map (skill: `ideation-map`)

Broad exploration before a specification. When you have a vague direction but don't know what to investigate, this skill:

1. Scans 3-5 related domains, existing solutions, and adjacent fields
2. Extracts cross-domain patterns that might apply
3. Outputs a structured "possibility map" with connection points
4. Waits for you to make the cross-domain leaps

The premise: AI has knowledge breadth, you have cross-domain intuition. Together you find directions neither would alone.

## Install

> Installs the maintained archive snapshot -- see the status note at the top. Existing same-name skills require confirmation.

```bash
git clone https://github.com/AliceLJY/workflow-orchestrator.git
cd workflow-orchestrator
bash install.sh
```

This copies four skills into `~/.claude/skills/`. Restart Claude Code to activate.

For unattended installation, make overwrite intent explicit:

```bash
bash install.sh --force
```

Use `--skills-dir PATH` to install into a different skill directory.

The pipeline also depends on external skills from `superpowers`. If any are missing, the orchestrator falls back to manual mode -- it never blocks.

## Usage Examples (design intent)

The flow below is the designed experience. In practice, each hop depends on Claude Code choosing to load the orchestrator skill from its description -- see the status note at the top.

```
You:  "I want to build a notification system for my app"
  --> Orchestrator routes to Ideation Map
  --> You get a possibility map with 4 domains scanned
  --> You pick a direction

You:  "Option B looks right, let's flesh it out"
  --> Routes to brainstorming, then planning
  --> Plan is written

      (auto-triggers Multi-Role Review)
  --> 4 reviewers run in parallel
  --> You get: "Plan looks good, 2 points need your call"

You:  "Go ahead"
  --> Routes to execution
  --> Sub-agents implement in parallel

You:  "Ship it"
  --> Merge, test, release
  --> Learnings captured automatically
```

## Before vs After (the goal)

**Before (manual skill management):**
```
> /brainstorm notification system       # need to know the command
> /write-plan                           # need to remember the sequence
> /multi-role-review                    # need to know this exists
> /execute-plan                         # need to trigger manually
> /code-review                          # easy to forget
> /finish                               # hope you remembered
```

**After (natural language orchestration):**
```
> I want to build a notification system
  ... (everything flows naturally from conversation) ...
> Ship it
```

## Design Principles

- **Zero command vocabulary** (design goal) -- users never learn slash commands; full enforcement needs the hook layer that was never shipped
- **Context isolation** -- sub-agents get precisely scoped context, not your full conversation history
- **Human-in-the-loop** -- AI advances production steps automatically, but waits at every decision point
- **Graceful degradation** -- if a skill is missing, falls back to manual mode instead of blocking
- **Resumable** -- switch windows mid-pipeline, come back later, pick up where you left off (via the external RecallNest MCP)

## Project Structure

```
skills/
  workflow-orchestrator/SKILL.md # Intent detection + pipeline routing
  multi-role-review/SKILL.md    # 4-role parallel plan review
  plan-rework/SKILL.md          # Review-driven plan revision
  ideation-map/SKILL.md         # Cross-domain possibility mapping
install.sh                       # One-command installer
docs/
  research.md                    # Design research notes
  plan.md                        # Implementation plan
```

## Part of the AliceLJY Claude Code Ecosystem

This project sits alongside:

- [RecallNest](https://github.com/AliceLJY/recallnest) -- Long-term memory for Claude Code via LanceDB; provides the checkpoint/resume capability the pipeline design relies on
- [agent-room-cli](https://github.com/AliceLJY/agent-room-cli) -- the tmux room where the successor workflow (one human + two mutually-checking AI agents) runs today

The multi-role review pattern here was directly inspired by the three-perspective cross-examination in the author's content-creation pipeline.

## License

[MIT](LICENSE)
