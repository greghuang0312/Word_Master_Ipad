# Flow Optimization Log

Path base:
1. This file lives under `SKILL_ROOT/references/optimizations/`.
2. Append one row after each approved phase and before entering the next phase.

| 阶段 | 问题现象 | 建议改进 | 优先级 | 是否采纳 |
|---|---|---|---|---|
| 1 | 用户初次描述需求不够详细，需多轮追问 | 毒舌产品经理模式有效，6维深挖方法可行 | 高 | 是 |
| 1 | 阶段1未加载 `brainstorming` skill | 阶段开始时应检查并加载 phase-playbook 规定的 Required Skills (Method) | 高 | 待采纳 |
| 1 | 阶段1未加载 `requirements-analysis` skill | 同上，需在阶段开始时显式加载所有规定的 Method Skills | 高 | 待采纳 |
| 2 | 架构设计需同时提供SQL和配置指南 | 一站式文档减少后续查找成本 | 中 | 是 |
| 2 | 阶段2未加载 `writing-plans` skill | writing-plans 要求创建 `docs/plans/YYYY-MM-DD-<feature>.md` 格式的实施计划，而非 architecture.md | 高 | 待采纳 |
| 2 | 阶段2未加载 `modular-architecture` skill | 同上，需在阶段开始时显式加载所有规定的 Method Skills | 高 | 待采纳 |
| 2.5 | 进入阶段3前未检查stack-skills-map是否有所需skill | 当STACK-SKILL-MAP中缺少项目所需stack时，应自动使用find-skills查找并提示用户选择 | 高 | 是 |
| 3 | 签核提示语"请回复：通过"语义不够友好 | 阶段过渡提示语改为"请回复：准备好了"，更符合用户期待 | 低 | 待采纳 |
| 3 | 阶段3开发过程中每一步没有人工确认 | 阶段3应按任务粒度暂停，等待用户确认后再继续下一步，而非一次性完成所有代码 | 高 | 待采纳 |
| 3 | 阶段3未加载 `test-driven-development` skill | TDD 要求"写测试→运行失败→写代码→测试通过→提交"循环，当前直接写代码跳过了测试步骤 | 高 | 待采纳 |
| 3 | 阶段3未使用已安装的 Stack Skills | swiftui-expert-skill、supabase-postgres-best-practices、ios-hig 已安装但未在开发过程中加载使用 | 高 | 待采纳 |

---

## 阶段 1-3 Skills 使用情况详细复盘

### 复盘日期：2026-03-11

---

### 一、phase-playbook 规定的 Skills 加载情况

#### 阶段 1：需求分析

| 规定 Skills (Method) | 是否加载 | 是否使用 | 差距分析 |
|---|---|---|---|
| `brainstorming` | ❌ 否 | ❌ 否 | 虽然使用了"毒舌产品经理模式"和"6维深挖"，但未正式加载 skill，可能遗漏 skill 中的最佳实践 |
| `requirements-analysis` | ❌ 否 | ❌ 否 | 手动完成了需求分析，但未获得 skill 中的结构化方法和模板 |

**根因**：阶段开始时未检查 phase-playbook.md 中的 Required Skills (Method) 列表

---

#### 阶段 2：架构与技术设计

| 规定 Skills (Method) | 是否加载 | 是否使用 | 差距分析 |
|---|---|---|---|
| `writing-plans` | ❌ 否 | ❌ 否 | 创建了 architecture.md 而非 `docs/plans/YYYY-MM-DD-<feature>.md` 格式的实施计划；缺少 step-by-step 任务分解和 TDD 循环 |
| `modular-architecture` | ❌ 否 | ❌ 否 | 参考了 skill 目录下的内容，但未正式加载，可能遗漏模块划分的最佳实践 |

**根因**：
1. 阶段开始时未检查 phase-playbook.md 中的 Required Skills (Method) 列表
2. 对 writing-plans skill 的输出格式理解有误（应是实施计划而非架构文档）

---

#### 阶段 3：开发实现

| 规定 Skills (Method) | 是否加载 | 是否使用 | 差距分析 |
|---|---|---|---|
| `test-driven-development` | ❌ 否 | ❌ 否 | 直接编写代码，完全跳过了"写测试→运行失败→写代码→测试通过"的 TDD 循环 |

| Stack Skills | 是否安装 | 是否加载 | 是否使用 | 差距分析 |
|---|---|---|---|---|
| `swiftui-expert-skill` | ✅ 是 | ❌ 否 | ❌ 否 | 已通过 find-skills 安装，但开发过程中未加载使用，可能遗漏 SwiftUI 最佳实践 |
| `supabase-postgres-best-practices` | ✅ 是 | ❌ 否 | ❌ 否 | 同上，可能遗漏 Supabase 数据库设计最佳实践 |
| `ios-hig` | ✅ 是 | ❌ 否 | ❌ 否 | 同上，可能遗漏 Apple HIG 设计规范细节 |

**根因**：
1. 阶段开始时未检查 phase-playbook.md 中的 Required Skills (Method) 列表
2. Stack Skills 安装后未在开发过程中实际加载使用
3. 阶段3缺少按任务粒度暂停等待用户确认的机制

---

### 二、核心问题总结

| 问题类型 | 问题描述 | 影响范围 | 建议解决方案 |
|---|---|---|---|
| **流程缺失** | 阶段开始时未检查 Required Skills (Method) | 阶段 1-3 | 在每个阶段开始时，自动读取 phase-playbook.md 并检查/加载规定的 Method Skills |
| **流程缺失** | Stack Skills 安装后未加载使用 | 阶段 3 | 在阶段3开始时和每个任务开始时，检查并加载相关的 Stack Skills |
| **格式错误** | writing-plans 输出格式不符合 skill 规定 | 阶段 2 | writing-plans 要求创建 `docs/plans/YYYY-MM-DD-<feature>.md` 格式的实施计划，包含 step-by-step 任务分解 |
| **方法缺失** | TDD 循环未执行 | 阶段 3 | 每个任务应遵循"写测试→运行失败→写代码→测试通过→提交"的循环 |
| **交互缺失** | 阶段3缺少人工确认 | 阶段 3 | 阶段3应按任务粒度暂停，等待用户确认后再继续下一步 |

---

### 三、改进建议优先级排序

| 优先级 | 改进项 | 实施难度 | 预期收益 |
|---|---|---|---|
| P0 | 阶段开始时自动检查并加载 Required Skills (Method) | 低 | 高 - 确保不遗漏关键方法论 |
| P0 | 阶段3按任务粒度暂停等待用户确认 | 低 | 高 - 提升用户控制感 |
| P1 | Stack Skills 在任务开始时加载使用 | 中 | 中 - 获得最佳实践指导 |
| P1 | TDD 循环执行 | 中 | 高 - 提升代码质量 |
| P2 | writing-plans 输出格式规范化 | 低 | 中 - 提升计划可执行性 |
| P3 | 签核提示语优化 | 低 | 低 - 提升用户体验 |

---

### 四、下次项目实施检查清单

#### 阶段开始前
- [ ] 读取 phase-playbook.md 获取当前阶段的 Required Skills (Method)
- [ ] 加载所有规定的 Method Skills
- [ ] 检查 STACK-SKILL-MAP.md 是否有所需 Stack Skills
- [ ] 如缺少 Stack Skills，使用 find-skills 查找并提示用户选择安装

#### 阶段进行中
- [ ] 每个任务开始时加载相关的 Stack Skills
- [ ] 按 TDD 方式进行开发（写测试→运行→写代码→测试→提交）
- [ ] 每完成一个任务暂停等待用户确认

#### 阶段结束前
- [ ] 检查交付物是否完整
- [ ] 记录优化建议到 flow-optimization-log.md
- [ ] 等待用户签核后再进入下一阶段
