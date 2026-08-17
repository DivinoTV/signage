-- Realtime (M6). Run this AFTER schema.sql and policies.sql. Re-runnable.
--
-- Not in the brief, but required. Without it the channel still joins and reports
-- status=ok, then the server sends a `system` message saying:
--
--   "Unable to subscribe to changes with given parameters.
--    Please check Realtime is enabled for the given connect parameters"
--
-- ...and no change ever arrives. Verified against the live project 2026-08-14 before
-- writing any client code. A silent non-delivery on a screen nobody watches is exactly
-- the failure §2.8 warns about, so it is worth knowing this is the cause.

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename  = 'assets'
  ) then
    alter publication supabase_realtime add table public.assets;
  end if;
end $$;

-- `zones` is deliberately NOT added. The TV never reads it (§2.10 FP3), so a change
-- there is nothing for a TV to react to.

-- Check what landed:
select schemaname, tablename
from pg_publication_tables
where pubname = 'supabase_realtime'
order by tablename;
