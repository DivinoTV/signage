-- Multi-Property TV Signage — schema (brief v2.1 §2.6)
-- Run first, before policies.sql and seed-zones.sql.

create table if not exists public.zones (
  property   text not null,
  slug       text not null,
  label      text not null,
  sort_order int  not null default 0,
  primary key (property, slug)
);

create table if not exists public.assets (
  id               uuid primary key default gen_random_uuid(),
  property         text not null,
  zone             text,
  media_url        text not null,
  media_type       text not null,
  duration_seconds int  not null default 8,
  sort_order       int  not null default 0,
  is_active        boolean not null default true,
  starts_at        timestamptz,
  ends_at          timestamptz,
  meta             jsonb not null default '{}'::jsonb,
  created_at       timestamptz not null default now(),

  constraint media_type_valid
    check (media_type in ('image', 'video')),

  -- MATCH SIMPLE: zone = NULL satisfies the FK automatically.
  -- That IS the inheritance rule — NULL means "everywhere in this property".
  constraint zone_fk foreign key (property, zone)
    references public.zones (property, slug)
);

create index if not exists assets_lookup_idx
  on public.assets (property, zone, sort_order)
  where is_active;

-- Enabled here, not only in policies.sql, so this file is fail-closed on its own.
-- RLS on with no policies denies everything to anon and authenticated; policies.sql
-- then opens exactly the access that is needed. Running this again is harmless.
-- Without it, the tables sit publicly readable AND writable in the gap between
-- running this file and running policies.sql.
alter table public.zones  enable row level security;
alter table public.assets enable row level security;
