# Workflow Orchestrator

**Natural language pipeline orchestration for Claude Code.**

Speak naturally. The AI detects your intent and routes you through the right pipeline stage -- from early ideation all the way to shipping and knowledge capture. No slash commands to memorize, no manual stage management.

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
| **Research** | Deep-dive into selected direction | User picks a direction from the map |
| **Plan** | Turn spec into implementation steps | "Let's plan this out" |
| **Review** | 4 parallel sub-agents challenge the plan from different angles | Auto after planning |
| **Execute** | Parallel sub-agents implement the plan | User confirms after review |
| **Ship** | Merge, test, release | "Ship it" |
| **Compound** | Capture learnings for future sessions | Auto after shipping |

**Key rule:** Production steps auto-advance. Decision steps wait for you.

## What's Inside

### 1. Workflow Orchestrator (`/workflow-orchestrator`)

The routing layer. Parses your natural language, figures out which pipeline stage you're at, and dispatches the right skill. Handles stage transitions, backtracking ("this direction is wrong"), and skip-ahead ("just start coding, I have a plan").

### 2. Multi-Role Review (`/multi-role-review`)

Four independent sub-agents review your plan in parallel, each from a distinct perspective:

| Role | Focus |
|------|-------|
| **User Advocate** | Does this actually solve the user's problem? Over-engineering? |
| **Architect** | Clean boundaries? Right abstractions? Extensible? |
| **Risk Hunter** | What breaks? Security holes? Dependency risks? |
| **Pragmatist** | Is there a simpler way? YAGNI violations? |

After individual reviews, the system cross-examines for blind spots and extracts core tensions -- the trade-offs that need your judgment. Inspired by the three-perspective cross-examination pattern from [content-alchemy](https://github.com/AliceLJY/content-alchemy).

### 3. Ideation Map (`/ideation-map`)

Meta-research before formal research. When you have a vague direction but don't know what to investigate, this skill:

1. Scans 3-5 related domains, existing solutions, and adjacent fields
2. Extracts cross-domain patterns that might apply
3. Outputs a structured "possibility map" with connection points
4. Waits for you to make the cross-domain leaps

The premise: AI has knowledge breadth, you have cross-domain intuition. Together you find directions neither would alone.

## Install

```bash
git clone https://github.com/AliceLJY/workflow-orchestrator.git
cd workflow-orchestrator
bash install.sh
```

This copies the three skills into `~/.claude/skills/`. Restart Claude Code to activate.

## Usage Examples

You don't invoke skills directly. Just talk:

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

## Before vs After

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

- **Zero command vocabulary** -- users never learn slash commands
- **Context isolation** -- sub-agents get precisely scoped context, not your full conversation history
- **Human-in-the-loop** -- AI advances production steps automatically, but waits at every decision point
- **Graceful degradation** -- if a skill is missing, falls back to manual mode instead of blocking
- **Resumable** -- switch windows mid-pipeline, come back later, pick up where you left off

## Project Structure

```
skills/
  multi-role-review/SKILL.md    # 4-role parallel plan review
  ideation-map/SKILL.md         # Cross-domain possibility mapping
  workflow-orchestrator/SKILL.md # Intent detection + pipeline routing
install.sh                       # One-command installer
docs/
  research.md                    # Design research notes
  plan.md                        # Implementation plan
```

## Part of the AliceLJY Claude Code Ecosystem

This project works alongside:

- [RecallNest](https://github.com/AliceLJY/recallnest) -- Long-term memory for Claude Code via LanceDB
- [content-alchemy](https://github.com/AliceLJY/content-alchemy) -- Content creation pipeline with multi-perspective review

The multi-role review pattern in this project was directly inspired by content-alchemy's three-perspective cross-examination. RecallNest provides the checkpoint/resume capability that lets pipelines survive across sessions.

## License

[MIT](LICENSE)
