# Flow Optimization Log

Path base:
1. This file lives under `SKILL_ROOT/references/optimizations/`.
2. Append one row after each approved phase and before entering the next phase.

| 阶段 | 问题现象 | 建议改进 | 优先级 | 是否采纳 |
|---|---|---|---|---|
| 1 | 需求边界初稿未显式写明“横竖屏支持”与“iPad 交互规范严格约束”，触发一次返工 | 在 Phase 1 需求提问清单中前置“屏幕方向支持”和“HIG 严格程度”必答项 | 高 | 待定 |
| 2 | 技术栈映射与阶段 2 交付节奏存在流程歧义：`STACK-SKILL-MAP` 可能残留旧技能，且架构与实施计划可能被同时提交 | 1) 当 `STACK-SKILL-MAP` 缺少所需 skill 时，先 `find-skills` 安装所需项，再清理旧 skill 并录入新 skill；2) `architecture.md` 与 `docs/plans/*.md` 分两步，先人工确认 `architecture.md` 通过后再产出实施计划 | 高 | 待定 |
| 2 | `skills add` 默认交互安装目标，命令执行易被卡在选择界面 | 对自动化安装统一使用 `--yes --global` 非交互模式，安装后强制做落地校验 | 中 | 待定 |
| 3 | 人工复核粒度定义不清，容易误解为“一个 step 完成后统一复核” | 明确为“每个 step 中的每个 task 均需要人工复核”，不允许跨 task 合并复核 | 高 | 待定 |
| 3 | 任务执行过程产出独立 `task-01~09.md` 任务卡，增加了不必要文档维护成本 | 后续不再创建 `task-01~09.md`，改为每个 task 完成后直接输出人工复核提示并等待 `通过`/`不通过` | 中 | 待定 |
| 3 | Windows 开发环境缺少 `xcodebuild`，无法执行 iPad 测试命令，导致流程阻塞 | 在 Windows 会话中允许“跳过自动测试、继续开发”，统一转人工复核并在 iPad 侧补测 | 高 | 待定 |
| 3 | 当前目录不含 `.git`，无法执行 `git add/commit` 形成可追溯提交链路 | 在 Phase 0/Phase 1 增加仓库健康检查（`.git` 存在性），缺失时先初始化或切换到正确仓库目录 | 高 | 待定 |
| 5 | 发布清单虽完成，但实机冒烟和 Supabase 联通验证仍依赖后置人工执行 | 将“iPad 冒烟 + Supabase 联通”前移为发布前硬门禁，不满足则标记“仅预发布准备” | 高 | 待定 |
