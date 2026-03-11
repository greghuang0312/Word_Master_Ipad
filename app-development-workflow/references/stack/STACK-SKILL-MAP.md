# Stack Skill Map

Path base:
1. `SKILL_ROOT` = this skill directory (`app-development-workflow/`).
2. `GLOBAL_SKILLS_ROOT` = globally installed skills root (for example `~/.agents/skills`).
3. Local mirror path format = `SKILL_ROOT/references/stack/<stack-skill-name>`.

Usage rule:
1. Keep task field value as canonical stack skill name.
2. Use `Resolution=global` as default (`global-first`).
3. Use `Resolution=local-mirror` only for customization, version pinning/audit, or offline execution.
4. Use `Load Hint=task-only` by default to reduce token footprint.
5. Keep only baseline 1-3 stack skills active at project level.

| Stack Skill | Resolution | Global Path | Local Path | Version/Source | Load Hint | Notes |
|---|---|---|---|---|---|---|
| `miniprogram-development` | `global` | `GLOBAL_SKILLS_ROOT/miniprogram-development` | `SKILL_ROOT/references/stack/miniprogram-development` | - | `task-only` | |
| `cloudbase-guidelines` | `global` | `GLOBAL_SKILLS_ROOT/cloudbase-guidelines` | `SKILL_ROOT/references/stack/cloudbase-guidelines` | - | `task-only` | |
| `auth-wechat-miniprogram` | `global` | `GLOBAL_SKILLS_ROOT/auth-wechat-miniprogram` | `SKILL_ROOT/references/stack/auth-wechat-miniprogram` | - | `task-only` | |
| `swift_swiftui` | `global` | `GLOBAL_SKILLS_ROOT/swift_swiftui` | `SKILL_ROOT/references/stack/swift_swiftui` | `swiftzilla/skills@swift_swiftui` | `task-only` | Word Master iPad UI baseline |
| `supabase-postgres-best-practices` | `global` | `GLOBAL_SKILLS_ROOT/supabase-postgres-best-practices` | `SKILL_ROOT/references/stack/supabase-postgres-best-practices` | `supabase/agent-skills@supabase-postgres-best-practices` | `task-only` | Supabase + RLS baseline |
| `deepseek` | `global` | `GLOBAL_SKILLS_ROOT/deepseek` | `SKILL_ROOT/references/stack/deepseek` | `vm0-ai/vm0-skills@deepseek` | `task-only` | DeepSeek candidate generation baseline |
