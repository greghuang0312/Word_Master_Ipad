# Word Master - Supabase 配置指南

更新时间：2026-03-11  
适用范围：Word Master V1（iPadOS，账号密码登录，不开放注册）

## 1. 创建项目

1. 登录 Supabase 控制台，创建新项目。
2. 在 `Project Settings -> API` 记录：
   - `Project URL`
   - `anon public key`（客户端可用）
   - `service_role key`（仅后台管理脚本可用，禁止放进 iPad 客户端）
3. 在本地或 CI 配置环境变量：
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

## 2. Auth 配置（仅登录，不注册）

1. 打开 `Authentication -> Providers`，启用 `Email`。
2. 在 Auth 设置中关闭公开注册（仅管理员可创建用户）。
3. 登录策略：客户端只保留登录入口，不提供注册按钮。

## 3. 账号预建（管理员）

推荐方式：在 Dashboard `Authentication -> Users` 手工创建学生账号。  
批量方式：使用 Admin API 创建（后台脚本执行，使用 `service_role`）。

建议字段：

1. `email`
2. `password`（初始密码）
3. `email_confirm = true`（避免确认邮件流程）

### 3.1 Dashboard 手工创建账号（推荐）

1. 进入 `Authentication -> Users`。
2. 点击 `Add user`。
3. 填写：
   - `Email`：学生邮箱（例如 `s001@school.local`）
   - `Password`：初始密码
4. 勾选或设置 `Auto Confirm User`（等价于 `email_confirm=true`）。
5. 保存后，用该账号在 App 登录验证。

### 3.2 Admin API 批量创建账号（可选）

仅在后端/管理员脚本使用，**禁止**在 iPad 客户端中使用 `service_role key`。

```bash
curl -X POST "https://<PROJECT-REF>.supabase.co/auth/v1/admin/users" \
  -H "apikey: <SERVICE_ROLE_KEY>" \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "s001@school.local",
    "password": "InitPass#2026",
    "email_confirm": true
  }'
```

批量创建时建议：

1. 先准备账号清单（CSV/JSON）。
2. 逐条调用 Admin API 并记录成功/失败日志。
3. 完成后抽测 2-3 个账号登录。

## 4. 数据表 SQL

在 `SQL Editor` 执行：

```sql
create extension if not exists pgcrypto;

create table if not exists public.words (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  zh_text text not null,
  en_word text not null,
  stage smallint not null default 1 check (stage between 1 and 6),
  next_review_date date not null,
  is_mastered boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, en_word)
);

create table if not exists public.review_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  word_id uuid not null references public.words(id) on delete cascade,
  result text not null check (result in ('known', 'unknown')),
  from_stage smallint not null,
  to_stage smallint not null,
  reviewed_at timestamptz not null default now(),
  next_review_date date not null
);

create table if not exists public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  llm_provider text not null default 'deepseek',
  deepseek_api_key text,
  updated_at timestamptz not null default now()
);

create index if not exists idx_words_user_review_date on public.words(user_id, next_review_date);
create index if not exists idx_words_user_stage on public.words(user_id, stage);
create index if not exists idx_logs_user_reviewed_at on public.review_logs(user_id, reviewed_at desc);
```

## 5. RLS 策略（用户数据隔离）

```sql
alter table public.words enable row level security;
alter table public.review_logs enable row level security;
alter table public.user_settings enable row level security;

create policy words_select_own on public.words
for select to authenticated
using ((select auth.uid()) = user_id);

create policy words_insert_own on public.words
for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy words_update_own on public.words
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy words_delete_own on public.words
for delete to authenticated
using ((select auth.uid()) = user_id);

create policy logs_select_own on public.review_logs
for select to authenticated
using ((select auth.uid()) = user_id);

create policy logs_insert_own on public.review_logs
for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy settings_select_own on public.user_settings
for select to authenticated
using ((select auth.uid()) = user_id);

create policy settings_insert_own on public.user_settings
for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy settings_update_own on public.user_settings
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
```

## 6. 业务规则落库口径

1. 队列查询：`next_review_date <= today`
2. 会（known）：阶段 +1（上限 6）
3. 不会（unknown）：回退阶段 1，`next_review_date = tomorrow`
4. 新词保存：阶段 1，首次复习日期为明天
5. 重复英文（同 user）：执行 upsert 合并更新，不新增重复记录

## 7. 客户端安全建议

1. 客户端只使用 `anon key`
2. `service_role key` 仅用于后台管理
3. API Key（DeepSeek）优先存 Keychain；若同步到云端需先加密

## 8. 常见排错

1. 登录失败（401）：
   - 检查 Email Provider 是否启用
   - 检查是否误关了登录能力
2. 查询为空：
   - 检查 RLS 是否开启且 policy 正确
   - 检查 token 对应 `auth.uid()` 是否与 `user_id` 一致
3. 写入失败（42501 权限不足）：
   - 检查 `insert/update` 的 `with check` 条件
4. 数据串读风险：
   - 全面检查是否存在 `using true` 之类过宽策略

## 9. 上线前核对清单

1. [ ] 公开注册已关闭
2. [ ] 学生账号已预创建
3. [ ] 三张表与索引已创建
4. [ ] RLS 策略已启用并验证
5. [ ] 客户端仅持有 `anon key`
6. [ ] `service_role key` 未进入客户端包体
7. [ ] 随机抽测 2 个账号，验证互相不可见
