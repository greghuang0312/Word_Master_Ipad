---
name: app-development-workflow
description: Run end-to-end app delivery with a strict six-phase workflow (requirements, architecture, implementation, testing, release, iteration), two-layer skill mapping (Method/Stack), mandatory human sign-off gates (通过/不通过), lazy-loaded skill context, and test-evidence-driven progression. Use when users ask to build, release, and iterate an app in controlled phases.
---

# App Development Workflow

## Execute Startup

1. Detect user message `你好`.
2. Output the exact ASCII welcome block in `SKILL_ROOT/references/protocols.md` section `Init Welcome`.
3. Include `By Greg Huang`.
4. Explain the six-phase process in beginner-friendly Chinese.
5. Start phase 1 immediately and switch to `毒舌产品经理模式`.

## Enforce Language Convention

1. Write user-facing explanations in Chinese by default.
2. Keep machine literals unchanged: `Required Skills (Method)`, `Required Skills (Stack)`, `verification_status`, `PASS`, `FAIL`, `PENDING_MANUAL`, `PASS(manual)`, `通过`, `不通过`, `你好`, `开始`.
3. Do not replace canonical literals with synonyms or translated variants in templates and checks.

## Enforce Canonical Sources

1. Use `SKILL_ROOT/references/protocols.md` as the single source for canonical literals and path scope.
2. Use `SKILL_ROOT/references/phase-playbook.md` as the single source for phase goals, deliverables, and entry gates.
3. Use `SKILL_ROOT/references/stack/STACK-SKILL-MAP.md` as the single source for stack resolution.

## Enforce Global Rules

1. Explain each action to users with plain Chinese: what, why, next step.
2. Enforce hard constraints internally: never skip phase, never simulate sign-off, never claim pass without evidence.
3. Require explicit user reply `通过` before entering the next phase.
4. Treat any non-`通过` response as not approved.
5. On `不通过`, execute the rejection workflow from `SKILL_ROOT/references/protocols.md`.
6. Before phase switch, clear draft/discussion context and keep only previous phase final artifact as baseline.
7. Write `approval_record` in each phase document.
8. Append one optimization log entry before entering the next phase.

## Apply Two-Layer Skill Model

1. Use only two task fields: `Required Skills (Method)` and `Required Skills (Stack)`.
2. After project-level plan/spec, lock 1-3 mandatory stack skills as baseline.
3. Resolve stack skill source via `SKILL_ROOT/references/stack/STACK-SKILL-MAP.md` using `global-first` policy.
4. After task decomposition, lazy-load missing method/stack skills per task.
5. Load only one stack skill per task by default; keep loaded only if the next adjacent task explicitly reuses it.
6. Unload irrelevant skills immediately after task completion.
7. Use `development-pipeline` only when users explicitly ask about development order/phases; it is not a default skill for any phase.
8. When coding a task, apply the loaded stack skill's guidelines (naming, patterns, constraints) to the generated code.

## Discover and Configure Stack Skills

1. At the end of Phase 1 (after requirements are approved), extract technology stack keywords from confirmed requirements (languages, frameworks, platforms, databases, cloud services).
2. For each keyword, run `find-skills <keyword>` to search for available stack skills.
3. Present search results to user with a summary of each skill's purpose.
4. Wait for user to select which skills to install (`install-skill <skill-name>`).
5. After installation, append one row per skill to `SKILL_ROOT/references/stack/STACK-SKILL-MAP.md` with Resolution=global, Load Hint=task-only.
6. If the project tech stack changes (e.g., during Phase 2 architecture decisions), repeat steps 2-5 for new stack keywords.
7. At Phase 2 start, verify that `STACK-SKILL-MAP.md` contains all skills matching the architecture's technology choices.

## Phase Startup Checklist

Before executing any phase:
1. Read `SKILL_ROOT/references/phase-playbook.md` Phase Matrix row for current phase.
2. Load all listed Method Skills by reading each skill's `SKILL.md` from the path in `Method Skill Local Paths` table.
3. If in phase 3 or later, load baseline stack skills from `STACK-SKILL-MAP.md` per `Apply Two-Layer Skill Model` rules.
4. If any required skill (Method or Stack) is missing, use `find-skills` to search and prompt user to install.
5. Confirm all skills loaded, then proceed with phase goals.

## Run Phase Workflow

1. Execute `Phase Startup Checklist` above.
2. Check the phase gate checklist in `SKILL_ROOT/references/protocols.md`.
3. Execute phase goals and produce required artifact.
4. Ask for phase sign-off using the template in `SKILL_ROOT/references/protocols.md`.
5. Stop execution and wait for user reply.
6. On `通过`, record approval and append optimization log.
7. For phase 5 or phase 6, allow exemption only when exemption conditions are met, and emit required exemption evidence.

## Run Task Delivery Loop

1. Read the implementation plan created in Phase 2 from `PROJECT_ROOT/docs/plans/YYYY-MM-DD-<feature>.md` to obtain the task list and TDD step structure.
2. Create task cards from `SKILL_ROOT/assets/task-template.md` for each task in the plan.
3. Before starting each task, output the `Task Pause Template` from `SKILL_ROOT/references/protocols.md` and wait for user reply `开始`.
4. Load any task-specific stack skills per `Apply Two-Layer Skill Model` rules.
5. Execute each task following the `writing-plans` TDD step structure:
   a. Write the failing test (exact file path, exact test code).
   b. Run test — verify FAIL.
   c. Write minimal implementation code.
   d. Run test — verify PASS.
   e. Refactor if needed, re-run test.
6. Save test logs under `PROJECT_ROOT/logs/`.
7. Fill the `验证证据` table in the task file using rules in `SKILL_ROOT/references/protocols.md`.
8. Follow `Verification Status Flow` in `SKILL_ROOT/references/protocols.md` to handle FAIL, PENDING_MANUAL, and PASS states.
9. Run `git add` and `git commit` only after user reply `通过`.
10. Output the `Task Transition Template` from `SKILL_ROOT/references/protocols.md` and wait for user confirmation before starting next task.

## Handle Exceptions

1. Handle sign-off rejection: ask reason, write `rejection_record`, revise, retest, resubmit.
2. Limit rejection loop to 3 rounds; after round 3 failure, propose pause and re-scope.
3. Handle phase rollback only after user confirmation.
4. Write rollback entries to `SKILL_ROOT/references/optimizations/flow-optimization-log.md`.
5. Never rollback autonomously.

## Use Bundled Resources

- `SKILL_ROOT/references/phase-playbook.md`: six phases, deliverables, gates, exemptions.
- `SKILL_ROOT/references/protocols.md`: welcome text, gate checklist, transition templates, evidence SOP, exception SOP.
- `SKILL_ROOT/references/optimizations/flow-optimization-log.md`: workflow optimization ledger tied to this skill.
- `SKILL_ROOT/references/stack/STACK-SKILL-MAP.md`: stack baseline resolution and local path map.
- `SKILL_ROOT/assets/task-template.md`: standard task card with verification evidence table.
- `SKILL_ROOT/assets/flow-optimization-log-template.md`: row template for optimization log append.
