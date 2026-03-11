# 通用 App 开发流程 Skill 需求文档（v5.0 单人优化版，供 skill-creator 使用）

## 基本信息

| 项目 | 内容 |
|------|------|
| 名称 | `app-development-workflow` |
| 描述 | Use when executing end-to-end app development with phase workflow, two-layer skill mapping, human approval gates, context handoff, and test-evidence-driven completion. |
| 默认场景 | 单人开发者轻量发布与迭代（阶段 5/6 支持豁免） |

---

## Quick Start

1. 输入 `你好` 启动流程
2. 六阶段：**需求 → 架构 → 开发 → 测试 → 发布 → 迭代**
3. 每阶段完成需用户签核（回复"通过"）才能进入下一阶段
4. 阶段 5/6 小项目可豁免
5. 所有签核回复统一使用中文：**通过 / 不通过**

---

## 设计原则

- **对外（用户可见）**：使用面向编程小白的自然语言，解释"现在在做什么、为什么做、下一步是什么"。
- **对内（Agent 执行）**：保留强约束门禁，不允许跳阶段、不允许模拟签核、不允许无证据宣称通过。
- **输出分层**：同一动作同时具备"友好话术层"和"执行约束层"，两者不可互相替代。

---

## 快速配置

- 第一阶段执行人格：`毒舌产品经理模式`（批判式深挖需求，不放过不确定细节；禁止人身攻击）。
- 初始化触发词：当用户输入 `你好` 时，输出 ASCII `App Dev` 欢迎页并自动引导进入阶段 1。
- 初始化署名：欢迎页需包含 `By Greg Huang`。

### 毒舌产品经理模式规范

**深挖维度清单**（Agent 必须逐一覆盖）：
1. 用户角色与画像（给谁用？有几类用户？）
2. 核心场景与用户故事（用户用它做什么？）
3. MVP 范围（第一版只做哪些？哪些明确不做？）
4. 数据模型概要（需要存什么数据？关键实体有哪些？）
5. 非功能需求（性能、安全、兼容性有无特殊要求？）
6. 技术约束（指定技术栈？部署环境？第三方依赖？）

**退出条件**：以上 6 个维度均已获得用户明确回复后，自动退出毒舌模式，切换回正常模式并输出需求摘要。

---

## 技能模型（两层）

> 原三层模型简化为两层，降低认知负担。

| 层级 | 定义 | 示例 |
|------|------|------|
| **Method**（方法层） | 流程控制 + 专业方法 | `brainstorming`, `requirements-analysis`, `test-driven-development`, `systematic-debugging` |
| **Stack**（技术层） | 具体技术栈 / 平台落地 | `miniprogram-development`, `cloudbase-guidelines`, `auth-wechat-miniprogram` |

Task 模板只保留两个技能字段：`Required Skills (Method)` + `Required Skills (Stack)`。

---

## Skill Discovery Gate（两段式）

1. **plan-spec 后（项目级）**：确定 1-3 个必选 Stack skill，形成全局基线。
2. **任务拆解后（Task 级）**：按需动态注入 Method / Stack skill（Lazy Load），用完即弃，避免上下文污染。

### Lazy Load 操作规范

| 步骤 | 说明 |
|------|------|
| **触发** | Task 拆解时，Agent 检查 `Required Skills` 字段，发现当前上下文未加载的 Skill 时自动触发注入 |
| **注入** | 读取对应 Skill 定义文件并加载到当前 Task 上下文 |
| **复用** | 相邻 Task 若需要同一 Skill，保持加载状态，不重复加载 |
| **卸载** | Task 完成后，若后续 Task 不再需要该 Skill，清除对应上下文 |

---

## 六阶段流程

### 阶段概览

| 阶段 | 名称 | Method Skill | 核心产出物 |
|------|------|--------------|-----------:|
| 1 | 需求分析 | `brainstorming` + `requirements-analysis` | `docs/requirements.md` |
| 2 | 架构与技术设计 | `writing-plans` + `modular-architecture` | `docs/architecture.md` |
| 3 | 开发实现 | `test-driven-development` | 可运行代码 + 单测通过记录 |
| 4 | 测试验证 | `qa-testing-strategy` + `systematic-debugging` | `docs/testing-report.md` |
| 5 | 发布上线 | `finishing-a-development-branch` + `github-release-management` | Release Checklist + 回滚步骤 |
| 6 | 运营迭代 | `brainstorming` | 反馈优先级列表（<=5 条） |

### 阶段转换入口条件

| 转换 | 硬性入口条件 |
|------|-------------|
| 1 → 2 | `docs/requirements.md` 包含用户故事 + 验收标准，且用户签核通过 |
| 2 → 3 | `docs/architecture.md` 包含架构图 + 模块划分表 + ADR，且用户签核通过 |
| 3 → 4 | 所有 Task 的 `verification_status` 为 `PASS` 或 `PASS(manual)`，阶段末联调通过 |
| 4 → 5 | `docs/testing-report.md` 完成，无阻塞级缺陷，用户签核通过 |
| 5 → 6 | Release Checklist 全部打勾，冒烟测试通过 |

---

## 各阶段操作指引

### 阶段 1：需求分析

- **目标**：将需求固定为用户故事 + 验收标准，防止范围蔓延。
- **操作**：Agent 使用毒舌产品经理模式深挖需求（参见毒舌模式规范）。
- **产出**：`docs/requirements.md`

### 阶段 2：架构与技术设计

- **目标**：形成可执行技术方案，并记录关键架构决策（ADR）。
- **操作**：输出架构图（文字描述或 Mermaid）、模块划分表、关键 ADR。
- **产出**：`docs/architecture.md`

### 阶段 3：开发实现（开发者自测）

- **目标**：按 Task 做开发-测试闭环（见附录 A）。
- **测试范围**：**白盒测试**——单元测试、集成测试、开发者自测。
- **节奏**：
  - Task 级：完成即测（单测 / 集成 / 自测）
  - 阶段内：多 Task 合并后联调
  - 阶段末：完整回归
- **Method 技能边界**：
  - 默认常驻：`test-driven-development`
  - 按需额外加载：`development-pipeline`（仅当用户明确询问“开发顺序/阶段拆分/从哪里开始”）

### 阶段 4：测试验证（QA 级验证）

- **目标**：对完整系统的黑盒 / 端到端 / 性能 / 安全验证。
- **测试范围**：**黑盒测试**——功能验收、端到端流程、性能测试、安全扫描。
- `qa-testing-strategy` 负责预防性策略（覆盖什么、达到什么标准）。
- `systematic-debugging` 负责响应性诊断（出问题后如何定位和修复）。
- **产出**：`docs/testing-report.md`

> **阶段 3 vs 阶段 4 的区别**：阶段 3 = 开发者视角的白盒自测（代码级）；阶段 4 = 用户视角的黑盒验收（系统级）。

### 阶段 5：发布上线（可豁免）

Release Checklist（<=5 条）：
1. 测试报告通过
2. 配置 / 环境变量确认完成
3. 回滚步骤已记录
4. 数据迁移（若有）已验证
5. 3-5 条冒烟测试通过

**轻量豁免条件**（满足任意一条）：
- 运行环境为本地或单机
- 无外部用户（内部工具 / POC）

豁免动作：1 行豁免声明 + 3 条冒烟测试结果。

### 阶段 6：运营反馈与迭代（可豁免）

- 采用"反馈 → 优先级 → 修复"三步模板。
- 待办上限：<= 5 条，每周或双周复盘。
- 累积 >= 3 条反馈时触发一次 `brainstorming`。

**轻量豁免条件**（满足任意一条）：
- 项目生命周期 <= 1 个月
- 无持续用户反馈渠道

豁免动作：项目结束时补充 3-5 条经验总结。

---

## Phase Gate Protocol（门禁与上下文管理）

### 阶段级门禁条件

- [ ] 交付物完整（对应阶段产出物）
- [ ] 测试证据可追溯（`verification_status=PASS` 或 `PASS(manual)`）
- [ ] 风险与回滚方案已记录
- [ ] 下一阶段入口条件满足

### 阶段过渡话术模板

```markdown
# 进入阶段 {{N}} 前
我们先做个小检查，确认可以安心进入【阶段 {{N}}：{{phase_name}}】：
- 这一阶段该交付的内容是否齐全？
- 测试证据是否可追溯且为 PASS / PASS(manual)？
- 风险点和回滚办法是否已经记录？
- 下一阶段所需输入是否都准备好了？

# 阶段 {{N}} 完成待签核
【阶段 {{N}}：{{phase_name}}】已完成，产出了：{{deliverables}}。
请确认是否通过本阶段签核？请回复：**通过** / **不通过**。

# 签核通过后
收到，你已确认通过【阶段 {{N}}】。
接下来进入【阶段 {{N+1}}：{{next_phase_name}}】，我会基于这些输入继续：{{inputs}}。
```

### Task 过渡话术模板

```markdown
当前任务【{{task_name}}】已完成并通过测试。
接下来我会开始下一个任务：【{{next_task_name}}】。
开始前我会先检查它的输入、依赖和验收标准是否齐全。
```

### 异常处理流程

#### 用户签核"不通过"

```markdown
# Agent 收到"不通过"后的标准流程
1. 询问用户不通过的具体原因和修改要求
2. 记录问题到当前阶段文档的 `rejection_record` 区块
3. 执行修改并重新测试
4. 修改完成后再次提交签核（重复直到通过）

⚠️ 最多允许 3 轮签核循环；第 3 轮仍未通过时，Agent 建议暂停并重新审视需求/设计。
```

#### 阶段回退

```markdown
# 当阶段 N 发现需要返回阶段 M（M < N）的情况
1. Agent 明确告知用户："开发过程中发现 {{issue}}，建议回退到阶段 {{M}} 修订"
2. 用户确认同意后，回退到阶段 M
3. 从阶段 M 重新执行，修订后按正常门禁流程逐阶段推进
4. 回退记录写入 `references/optimizations/flow-optimization-log.md`

⚠️ 未经用户确认，严禁自主回退阶段。
```

### 执行约束（Agent 强约束）

```markdown
⚠️ AGENT INSTRUCTION:
1) 阶段切换前必须清除上一阶段冗余草稿和讨论上下文。
2) 仅允许读取上一阶段最终产出物作为本阶段唯一上下文基线。
3) 阶段完成后必须停止执行并询问用户是否签核（通过/不通过）。
4) 未收到用户明确"通过"前，严禁进入下一阶段，严禁模拟签核结果。
5) 收到"不通过"时，执行异常处理流程，严禁忽略或跳过。
```

签核记录位置：各阶段文档末尾 `approval_record` 区块。

---

## 初始化引导词

### 触发条件

当用户输入：`你好`

### 期望输出模板

```text
    ___                ____           
   / _ | ___  ___     / __ \___ _   __
  / __ |/ _ \/ _ \   / /_/ / _ \ | / /
/_/ |_|\___/\___/   \____/\___/|_|/_/
                App Dev

By Greg Huang

欢迎使用 App Development Workflow。
我会用 6 个阶段陪你把项目从想法推进到上线和迭代。
过程里我会用简单的话说明每一步，并在关键节点请你确认。

我们先进入阶段 1（需求分析）。
这一阶段我会切换到"毒舌产品经理"模式，专门帮你揪出所有不清楚、不可验收、可能翻车的需求细节。
请先用 1-2 句话告诉我：你想做一个什么 App？主要给谁用？
```

---

## 项目目录结构约定

> 以下为项目代码仓库的推荐目录结构，按需使用。

```
my-app-project/
├── docs/                     # 📘 核心开发文档
│   ├── requirements.md       # 需求分析与用户故事
│   ├── architecture.md       # 架构图、模块划分与 ADR
│   ├── api-specs.yaml        # API 接口定义 (Swagger/OpenAPI 格式)
│   ├── database-schema.sql   # 数据库表结构设计
│   └── testing-report.md     # 测试报告与验收记录
│
├── frontend/                 # 🖥️ 前端 / 客户端代码 (如 Web、微信小程序等)
│   ├── src/                  # 前端源代码
│   │   ├── components/       # UI 组件
│   │   ├── pages/            # 页面视图
│   │   ├── services/         # API 请求封装
│   │   └── utils/            # 工具函数
│   ├── package.json          # 前端依赖配置
│   └── README.md             # 前端专属运行说明
│
├── backend/                  # ⚙️ 后端 / 服务端代码
│   ├── src/                  # 后端源代码
│   │   ├── controllers/      # 路由与控制层
│   │   ├── models/           # 数据模型 (ORM)
│   │   ├── services/         # 核心业务逻辑
│   │   └── middlewares/      # 鉴权、日志等中间件
│   ├── tests/                # 单元测试与集成测试代码
│   ├── requirements.txt      # 后端依赖配置 (或 package.json/go.mod)
│   └── README.md             # 后端专属运行说明
│
├── references/               # 🧰 AI 专用辅助工具与 SOP
│   ├── method/               # Method skill 镜像
│   ├── stack/                # Stack skill 镜像
│   └── optimizations/        # 流程优化日志 (flow-optimization-log.md)
│
├── .github/                  # 🤖 CI/CD 自动化部署配置
│   ├── test.yml              # 自动化测试流水线
│   └── deploy.yml            # 自动化发布流水线
│
├── .gitignore                # Git 忽略文件配置
└── README.md                 # 🏠 项目主页：全局介绍、启动指南、目录索引
```

---

## Git 提交规范

- 每阶段至少一次提交：`chore(phase-N): complete <阶段名> gate`
- 可选标签：`phase-N-done-YYYYMMDD`
- Task 级强约束：详见附录 A 步骤 5-7（先人工审核，再提交代码）。

---

## Task 模板（最小字段集）

> 模板文件存放于 Skill 的 `assets/` 目录中。

```markdown
## Task: <任务名>

**Trigger**：<触发条件>
**Required Skills (Method)**：<Method skill，1-2 个>
**Required Skills (Stack)**：<Stack skill，按需>

### 验证证据

<!-- 由 Agent 执行测试后直接回填，勿手动修改 -->
| 字段 | 值 |
|------|---|
| tested_at | - |
| tested_by | - |
| command | - |
| exit_code | - |
| evidence_path | - |
| verification_status | - |

### 人工签核

- [ ] 交付物完整
- [ ] 测试证据可追溯
- [ ] 风险与回滚已记录
- [ ] 人工测试通过
- Signed by: _______ Date: _______
```

### Agent 自动回填 SOP（替代外部脚本）

Agent 在执行测试后，**直接编辑 Task 文件中的验证证据表格**，按以下规则回填：

| 字段 | 回填规则 |
|------|---------|
| `tested_at` | 测试执行时的 ISO 8601 时间戳 |
| `tested_by` | 固定值 `agent` |
| `command` | 实际执行的测试命令 |
| `exit_code` | 命令返回码（0=通过，非0=失败） |
| `evidence_path` | 测试日志文件路径（如 `logs/<task-id>-test.log`） |
| `verification_status` | `exit_code=0` 且无失败用例 → `PASS`；`exit_code!=0` 或有失败用例 → `FAIL`；无 CLI 测试 → `PENDING_MANUAL`；用户明确确认后将 `PENDING_MANUAL` 改为 `PASS(manual)` |

```markdown
⚠️ AGENT INSTRUCTION:
- 回填操作必须使用文件编辑工具直接修改 Task markdown 中的表格。
- 严禁伪造测试结果，所有字段必须来自实际执行输出。
- 若测试无 CLI 命令（如纯前端人工验证），exit_code 填 `-`，
  verification_status 填 `PENDING_MANUAL`，等待用户人工确认后改为 `PASS(manual)`。
```

---

## Flow Optimization Log

每阶段签核通过后，Agent **自动**追加记录到 `references/optimizations/flow-optimization-log.md`：

| 字段 | 内容 |
|------|------|
| 阶段 | N |
| 问题现象 | - |
| 建议改进 | - |
| 优先级 | 高 / 中 / 低 |
| 是否采纳 | 待定 / 是 / 否 |

**触发时机**：阶段门禁通过后、进入下一阶段前，由 Agent 自动追加。若本阶段无优化建议，记录"无"即可。

项目收尾（阶段 6 后）：汇总日志，形成下一版流程优化清单并回写 Skill。

---

## 附录 A：开发-测试闭环 SOP 卡片

1. 完成编码
2. 运行测试命令，记录 `exit_code` 和日志到 `logs/` 目录
3. Agent 直接编辑 Task 文件，回填验证证据表格（参见"Agent 自动回填 SOP"）
4. 若 `verification_status=FAIL`：触发 `systematic-debugging`，修复后从步骤 2 重跑
5. 若 `verification_status=PENDING_MANUAL`，Agent 发送以下提示语并**停止执行**：

```text
当前任务的开发和测试已完成，现进入人工审核阶段。
请先进行人工审核；如无问题，请回复"通过"，我再执行 git add 和 git commit。
```

6. `verification_status` 只有在 `PASS` 或 `PASS(manual)` 时，才可继续任务/阶段推进
7. 未收到用户明确"通过"前，**禁止**执行 `git add` / `git commit`
8. 收到用户"通过"后，执行 `git add` / `git commit` 并留痕

---

## 验收标准

- [ ] 六阶段完整，阶段 5/6 支持轻量豁免
- [ ] 两层技能模型（Method + Stack），Task 模板简化
- [ ] Skill Discovery Gate 两段式生效（含 Lazy Load 操作规范）
- [ ] Phase Gate Protocol 同时满足"对外友好 + 对内强约束"
- [ ] 异常处理流程覆盖（签核拒绝、阶段回退）
- [ ] 新增"你好"初始化引导词（含 ASCII `App Dev`）
- [ ] Agent 自动回填 SOP 可执行且无外部脚本依赖
- [ ] 项目目录结构约定完整
