-- Realtime (M6). Run AFTER schema.sql and policies.sql. Re-runnable.
--
-- Two things are needed, and the second one is not obvious.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Put `assets` in the publication
-- ─────────────────────────────────────────────────────────────────────────────
-- Without this the channel joins, reports status=ok, and the server then sends
--   "Unable to subscribe to changes with given parameters"
-- ...and no change ever arrives. Verified against the live project 2026-08-14.

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'assets'
  ) then
    alter publication supabase_realtime add table public.assets;
  end if;
end $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. A change signal that survives RLS filtering
-- ─────────────────────────────────────────────────────────────────────────────
-- Realtime only delivers a change if the SUBSCRIBER is allowed to see the NEW row.
-- The anon policy is `using (is_active = true)`, so:
--
--   showing a slide  (false -> true)   new row visible    -> event delivered
--   hiding a slide   (true  -> false)  new row invisible  -> event SUPPRESSED
--
-- Measured on the live project 2026-08-17: showing a slide reached the TV in 1 second;
-- hiding it produced no event at all. The captured frame also shows
-- `old_record` carrying only `id` (default replica identity), so the old state cannot
-- rescue the check either.
--
-- That is backwards from what matters most. §5.6 makes `is_active = false` the emergency
-- kill switch for bad content and promises it "propagates in seconds".
--
-- Fixing it by loosening the anon SELECT policy was rejected: §4.3 requires that hidden
-- rows stay unreadable by the public, and that test is a release blocker.
--
-- So instead: one row holding a timestamp, always readable, bumped by a trigger on every
-- change to `assets`. The TV subscribes to THAT. The signal carries no content — it only
-- says "something changed, go refetch" — and the refetch runs under the same RLS as
-- always, so nothing is exposed. Being trigger-driven, it also catches changes made
-- straight from the SQL editor or the dashboard, not just from the admin panel.

create table if not exists public.revision (
  id        int primary key default 1,
  bumped_at timestamptz not null default now(),
  constraint revision_single_row check (id = 1)
);

insert into public.revision (id) values (1) on conflict (id) do nothing;

alter table public.revision enable row level security;

-- Readable by anyone; it is a bare timestamp. There is deliberately NO write policy —
-- the trigger below is `security definer`, so it is the only thing that can bump it.
drop policy if exists "anon reads revision" on public.revision;
create policy "anon reads revision"
  on public.revision for select to anon
  using (true);

drop policy if exists "authenticated reads revision" on public.revision;
create policy "authenticated reads revision"
  on public.revision for select to authenticated
  using (true);

create or replace function public.bump_revision() returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.revision set bumped_at = now() where id = 1;
  return null;
end $$;

-- FOR EACH STATEMENT, not FOR EACH ROW: a reorder rewriting many rows should bump once
-- per statement rather than once per row. The TV debounces anyway, but there is no reason
-- to generate the noise.
drop trigger if exists assets_bump_revision on public.assets;
create trigger assets_bump_revision
  after insert or update or delete on public.assets
  for each statement execute function public.bump_revision();

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'revision'
  ) then
    alter publication supabase_realtime add table public.revision;
  end if;
end $$;

-- `zones` is deliberately NOT published. The TV never reads it (§2.10 FP3), so a change
-- there is nothing for a TV to react to.

-- Check what landed:
select schemaname, tablename
from pg_publication_tables
where pubname = 'supabase_realtime'
order by tablename;
