# Workflow Orchestrator Implementation Plan

> **历史快照（2026-04）**：本文档是初版实施计划的存档，checkbox 状态停留在开发早期，与最终发布的 v2.0 不一一对应。保留原貌作为设计过程记录。research.md 中规划的 P2（意图识别 hook）最终未实现——这也是 README 状态说明里"核心承诺未完整兑现"的原因。

## P0: Multi-Role Plan Review Skill

**Goal:** Plan 写完后，自动用 4 个不同视角的子 agent 并行审查，汇总后给用户一份精炼结论。

### Task 1: 创建 multi-role-review skill
- [x] 创建 `~/.claude/skills/multi-role-review/SKILL.md`
- [ ] 4 个审查角色：用户视角、架构视角、风险视角、务实视角
- [ ] 复用 content-alchemy 的"三方质询"交叉盲区发现模式
- [ ] 复用 dispatching-parallel-agents 的并行子 agent 模式
- [ ] 输出结构化审查报告 + 核心张力（跨角色最大分歧）

### Task 2: 创建 ideation-map skill
- [ ] 创建 `~/.claude/skills/ideation-map/SKILL.md`
- [ ] 输出可能性地图文件（ideation-map.md）
- [ ] 为用户的"跨域结构映射"能力设计接口

### Task 3: 创建编排层 skill
- [ ] 创建 `~/.claude/skills/workflow-orchestrator/SKILL.md`
- [ ] 意图识别逻辑
- [ ] 阶段路由：ideate → research → plan → review → run → ship → compound
- [ ] 与 RecallNest 集成记录流水线进度
