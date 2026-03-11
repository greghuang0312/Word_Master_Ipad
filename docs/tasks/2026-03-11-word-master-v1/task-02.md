## Task: 复习领域模型与艾宾浩斯调度器

**Trigger**：阶段 3 执行，且前置任务完成后进入当前任务  
**Required Skills (Method)**：$(System.Collections.Hashtable.Method)  
**Required Skills (Stack)**：$(System.Collections.Hashtable.Stack)

### 任务描述

- **范围**：实现阶段推进/回退与下次复习日期计算
- **验收标准**：与 $plan 中 Task 2 定义一致（FAIL -> PASS 闭环）
- **依赖**：Task 01

### 文件清单

- Create: `WordMaster/Core/Models/WordItem.swift`
- Create: `WordMaster/Core/Review/ReviewScheduler.swift`
- Test: `WordMasterTests/ReviewSchedulerTests.swift`

### TDD 步骤

- Step 1: 编写失败测试（以 $plan 中对应 Task 的测试代码为准）
- Step 2: 运行测试，确认 FAIL（保存日志到 logs/task-02-test-fail.log）
- Step 3: 编写最小实现代码
- Step 4: 运行测试，确认 PASS（保存日志到 logs/task-02-test-pass.log）
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
