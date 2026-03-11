## Task: 我的页（API Key + 退出）与方向适配

**Trigger**：阶段 3 执行，且前置任务完成后进入当前任务  
**Required Skills (Method)**：$(System.Collections.Hashtable.Method)  
**Required Skills (Stack)**：$(System.Collections.Hashtable.Stack)

### 任务描述

- **范围**：实现 API Key 保存/读取、退出登录及横竖屏适配
- **验收标准**：与 $plan 中 Task 8 定义一致（FAIL -> PASS 闭环）
- **依赖**：Task 01, Task 03

### 文件清单

- Create: `WordMaster/Features/Profile/ProfileViewModel.swift`
- Create: `WordMaster/Features/Profile/ProfileView.swift`
- Create: `WordMaster/Shared/Security/KeychainStore.swift`
- Modify: `WordMaster/App/MainTabView.swift`
- Test: `WordMasterTests/ProfileViewModelTests.swift`

### TDD 步骤

- Step 1: 编写失败测试（以 $plan 中对应 Task 的测试代码为准）
- Step 2: 运行测试，确认 FAIL（保存日志到 logs/task-08-test-fail.log）
- Step 3: 编写最小实现代码
- Step 4: 运行测试，确认 PASS（保存日志到 logs/task-08-test-pass.log）
- Step 5: 提交（仅在用户回复 通过 后执行）

### 验证证据

| 字段 | 值 |
|---|---|
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
