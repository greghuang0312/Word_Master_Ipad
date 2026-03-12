-- Word Master / Step 4
-- Supabase SQL Editor: run once (safe to re-run)

begin;

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

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

create index if not exists idx_words_user_review_date
  on public.words(user_id, next_review_date);

create index if not exists idx_words_user_stage
  on public.words(user_id, stage);

create index if not exists idx_logs_user_reviewed_at
  on public.review_logs(user_id, reviewed_at desc);

drop trigger if exists trg_words_set_updated_at on public.words;
create trigger trg_words_set_updated_at
before update on public.words
for each row execute function public.set_updated_at();

drop trigger if exists trg_user_settings_set_updated_at on public.user_settings;
create trigger trg_user_settings_set_updated_at
before update on public.user_settings
for each row execute function public.set_updated_at();

commit;
