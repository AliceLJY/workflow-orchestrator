# Research: 自然语言驱动的开发流水线编排层

## 1. 现有 Skill 体系结构

**触发机制：**
- Skill 通过 `SessionStart` hook 注入（hooks.json 配置）
- Skill 标识符在 frontmatter 定义 (name/description/trigger)，系统通过意图匹配自动调用
- Trigger 词典示例：brainstorming 触发于"创意/特性/功能"，test-driven-development 触发于"实现/修复"

**嵌套调用：**
- Skill 可在执行过程中显式调用其他 Skill（如 brainstorming → writing-plans → subagent-driven-development）
- 通过 `superpowers:XXX` Skill tool 语法触发
- 支持链式调用（Terminal state 检查防循环）

**编排现状：**
- 单向流水线：brainstorming → writing-plans → (subagent-driven | executing-plans) → finishing
- 无"回流"概念，设计阶段不回溯代码阶段

## 2. 现有编排能力

**执行引擎：**
- `subagent-driven-development`：当前会话内，任务独立，双阶段审查（规范性 + 代码质量）
- `executing-plans`：独立会话，更大粒度任务，人工检查点
- 两者都从 plan 文件提取任务并顺序执行

**Plan 格式：**
```markdown
# Feature Implementation Plan
**Goal:** 一句话目标
**Architecture:** 2-3句设计思路
### Task N: 组件名
**Files:** Create/Modify/Test 清单
- [ ] Step 1-5: TDD 循环
```

**意图识别→路由：**
- **当前缺失**。无统一的"说人话 → 自动判断走哪一步"机制
- Brainstorming 通过显式问题逐步细化需求
- 无主编排层

## 3. 多角色审查机制

**Content Alchemy（写作 skill）：**
- Stage 4 执行"拆/辨/造"流程，三个视角：乐观/悲观/人文
- 非真正多 agent，而是框架内的逻辑检查清单
- Writing Persona 差异分析实现风格迭代

**Code Review（代码审查）：**
- 单一审查代理（code-reviewer subagent）
- 审查 prompt 包含 WHAT/PLAN/SHA/DESCRIPTION
- 评分维度固定（Strengths/Issues/Assessment）
- 无并行多 persona，顺序单次

**差距：** 无真正的"编辑部"式并行多轮审查

## 4. 技术方案评估

| 选项 | 优势 | 劣势 |
|------|------|------|
| **Skill 层** | 自动触发、复用现有框架 | 难灵活路由、trigger 词表有限 |
| **Hook 层** | SessionStart 可注入全局 prompt | 单次触发、无实时重评估 |
| **Prompt 层** | 最灵活、可动态修改 | 无持久化、每会话重建 |

## 5. 推荐方案：Skill + Hook 混合

### 架构三层

```
Hook 层（SessionStart）
  → 注入意图识别 prompt + 流水线状态
  
Skill 层（编排核心）
  → 解析意图 → 判断阶段 → 分发子 agent
  
子 Agent 层（执行）
  → 各自独立上下文，返回结构化摘要
```

### 意图识别

```
用户输入 → 意图分类 →
判断阶段：ideate | research | plan | run | review | ship | compound
```

### 多角色并行审查

- 3-5 个独立审查 agent：用户视角、架构、安全、可维护性、性能
- 并行 dispatch + 结构化汇总
- 沿用"精准构造上下文"模式（不继承全局历史）

### 上下文隔离

- 每个子 agent 构造精准上下文，不继承全局历史
- 结果写文件 or 返回结构化摘要（DONE/DONE_WITH_CONCERNS/BLOCKED）
- RecallNest checkpoint 记录流水线进度

### 实现优先级

1. **P0**: 多角色 plan review skill（独立可用，性价比最高）
2. **P1**: ideation 可能性地图 skill
3. **P2**: 意图识别 hook + 编排 skill（串联 P0+P1+existing skills）
4. **P3**: 全流水线自动流转 + RecallNest 进度恢复

### 设计原则

- **零污染**：子 agent 精准上下文，不继承全局历史
- **可恢复**：任意阶段可重新进入
- **人在回路**：关键决策点必须人工确认
- **说人话**：用户永远不需要记命令
