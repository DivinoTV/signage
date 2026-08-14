-- Zone seed (brief v2.1 §2.6). Re-runnable.
--
-- PROPERTY LIST corrected 2026-08-12 by the owner. The brief's §2.6 list was wrong.
--   brief said: caldera, gili-air, divino-suites, kanzen-santorini, kanzen-gili-air, oniro
--   actual:     divino-caldera, divino-gili-air, kanzen-gili-air, oniro
-- Four properties, not six. Only divino-gili-air is operating so far; the other three are
-- left commented out below and go live by uncommenting their block.
--
-- Adding a property or a category later is an insert here — no migration, no code change,
-- no TV change (§2.10 FP2/FP3).
--
-- NOTE: the admin panel builds its property dropdown from THIS table. A property with no
-- rows here does not appear in the admin at all, which is why the three that are not yet
-- operating are deliberately absent rather than seeded empty.
--
-- The `label` is what the operator sees and can be changed freely at any time.
-- The `slug` goes into the TV's bookmarked URL as &type= and must NOT change once TVs
-- are provisioned (§2.10).

insert into public.zones (property, slug, label, sort_order) values

  -- ── Divino Gili Air — currently the only operating property ──────────────
  ('divino-gili-air', 'deluxe',       'Deluxe',       1),
  ('divino-gili-air', 'junior-suite', 'Junior Suite', 2),
  ('divino-gili-air', 'king-suite',   'King Suite',   3),
  ('divino-gili-air', 'superior',     'Superior',     4)

  -- ── Divino Caldera — not operating yet ───────────────────────────────────
  -- ,('divino-caldera', 'deluxe', 'Deluxe', 1)

  -- ── Kanzen Gili Air — not operating yet ──────────────────────────────────
  -- ,('kanzen-gili-air', 'deluxe', 'Deluxe', 1)

  -- ── Oniro — not operating yet ────────────────────────────────────────────
  -- ,('oniro', 'deluxe', 'Deluxe', 1)

on conflict (property, slug) do nothing;

-- Check what landed:
select property, slug, label, sort_order
from public.zones
order by property, sort_order;
