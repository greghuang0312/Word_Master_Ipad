# Word Master 在 Swift Playgrounds（iPad）测试步骤

更新时间：2026-03-11  
适用场景：当前开发机为 Windows，无法运行 `xcodebuild`，改为 iPad 侧人工测试。

## 1. 环境建议（为什么 Windows 不能直接测）

1. `xcodebuild` 仅在 macOS + Xcode 环境可用。
2. 你当前在 Windows，只能做代码编辑，不能跑 iOS/iPad Simulator 自动测试。
3. 推荐测试方式：
   - 方式 A（你当前可行）：iPad 的 Swift Playgrounds 人工测试
   - 方式 B（后续补齐）：Mac 上用 Xcode 跑自动测试与归档

## 2. 需要传到 iPad 的文件

只需要传 `WordMaster` 目录下的业务源码（`WordMasterTests` 不用传）：

1. [WordMasterApp.swift](/e:/Program/Word_Master/WordMaster/WordMasterApp.swift)
2. [App](/e:/Program/Word_Master/WordMaster/App)
3. [Core](/e:/Program/Word_Master/WordMaster/Core)
4. [Data](/e:/Program/Word_Master/WordMaster/Data)
5. [Features](/e:/Program/Word_Master/WordMaster/Features)
6. [Shared](/e:/Program/Word_Master/WordMaster/Shared)

## 3. 从 Windows 传文件到 iPad

推荐做法（最稳妥）：

1. 在 Windows 将 `e:\Program\Word_Master\WordMaster` 打包为 `WordMaster.zip`。
2. 上传到 iCloud Drive（或 AirDrop/微信文件传输助手）。
3. 在 iPad“文件”App 中解压 `WordMaster.zip`。

## 4. 在 iPad Swift Playgrounds 建项目并导入

1. 打开 Swift Playgrounds（iPad）。
2. 新建 `App` 项目（空白 App 即可）。
3. 在项目侧边栏中，按目录创建分组：`App/Core/Data/Features/Shared`。
4. 把 `WordMaster` 目录中的 `.swift` 文件逐个导入到对应分组。
5. 确保入口文件是 `WordMasterApp.swift`。

## 5. 测试前最小配置

1. 登录流程：可先用当前默认仓储（内存仓储）做 UI 流程验证。
2. 若要联通真实 Supabase：
   - 先按 [supabase-setup.md](/e:/Program/Word_Master/docs/supabase-setup.md) 建好项目、表与 RLS；
   - 再把 Auth/Word 仓储实现切到 Supabase SDK 版本（当前代码默认是内存仓储）。
3. DeepSeek 测试前，在“我的”页填入有效 API Key。

## 6. iPad 人工测试步骤（建议顺序）

1. 启动 App，输入账号密码登录。
2. 进入“添加”页：
   - 输入中文 -> 查询候选；
   - 点选候选保存；
   - 再测试手写英文保存。
3. 用相同英文再添加一次，确认“合并更新”提示。
4. 进入“复习”页：
   - 直接点卡片 => 进入下一阶段；
   - 点“英文翻译”后再点卡片 => 回退阶段1、次日复习。
5. 进入“库”页，确认中英文、阶段显示与删除可用。
6. 进入“统计”页，核对总量/进行中/逾期/已掌握与时间轴。
7. 进入“我的”页，测试 API Key 保存与退出登录。
8. 在 iPad 旋转横竖屏，检查页面状态不丢失。

## 7. 测试结果记录模板（建议）

每条记录：

1. 测试项（例如：复习-不会回退）
2. 预期结果
3. 实际结果
4. 是否通过（PASS/FAIL）
5. 截图路径（可选）

可把结果写回 `docs/testing-report.md`，便于后续发布签核。

