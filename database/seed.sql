-- ============================================================
-- COGENT HEX INVENTORY SYSTEM
-- INITIAL SEED DATA
--
-- This file adds the initial inventory classification.
-- Categories and subcategories can be added later without
-- changing the database structure.
-- ============================================================


-- ============================================================
-- TOP-LEVEL CATEGORIES
-- ============================================================

insert into public.categories (name, description)
values
    (
        'Electrical',
        'Electrical power and control components'
    ),
    (
        'Wiring',
        'Wire, cable and cord products'
    ),
    (
        'Networking',
        'Industrial networking and communication components'
    ),
    (
        'Thermal',
        'Heat management and cooling components'
    )
on conflict (name) do nothing;


-- ============================================================
-- ELECTRICAL SUBCATEGORIES
-- ============================================================

insert into public.subcategories
    (category_id, name, description)

select
    c.id,
    v.name,
    v.description

from public.categories c

cross join (
    values
        (
            'Breakers',
            'Circuit breakers and electrical protection devices'
        ),
        (
            'Contact Relays',
            'Contact relays and related control relay components'
        ),
        (
            'Safety Relays',
            'Safety-rated relays and safety control components'
        ),
        (
            'VFDs',
            'Variable frequency drives'
        )
) as v(name, description)

where c.name = 'Electrical'

on conflict (category_id, name) do nothing;


-- ============================================================
-- WIRING SUBCATEGORIES
-- ============================================================

insert into public.subcategories
    (category_id, name, description)

select
    c.id,
    v.name,
    v.description

from public.categories c

cross join (
    values
        (
            'Tool Cord',
            'Portable tool and equipment cord'
        ),
        (
            'Ethernet',
            'Ethernet cable and related wiring'
        )
) as v(name, description)

where c.name = 'Wiring'

on conflict (category_id, name) do nothing;


-- ============================================================
-- NETWORKING SUBCATEGORIES
-- ============================================================

insert into public.subcategories
    (category_id, name, description)

select
    c.id,
    v.name,
    v.description

from public.categories c

cross join (
    values
        (
            'Splitters',
            'Network splitters and distribution components'
        )
) as v(name, description)

where c.name = 'Networking'

on conflict (category_id, name) do nothing;


-- ============================================================
-- THERMAL SUBCATEGORIES
-- ============================================================

insert into public.subcategories
    (category_id, name, description)

select
    c.id,
    v.name,
    v.description

from public.categories c

cross join (
    values
        (
            'Heat Sinks',
            'Heat sinks and thermal management components'
        )
) as v(name, description)

where c.name = 'Thermal'

on conflict (category_id, name) do nothing;


-- ============================================================
-- END OF INITIAL SEED DATA
--
-- Current classifications:
--
-- Electrical
--   ├── Breakers
--   ├── Contact Relays
--   ├── Safety Relays
--   └── VFDs
--
-- Wiring
--   ├── Tool Cord
--   └── Ethernet
--
-- Networking
--   └── Splitters
--
-- Thermal
--   └── Heat Sinks
--
-- Additional categories/subcategories can be added later.
-- ============================================================
