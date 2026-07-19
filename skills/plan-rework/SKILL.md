---
name: plan-rework
description: |
  Use after a plan review when the user chooses to revise the plan from the report.
  Apply only required changes, run one lightweight verification, then return control.
  审查报告驱动的 Plan 修订。消费 multi-role-review 的输出，
  针对性修改 plan，然后再过一轮精简 review 验证修改。
  独立于 multi-role-review，保持审查和修订的职责分离。
metadata:
  version: "1.1"
  auto-trigger: false
---

# Plan Rework: 审查驱动的 Plan 修订

multi-role-review 说 "Needs rework"？这个 skill 负责**按审查意见修改 plan**，然后再过一轮验证。

**设计原则**：reviewer 不改，fixer 不审。职责分离，防止自己审自己。

## 什么时候触发

- multi-role-review 交接单 `status=rework` 后，用户明确选择修订
- 用户说"按审查意见改一下 plan"
- 编排层判断需要回溯修改时

## 执行流程

```
review-report.md（审查报告）
    ↓
Step 1: 提取必改项（blockers + 高优先级共振问题）
    ↓
Step 2: 逐项修改 plan（只改报告指出的问题，不做额外变更）
    ↓
Step 3: 精简 re-review（2 角色快速验证修改项）
    ↓
Step 4: emit 交接单
```

## Step 1: 提取必改项

从 `review-report.md` 中提取：
1. 所有标记为 "Needs rework" 的角色的关注项
2. 高优先级问题（2+ 角色共振）
3. 核心张力中明确需要解决的部分

**不改的**：
- 单个角色的低优先级 concern（提醒用户但不动）
- 风格偏好类建议（架构师说解耦 vs 务实者说够用 → 让用户判断）

## Step 2: 修改 Plan

**只改审查报告指出的问题**，不做额外优化/重构：

1. 逐个 blocker 修改对应的 plan 段落
2. 每个修改旁加 `<!-- reworked: [原因] -->` 注释
3. 修改完在 plan 末尾追加修订记录：

```markdown
## Rework Log
- [timestamp] 根据 review-report 修改：
  - [修改1]: [原因]
  - [修改2]: [原因]
```

## Step 3: 精简 Re-Review

**不重跑完整 4 角色审查**。只用 2 角色快速验证修改项：

- **原始 "Needs rework" 的角色**：验证自己提的问题是否被解决
- **Pragmatist**：确认修改没引入新的过度工程

如果原始 rework 角色就是 Pragmatist，则用 Architect 替补。

### Re-Review 输出格式

```markdown
## Re-Review: [角色名]
**修改项验证**:
- [问题1]: Resolved / Still open
- [问题2]: Resolved / Still open
**新增问题**: [有/无]
**结论**: Approved / Still needs work
```

## Step 4: Emit 交接单

```yaml
handoff:
  from: plan-rework
  status: ok | rework | blocked # 2 角色都 Approved = ok；仍有问题 = rework；未完成 = blocked
  artifact: "plan.md"       # 修改后的 plan
  blockers: []              # 只记录导致本阶段未完成的外部阻塞
  concerns: []              # rework 时列出仍未解决的问题
  next: await-user-decision # 本阶段不会自动回到 review 或进入 execution
  decisions_needed: ["按 status 确认执行、补充缺失条件，或决定再次修改、接受风险、停止"]
  review_round: 2           # 初始完整 review 为 1，本次精简 re-review 为 2
  rework_attempt: 1
  max_rework_attempts: 1
```

## 循环上限

- plan-rework → re-review 最多**1 轮**
- 如果 re-review 仍然 "Still needs work" → 交接单 status=rework，升级给用户
- 2 轮（原始 review + 1 次精简 re-review）后必须人工介入
- `next` 保持 `await-user-decision`；不得自动调用 multi-role-review 或再次调用 plan-rework

## 反模式

- **不要趁机重构 plan** — 只改报告指出的问题
- **不要跳过 re-review** — 改了就要验证
- **不要用 4 角色做 re-review** — 2 角色够了，省 context
- **不要把风格偏好当 blocker 改** — 那是用户的判断
