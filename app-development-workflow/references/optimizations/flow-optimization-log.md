# Flow Optimization Log

Path base:
1. This file lives under `SKILL_ROOT/references/optimizations/`.
2. Append one row after each approved phase and before entering the next phase.

| 阶段 | 问题现象 | 建议改进 | 优先级 | 是否采纳 |
|---|---|---|---|---|
| 1 | 需求边界初稿未显式写明“横竖屏支持”与“iPad 交互规范严格约束”，触发一次返工 | 在 Phase 1 需求提问清单中前置“屏幕方向支持”和“HIG 严格程度”必答项 | 高 | 待定 |
| 2 | 技术栈映射与阶段 2 交付节奏存在流程歧义：`STACK-SKILL-MAP` 可能残留旧技能，且架构与实施计划可能被同时提交 | 1) 当 `STACK-SKILL-MAP` 缺少所需 skill 时，先 `find-skills` 安装所需项，再清理旧 skill 并录入新 skill；2) `architecture.md` 与 `docs/plans/*.md` 分两步，先人工确认 `architecture.md` 通过后再产出实施计划 | 高 | 待定 |
| 2 | `skills add` 默认交互安装目标，命令执行易被卡在选择界面 | 对自动化安装统一使用 `--yes --global` 非交互模式，安装后强制做落地校验 | 中 | 待定 |
| 3 | 人工复核粒度定义不清 | 明确为“每个 step 均需要人工复核”，不允许跨 step 合并复核 | 高 | 待定 |

| 6 | 编码结束后的功能调整缺少统一处理路径，容易直接跳到“凭经验修复” | 固化“功能调整技能路由”顺序：1) 先判定调整类型（UI/交互、数据层、后端联调、算法/规则、测试回归）；2) 先查 Required Skills（方法层）与 `STACK-SKILL-MAP`（技术栈层）是否有可用 skill 并优先加载；3) 若缺失再用 `find-skills` 搜索与安装；4) 若仍无可用 skill，再使用大模型通用能力实施修复 | 高 | 待定 |
| 6 | 优化阶段是否调用 `brainstorming` 触发条件不清，导致过度调用或漏调用 | 明确触发规则：小改动/确定性修复（已有明确实现路径）不调用 `brainstorming`；当需求含糊、存在多方案权衡、影响架构或跨模块流程、或累计反馈 >=3 条时，再调用 `brainstorming` | 高 | 待定 |
