## Task: <任务名>

**Trigger**：<触发条件>  
**Required Skills (Method)**：<Method skill，1-2 个>  
**Required Skills (Stack)**：<Stack skill，按需>

### 任务描述

- **范围**：<本任务覆盖的功能范围>
- **验收标准**：<Pass/Fail 判定条件>
- **依赖**：<前置任务或外部依赖>

### 文件清单

<!-- 列出本任务涉及的所有文件，使用 writing-plans 风格的精确路径 -->
- Create: `<exact/path/to/new-file>`
- Modify: `<exact/path/to/existing-file:line-range>`
- Test: `<tests/exact/path/to/test-file>`

### TDD 步骤

<!-- 遵循 writing-plans bite-sized 粒度（2-5 分钟/步） -->

**Step 1: 编写失败测试**
<!-- 精确测试代码 -->

**Step 2: 运行测试，确认 FAIL**
<!-- 精确命令 + 预期输出 -->

**Step 3: 编写最小实现代码**
<!-- 精确实现代码 -->

**Step 4: 运行测试，确认 PASS**
<!-- 精确命令 + 预期输出 -->

**Step 5: 提交**
<!-- git add + git commit，仅在用户回复"通过"后执行 -->

### 验证证据

<!-- 由 Agent 执行测试后直接回填，勿手动修改。字段名和状态值保持字面量，不做翻译。 -->
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

