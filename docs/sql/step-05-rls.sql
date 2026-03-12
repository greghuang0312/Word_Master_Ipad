-- Word Master / Step 5
-- Supabase SQL Editor: run once (safe to re-run)

begin;

-- Enable RLS
alter table if exists public.words enable row level security;
alter table if exists public.review_logs enable row level security;
alter table if exists public.user_settings enable row level security;

-- words policies
drop policy if exists words_select_own on public.words;
create policy words_select_own on public.words
for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists words_insert_own on public.words;
create policy words_insert_own on public.words
for insert to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists words_update_own on public.words;
create policy words_update_own on public.words
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists words_delete_own on public.words;
create policy words_delete_own on public.words
for delete to authenticated
using ((select auth.uid()) = user_id);

-- review_logs policies
drop policy if exists logs_select_own on public.review_logs;
create policy logs_select_own on public.review_logs
for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists logs_insert_own on public.review_logs;
create policy logs_insert_own on public.review_logs
for insert to authenticated
with check ((select auth.uid()) = user_id);

-- user_settings policies
drop policy if exists settings_select_own on public.user_settings;
create policy settings_select_own on public.user_settings
for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists settings_insert_own on public.user_settings;
create policy settings_insert_own on public.user_settings
for insert to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists settings_update_own on public.user_settings;
create policy settings_update_own on public.user_settings
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

commit;
