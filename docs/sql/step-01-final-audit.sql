-- Word Master / Step 1 Closure Audit
-- Purpose: final backend checks after schema + RLS + isolation verification.

-- 1) Tables + RLS status
select tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('words', 'review_logs', 'user_settings')
order by tablename;

-- 2) Indexes
select tablename, indexname
from pg_indexes
where schemaname = 'public'
  and tablename in ('words', 'review_logs', 'user_settings')
order by tablename, indexname;

-- 3) words unique constraint (user_id, en_word)
select conname, conrelid::regclass as table_name
from pg_constraint
where conrelid = 'public.words'::regclass
  and contype = 'u';

-- 4) Policies
select schemaname, tablename, policyname, cmd, roles
from pg_policies
where schemaname = 'public'
  and tablename in ('words', 'review_logs', 'user_settings')
order by tablename, policyname;

-- 5) updated_at triggers
select c.relname as table_name, t.tgname
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('words', 'user_settings')
  and not t.tgisinternal
order by c.relname, t.tgname;
