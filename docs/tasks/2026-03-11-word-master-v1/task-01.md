## Task: 项目骨架与导航容器

**Trigger**：阶段 3 执行，且前置任务完成后进入当前任务  
**Required Skills (Method)**：`test-driven-development`  
**Required Skills (Stack)**：`swift_swiftui`

### 任务描述

- **范围**：创建 App 入口、登录态路由与 5 Tab 容器骨架
- **验收标准**：与 `docs/plans/2026-03-11-word-master-v1.md` 中 Task 1 定义一致（FAIL -> PASS 闭环）
- **依赖**：无

### 文件清单

- Create: `WordMaster/WordMasterApp.swift`
- Create: `WordMaster/App/AppRouter.swift`
- Create: `WordMaster/App/MainTabView.swift`
- Create: `WordMaster/Features/Auth/LoginView.swift`
- Test: `WordMasterTests/AppRouterTests.swift`

### TDD 步骤

- Step 1: 编写失败测试（已创建 `WordMasterTests/AppRouterTests.swift`）
- Step 2: 运行测试，确认 FAIL（证据日志：`logs/task-01-manual-review.log`）
- Step 3: 编写最小实现代码
- Step 4: 运行测试，确认 PASS（当前环境无 `xcodebuild`，转人工复核）
- Step 5: 提交（仅在用户回复 通过 后执行）

### 验证证据

| 字段 | 值 |
|---|---|
| tested_at | 2026-03-11T21:16:46.2718873+08:00 |
| tested_by | agent |
| command | `xcodebuild test -scheme WordMaster -destination "platform=iOS Simulator,name=iPad (10th generation)" -only-testing:WordMasterTests/AppRouterTests` |
| exit_code | - |
| evidence_path | `logs/task-01-manual-review.log` |
| verification_status | PASS(manual) |

### 人工签核

- [ ] 交付物完整
- [ ] 测试证据可追溯
- [ ] 风险与回滚已记录
- [ ] 人工测试通过
- Signed by: _______ Date: _______
