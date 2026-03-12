# Word Master 客户端接入执行手册（Windows -> iPad）

更新时间：2026-03-12

适用场景：Windows 环境只做开发与配置，最终在 iPad Swift Playgrounds 统一联调。

## 1. 目标

1. 后端（Supabase）已完成：Schema、RLS、隔离验证。
2. 客户端（iPad）联调前完成配置：Supabase key、DeepSeek key、验收脚本与检查清单。
3. 在 iPad 一次性完成登录、加词、复习、统计、我的全链路验证。

## 2. Windows 侧预配置（必须完成）

1. 校验 `.env` 关键字段：
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_PUBLISHABLE_KEY`
   - `SUPABASE_SECRET_KEY`（仅服务端/管理脚本）
2. 运行后端验收 SQL（Supabase SQL Editor）：
   - `docs/sql/step-04-schema.sql`
   - `docs/sql/step-05-rls.sql`
   - `docs/sql/step-01-final-audit.sql`
3. 运行隔离脚本：
   - `scripts/run-rls-check.cmd`
4. 管理接口验证（secret key）：
   - `Invoke-RestMethod ... /auth/v1/admin/users`
   - 必须使用非浏览器 `User-Agent`。
5. iPad 配置准备：
   - 在 `WordMaster/Data/Supabase/SupabaseLocalConfig.swift` 填写 `url` 和 `anonKey`
   - 不要填写 secret key

## 3. DeepSeek 接入与设置（客户端）

当前代码策略：

1. API Key 存储：Keychain（key: `deepseek_api_key`）。
2. 候选生成：`DeepSeekClient` 调用 `https://api.deepseek.com/chat/completions`。
3. 兜底策略：DeepSeek 失败时允许手写英文保存。
4. 新增能力：在“我的”页面可直接“测试 API Key”连通性。

关键代码：

1. `WordMaster/Data/LLM/DeepSeekSettings.swift`
2. `WordMaster/Data/LLM/DeepSeekClient.swift`
3. `WordMaster/Features/Profile/ProfileViewModel.swift`
4. `WordMaster/Features/Profile/ProfileView.swift`
5. `WordMaster/Features/Add/AddWordViewModel.swift`

## 4. iPad Swift Playgrounds 联调顺序

1. 导入项目源码后先登录（账号来自 Supabase Users）。
2. 打开“我的”页面：
   - 输入 DeepSeek API Key
   - 点击“测试”
   - 显示“DeepSeek 连接正常”再点击“保存”
3. 打开“添加”页面：
   - 输入中文词义并查询候选
   - 候选可选中保存
   - 再测手写英文保存（兜底）
4. 打开“复习”页面：
   - 不看英文直接点卡片 -> `known`
   - 点击“英文翻译”后再点卡片 -> `unknown`（回退阶段 1）
5. 打开“库/统计”页面，确认数据与阶段变化一致。
6. 切换账号复测，确认互相不可见（RLS 生效）。

## 5. 风险与判定

1. 若“测试 API Key”失败但手写可保存：DeepSeek 问题，不阻塞核心流程。
2. 若登录成功但数据为空：优先检查 RLS policy 与 `user_id`。
3. 发布前通过标准：
   - RLS 隔离脚本 PASS
   - API Key 测试 PASS
   - 五页主流程手工验证 PASS
