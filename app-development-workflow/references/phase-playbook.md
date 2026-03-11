# Phase Playbook

## Table of Contents

1. Phase Matrix
2. Path Scope Convention
3. Method Skill Local Paths
4. Stack Skill Path Policy
5. Phase Entry Gates
6. Phase Goals
7. Recommended Repository Layout

## Phase Matrix

| Phase | Name | Method Skills | Stack Skills | Core Deliverable |
|---|---|---|---|---|
| 1 | 需求分析 | `brainstorming`, `requirements-analysis` | — | `PROJECT_ROOT/docs/requirements.md` |
| 2 | 架构与技术设计 | `writing-plans`, `modular-architecture` | 由 Phase 1 确定的技术栈动态填充 | `PROJECT_ROOT/docs/architecture.md` + `PROJECT_ROOT/docs/plans/*.md` |
| 3 | 开发实现 | `test-driven-development` | `STACK-SKILL-MAP.md` 中的 baseline skills | 可运行代码 + 单测通过记录 |
| 4 | 测试验证 | `qa-testing-strategy`, `systematic-debugging` | 同 Phase 3 | `PROJECT_ROOT/docs/testing-report.md` |
| 5 | 发布上线 | `finishing-a-development-branch`, `github-release-management` | 同 Phase 3 | Release Checklist + 回滚步骤 |
| 6 | 运营迭代 | `brainstorming` | — | 反馈优先级列表（<=5 条） |

## Path Scope Convention

1. Follow canonical path rules in `SKILL_ROOT/references/protocols.md`.
2. Keep method/stack skill mirrors under `SKILL_ROOT/references/{method,stack}/...`.
3. Keep workflow optimization logs under `SKILL_ROOT/references/optimizations/...`.

## Method Skill Local Paths

说明：
1. 任务中的主标识仍使用 skill 名称（例如 `brainstorming`）。
2. 相对路径仅用于在本项目中定位已同步的 skill 镜像。

| Method Skill | Local Relative Path |
|---|---|
| `brainstorming` | `SKILL_ROOT/references/method/brainstorming` |
| `requirements-analysis` | `SKILL_ROOT/references/method/requirements-analysis` |
| `writing-plans` | `SKILL_ROOT/references/method/writing-plans` |
| `modular-architecture` | `SKILL_ROOT/references/method/modular-architecture` |
| `test-driven-development` | `SKILL_ROOT/references/method/test-driven-development` |
| `development-pipeline` | `SKILL_ROOT/references/method/development-pipeline` |
| `qa-testing-strategy` | `SKILL_ROOT/references/method/qa-testing-strategy` |
| `systematic-debugging` | `SKILL_ROOT/references/method/systematic-debugging` |
| `finishing-a-development-branch` | `SKILL_ROOT/references/method/finishing-a-development-branch` |
| `github-release-management` | `SKILL_ROOT/references/method/github-release-management` |

## Stack Skill Path Policy

1. Keep stack skill name as the canonical task field value.
2. Define up to 1-3 baseline stack skills after project-level plan/spec.
3. Use global installed stack skills as default source (`global-first`).
4. Mirror stack skill locally only when one of these is true:
   - project-specific customization is required
   - strict version pinning or audit reproducibility is required
   - offline/isolated execution is required
5. Local mirror path format:
   `SKILL_ROOT/references/stack/<stack-skill-name>`.
6. For every baseline stack skill, append one row to
   `SKILL_ROOT/references/stack/STACK-SKILL-MAP.md` before phase execution.
7. At task runtime, load only one required stack skill at a time and unload after task completion unless the next adjacent task reuses it.
8. Do not duplicate mapping examples here; use `STACK-SKILL-MAP.md` as the only mapping table source.

## Phase Entry Gates

| Transition | Required Entry Condition |
|---|---|
| 1 -> 2 | `PROJECT_ROOT/docs/requirements.md` 包含用户故事 + 验收标准，Stack Skills 已通过 `find-skills` 搜索并配置到 `STACK-SKILL-MAP.md`，且用户签核通过 |
| 2 -> 3 | `PROJECT_ROOT/docs/architecture.md` 包含架构图 + 模块划分表 + ADR，且 `docs/plans/` 包含实施计划，且用户签核通过 |
| 3 -> 4 | 所有 Task 的 `verification_status` 为 `PASS` 或 `PASS(manual)`，阶段末联调通过 |
| 4 -> 5 | `PROJECT_ROOT/docs/testing-report.md` 完成，无阻塞级缺陷，用户签核通过 |
| 5 -> 6 | Release Checklist 全部打勾，冒烟测试通过 |

## Phase Goals

### Phase 1: 需求分析

- 固化用户故事和验收标准，防止范围蔓延。
- 使用毒舌产品经理模式逐项深挖 6 个维度：用户画像、核心场景、MVP 边界、数据模型、非功能需求、技术约束。
- 6 维都获得明确回复后退出毒舌模式并给出摘要。

### Phase 2: 架构与技术设计

- 形成可执行技术方案。
- 产出架构图（文本或 Mermaid）、模块划分表、关键 ADR。
- 使用 `writing-plans` skill 创建 `PROJECT_ROOT/docs/plans/YYYY-MM-DD-<feature>.md` 格式的实施计划，包含 step-by-step 任务分解。
- `architecture.md` 记录架构决策，实施计划单独存放于 `docs/plans/`。

### Phase 3: 开发实现（白盒）

- 执行 Task 级开发-测试闭环。
- 使用 `writing-plans` skill 创建的实施计划作为任务分解的基础，每个 Task 遵循 bite-sized 粒度（2-5 分钟/步）。
- 本阶段默认方法技能为 `test-driven-development`，遍历 TDD 循环：写测试 → 运行失败 → 写代码 → 运行通过 → 提交。
- 覆盖单元测试、集成测试、开发者自测。
- 进行阶段内联调和阶段末回归。
- `development-pipeline` 仅在用户明确询问“开发顺序/阶段拆分/从哪里开始”时额外加载，不作为 Phase 3 常驻技能。

### Phase 4: 测试验证（黑盒）

- 执行功能验收、端到端流程、性能测试、安全扫描。
- 使用 `qa-testing-strategy` 负责预防性覆盖策略。
- 使用 `systematic-debugging` 负责缺陷定位与修复闭环。

### Phase 5: 发布上线（可豁免）

Release Checklist（最多 5 条）:
1. 测试报告通过
2. 配置与环境变量确认完成
3. 回滚步骤已记录
4. 数据迁移（若有）已验证
5. 3-5 条冒烟测试通过

轻量豁免条件（满足任意一条）:
1. 运行环境为本地或单机
2. 无外部用户（内部工具或 POC）

豁免时输出:
1. 1 行豁免声明
2. 3 条冒烟测试结果

### Phase 6: 运营反馈与迭代（可豁免）

- 使用三步模板：反馈 -> 优先级 -> 修复。
- 限制待办上限为 5 条。
- 每周或双周复盘。
- 累积 >= 3 条反馈时触发一次 `brainstorming`。

轻量豁免条件（满足任意一条）:
1. 项目生命周期 <= 1 个月
2. 无持续用户反馈渠道

豁免时输出:
1. 项目结束时补充 3-5 条经验总结

## Recommended Repository Layout

以下目录树相对于 `PROJECT_ROOT/`。

```
my-app-project/
|- docs/
|  |- requirements.md
|  |- architecture.md
|  |- plans/
|  |  `- YYYY-MM-DD-<feature>.md
|  |- api-specs.yaml
|  |- database-schema.sql
|  `- testing-report.md
|- frontend/
|- backend/
|- .github/
|- .gitignore
`- README.md
```
