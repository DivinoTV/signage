-- RLS — the ONLY security layer (brief v2.1 §2.7). Re-runnable.
-- After running this: verify with docs/SECURITY-CHECKLIST (§4.3). Any passing write = wide open.

alter table public.assets enable row level security;
alter table public.zones  enable row level security;

drop policy if exists "anon reads active assets"     on public.assets;
drop policy if exists "authenticated manages assets" on public.assets;

create policy "anon reads active assets"
  on public.assets for select to anon
  using (is_active = true);

create policy "authenticated manages assets"
  on public.assets for all to authenticated
  using (true) with check (true);

-- zones is admin-only; the TV never reads it (§2.10 FP3 — shape validation, not membership)
drop policy if exists "authenticated manages zones" on public.zones;

create policy "authenticated manages zones"
  on public.zones for all to authenticated
  using (true) with check (true);

-- Storage bucket `signage` — create it as PUBLIC READ in the dashboard first.
drop policy if exists "public reads signage"        on storage.objects;
drop policy if exists "authenticated uploads signage" on storage.objects;
drop policy if exists "authenticated deletes signage" on storage.objects;

create policy "public reads signage"
  on storage.objects for select to anon
  using (bucket_id = 'signage');

create policy "authenticated uploads signage"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'signage');

create policy "authenticated deletes signage"
  on storage.objects for delete to authenticated
  using (bucket_id = 'signage');

-- NOT DONE BY THIS FILE, and not optional:
--   1. Disable public signup (Auth -> Providers -> Email -> disable "Allow new users to sign up").
--      Left open, anyone registers, gets `authenticated`, and passes every write policy above.
--   2. Create the admin user manually from the dashboard.
