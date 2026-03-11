# Protocols

## Table of Contents

1. Canonical Terms
2. Path Scope
3. Init Welcome
4. Phase Gate Checklist
5. Phase Transition Template
6. Task Transition Template
7. Rejection Handling SOP
8. Rollback SOP
9. Task Evidence Fill Rules
10. Verification Status Flow
11. Manual Review Stop Message
12. Approval and Optimization Records
13. Task Pause Template

## Canonical Terms

Use these literals exactly:

- Trigger word: `你好`
- Sign-off words: `通过`, `不通过`
- Task start word: `开始`
- Required fields: `Required Skills (Method)`, `Required Skills (Stack)`, `verification_status`
- Status values: `PASS`, `FAIL`, `PENDING_MANUAL`, `PASS(manual)`

Do not translate or replace these literals in checks, templates, or gate decisions.

## Path Scope

1. `SKILL_ROOT` = this skill directory (`app-development-workflow/`).
2. `PROJECT_ROOT` = user project workspace root.
3. References to phase artifacts and test logs use `PROJECT_ROOT/...`.
4. References to skill instructions, templates, and optimization records use `SKILL_ROOT/...`.

## Init Welcome

Trigger: user input is exactly `你好`.

Output this block first:

```text
    ___                ____           
   / _ | ___  ___     / __ \___ _   __
  / __ |/ _ \/ _ \   / /_/ / _ \ | / /
/_/ |_|\___/\___/   \____/\___/|_|/_/
                App Dev

By Greg Huang
```

Then explain in plain Chinese:
1. The workflow has 6 phases.
2. You will pause at sign-off checkpoints.
3. Start phase 1 immediately.
4. Ask for a 1-2 sentence app idea and target users.

## Phase Gate Checklist

- [ ] 交付物完整（对应阶段产出物）
- [ ] 测试证据可追溯（`verification_status=PASS` 或 `PASS(manual)`）
- [ ] 风险与回滚方案已记录
- [ ] 下一阶段入口条件满足

## Phase Transition Template

```markdown
# 进入阶段 {{N}} 前
我们先做个小检查，确认可以安心进入【阶段 {{N}}：{{phase_name}}】：
- 这一阶段该交付的内容是否齐全？
- 测试证据是否可追溯且为 PASS / PASS(manual)？
- 风险点和回滚办法是否已经记录？
- 下一阶段所需输入是否都准备好了？

# 阶段 {{N}} 完成待签核
【阶段 {{N}}：{{phase_name}}】已完成，产出了：{{deliverables}}。
请确认是否通过本阶段签核？**准备好了**就回复：**通过**；如有疑问回复：**不通过**。

# 签核通过后
收到，你已确认通过【阶段 {{N}}】。
接下来进入【阶段 {{N+1}}：{{next_phase_name}}】，我会基于这些输入继续：{{inputs}}。
```

## Task Transition Template

```markdown
当前任务【{{task_name}}】已完成并通过测试。
接下来我会开始下一个任务：【{{next_task_name}}】。
开始前我会先检查它的输入、依赖和验收标准是否齐全。
```

## Rejection Handling SOP

When user replies `不通过`:
1. Ask for concrete rejection reasons and requested changes.
2. Write issues under `rejection_record` in the current phase doc.
3. Apply fixes and rerun tests.
4. Resubmit sign-off.

Stop rule:
1. Allow maximum 3 rejection loops.
2. If still rejected in loop 3, propose pause and re-scope requirements/design.

## Rollback SOP

When rollback is needed:
1. State issue and proposed rollback target phase.
2. Ask for user confirmation.
3. Roll back only after explicit user agreement.
4. Log rollback record to `SKILL_ROOT/references/optimizations/flow-optimization-log.md`.

Hard rule:
1. Never rollback phase without user confirmation.

## Task Evidence Fill Rules

Fill the `验证证据` table in each task markdown directly after testing.

| Field | Rule |
|---|---|
| `tested_at` | ISO 8601 timestamp at test execution time |
| `tested_by` | `agent` |
| `command` | Actual executed test command |
| `exit_code` | Command return code (`0` pass, non-`0` fail, `-` for no CLI test) |
| `evidence_path` | Log file path, e.g. `PROJECT_ROOT/logs/<task-id>-test.log` |
| `verification_status` | `PASS`, `FAIL`, `PENDING_MANUAL`, or `PASS(manual)` |

Hard rules:
1. Use file editing tool to update the task markdown table directly.
2. Never fabricate test evidence.
3. If there is no CLI test, set `exit_code` to `-` and set `verification_status` to `PENDING_MANUAL`.
4. Change `PENDING_MANUAL` to `PASS(manual)` only after explicit user confirmation.

## Verification Status Flow

Use this exact flow:

1. `FAIL` -> trigger `systematic-debugging`, fix, and retest.
2. `PENDING_MANUAL` -> send manual review stop message and wait.
3. `PASS(manual)` -> treat as approved test evidence after explicit manual sign-off.
4. `PASS` -> treat as approved test evidence from executable tests.

Phase/task progression rule:

1. Allow progression only when final status is `PASS` or `PASS(manual)`.

## Manual Review Stop Message

Send this and stop:

```text
当前任务的开发和测试已完成，现进入人工审核阶段。
请先进行人工审核；如无问题，请回复"通过"，我再执行 git add 和 git commit。
```

Hard rule:
1. Do not run `git add` or `git commit` before explicit user reply `通过`.

## Approval and Optimization Records

Append `approval_record` to each phase artifact under `PROJECT_ROOT/docs/` at phase completion.

Append one row to `SKILL_ROOT/references/optimizations/flow-optimization-log.md` after each approved phase and before entering next phase:

| 字段 | 内容 |
|---|---|
| 阶段 | N |
| 问题现象 | - |
| 建议改进 | - |
| 优先级 | 高 / 中 / 低 |
| 是否采纳 | 待定 / 是 / 否 |

## Task Pause Template

Send this before starting each task:

```text
下一个任务：【{{task_name}}】
范围：{{scope_summary}}
依赖：{{dependencies}}
预计产出：{{expected_output}}

准备好开始了吗？请回复：**开始** 继续。
```
