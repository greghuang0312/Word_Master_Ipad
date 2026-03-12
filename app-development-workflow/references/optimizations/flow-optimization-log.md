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

