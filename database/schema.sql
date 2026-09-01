-- ============================================================
-- COGENT HEX INVENTORY SYSTEM
-- PostgreSQL / Supabase Database Schema
--
-- Version: 1.0
-- ============================================================


-- ============================================================
-- EXTENSIONS
-- ============================================================

create extension if not exists "pgcrypto";


-- ============================================================
-- ENUM TYPES
-- ============================================================

do $$
begin

    create type public.user_role as enum (
        'admin',
        'manager',
        'inventory_user'
    );

exception
    when duplicate_object then null;

end $$;


do $$
begin

    create type public.transaction_type as enum (
        'check_in',
        'check_out',
        'adjustment'
    );

exception
    when duplicate_object then null;

end $$;


-- ============================================================
-- USER PROFILES
--
-- Supabase authentication lives in auth.users.
-- This table stores application-specific information.
-- ============================================================

create table public.profiles (

    id uuid primary key
        references auth.users(id)
        on delete cascade,

    first_name text,

    last_name text,

    display_name text,

    role public.user_role
        not null default 'inventory_user',

    employee_number text,

    department text,

    phone text,

    active boolean
        not null default true,

    created_at timestamptz
        not null default now(),

    updated_at timestamptz
        not null default now()

);


create unique index profiles_employee_number_unique
on public.profiles(employee_number)
where employee_number is not null;


-- ============================================================
-- CATEGORIES
--
-- Examples:
--
-- Electrical
-- Networking
-- Controls
-- Wiring
-- Thermal
-- Mechanical
-- Tools
-- Safety
-- ============================================================

create table public.categories (

    id uuid primary key
        default gen_random_uuid(),

    name text not null,

    description text,

    active boolean
        not null default true,

    created_at timestamptz
        not null default now(),

    updated_at timestamptz
        not null default now(),

    constraint categories_name_unique
        unique (name)

);


-- ============================================================
-- SUBCATEGORIES
--
-- Examples:
--
-- Electrical
--   Breakers
--   Relays
--   VFDs
--
-- Relays
--   Contact
--   Safety
-- ============================================================

create table public.subcategories (

    id uuid primary key
        default gen_random_uuid(),

    category_id uuid not null
        references public.categories(id)
        on delete restrict,

    name text not null,

    description text,

    active boolean
        not null default true,

    created_at timestamptz
        not null default now(),

    updated_at timestamptz
        not null default now(),

    constraint subcategories_category_name_unique
        unique (category_id, name)

);


-- ============================================================
-- VENDORS
--
-- Companies Cogent Hex purchases inventory from.
-- ============================================================

create table public.vendors (

    id uuid primary key
        default gen_random_uuid(),

    name text not null,

    account_number text,

    contact_name text,

    phone text,

    email text,

    website text,

    address_line_1 text,

    address_line_2 text,

    city text,

    state text,

    postal_code text,

    notes text,

    active boolean
        not null default true,

    created_at timestamptz
        not null default now(),

    updated_at timestamptz
        not null default now(),

    constraint vendors_name_unique
        unique (name)

);


-- ============================================================
-- STORAGE LOCATIONS
--
-- Allows locations such as:
--
-- Warehouse
-- Aisle 4
-- Rack 02
-- Shelf 03
-- Bin B
-- ============================================================

create table public.locations (

    id uuid primary key
        default gen_random_uuid(),

    name text not null,

    building text,

    area text,

    aisle text,

    rack text,

    shelf text,

    bin text,

    description text,

    active boolean
        not null default true,

    created_at timestamptz
        not null default now(),

    updated_at timestamptz
        not null default now()

);


create index locations_name_idx
on public.locations(name);


-- ============================================================
-- INVENTORY ITEMS
--
-- This represents a part/material that Cogent Hex keeps
-- in inventory.
-- ============================================================

create table public.inventory_items (

    id uuid primary key
        default gen_random_uuid(),

    -- Identification
    part_number text not null,

    barcode text,

    sku text,

    description text not null,

    -- Classification
    category_id uuid not null
        references public.categories(id)
        on delete restrict,

    subcategory_id uuid
        references public.subcategories(id)
        on delete restrict,

    -- Manufacturer information
    manufacturer text,

    manufacturer_part_number text,

    model_number text,

    -- Vendor information
    vendor_id uuid
        references public.vendors(id)
        on delete restrict,

    vendor_part_number text,

    -- Inventory information
    unit_of_measure text
        not null default 'each',

    quantity_on_hand numeric(12,2)
        not null default 0,

    minimum_quantity numeric(12,2)
        not null default 0,

    reorder_quantity numeric(12,2),

    -- Storage
    location_id uuid
        references public.locations(id)
        on delete restrict,

    -- Financial
    unit_cost numeric(12,2),

    -- Additional information
    notes text,

    image_url text,

    active boolean
        not null default true,

    created_at timestamptz
        not null default now(),

    updated_at timestamptz
        not null default now(),

    constraint inventory_items_part_number_unique
        unique (part_number),

    constraint inventory_items_quantity_check
        check (quantity_on_hand >= 0),

    constraint inventory_items_minimum_check
        check (minimum_quantity >= 0),

    constraint inventory_items_cost_check
        check (unit_cost is null or unit_cost >= 0)

);


-- ============================================================
-- ITEM ALTERNATE IDENTIFIERS
--
-- Useful when an item has multiple barcodes, manufacturer
-- numbers, legacy part numbers, etc.
-- ============================================================

create table public.item_identifiers (

    id uuid primary key
        default gen_random_uuid(),

    item_id uuid not null
        references public.inventory_items(id)
        on delete cascade,

    identifier text not null,

    identifier_type text
        not null default 'barcode',

    created_at timestamptz
        not null default now(),

    constraint item_identifier_unique
        unique (identifier)

);


-- ============================================================
-- JOBS / PROJECTS
--
-- Inventory can be checked out against a job or project.
--
-- Example:
--
-- Job 2471
-- Line 3
-- Panel Build
-- ============================================================

create table public.jobs (

    id uuid primary key
        default gen_random_uuid(),

    job_number text not null,

    name text,

    description text,

    customer text,

    status text
        not null default 'active',

    created_at timestamptz
        not null default now(),

    updated_at timestamptz
        not null default now(),

    constraint jobs_job_number_unique
        unique (job_number)

);


-- ============================================================
-- INVENTORY TRANSACTIONS
--
-- EVERY inventory movement is recorded here.
--
-- check_in
-- check_out
-- adjustment
--
-- This table creates the audit trail.
-- ============================================================

create table public.inventory_transactions (

    id uuid primary key
        default gen_random_uuid(),

    -- Item involved
    item_id uuid not null
        references public.inventory_items(id)
        on delete restrict,

    -- User who performed the transaction
    user_id uuid
        references public.profiles(id)
        on delete restrict,

    -- Transaction type
    transaction_type public.transaction_type
        not null,

    -- Quantity moved
    quantity numeric(12,2)
        not null,

    -- Inventory state before transaction
    quantity_before numeric(12,2)
        not null,

    -- Inventory state after transaction
    quantity_after numeric(12,2)
        not null,

    -- Optional job/project
    job_id uuid
        references public.jobs(id)
        on delete restrict,

    -- Free-text job number for flexibility
    job_number text,

    -- Where the item went
    destination text,

    -- Location associated with transaction
    location_id uuid
        references public.locations(id)
        on delete restrict,

    -- Purchase order / reference
    reference_number text,

    -- Notes
    notes text,

    created_at timestamptz
        not null default now(),

    constraint transaction_quantity_positive
        check (quantity > 0),

    constraint transaction_quantity_before_valid
        check (quantity_before >= 0),

    constraint transaction_quantity_after_valid
        check (quantity_after >= 0)

);


-- ============================================================
-- INVENTORY ADJUSTMENTS
--
-- Used for physical inventory counts or corrections.
--
-- Example:
--
-- System says 14
-- Physical count says 13
-- Adjustment = -1
-- ============================================================

create table public.inventory_adjustments (

    id uuid primary key
        default gen_random_uuid(),

    item_id uuid not null
        references public.inventory_items(id)
        on delete restrict,

    user_id uuid
        references public.profiles(id)
        on delete restrict,

    system_quantity numeric(12,2)
        not null,

    counted_quantity numeric(12,2)
        not null,

    adjustment_quantity numeric(12,2)
        generated always as
        (counted_quantity - system_quantity)
        stored,

    reason text,

    created_at timestamptz
        not null default now(),

    constraint adjustment_system_quantity_valid
        check (system_quantity >= 0),

    constraint adjustment_counted_quantity_valid
        check (counted_quantity >= 0)

);


-- ============================================================
-- PURCHASE ORDERS
--
-- Optional foundation for receiving inventory.
-- ============================================================

create table public.purchase_orders (

    id uuid primary key
        default gen_random_uuid(),

    po_number text not null,

    vendor_id uuid
        references public.vendors(id)
        on delete restrict,

    status text
        not null default 'open',

    order_date date,

    expected_date date,

    notes text,

    created_by uuid
        references public.profiles(id)
        on delete restrict,

    created_at timestamptz
        not null default now(),

    updated_at timestamptz
        not null default now(),

    constraint purchase_orders_po_number_unique
        unique (po_number)

);


-- ============================================================
-- PURCHASE ORDER ITEMS
-- ============================================================

create table public.purchase_order_items (

    id uuid primary key
        default gen_random_uuid(),

    purchase_order_id uuid not null
        references public.purchase_orders(id)
        on delete cascade,

    item_id uuid not null
        references public.inventory_items(id)
        on delete restrict,

    quantity_ordered numeric(12,2)
        not null,

    quantity_received numeric(12,2)
        not null default 0,

    unit_cost numeric(12,2),

    created_at timestamptz
        not null default now(),

    constraint po_quantity_ordered_valid
        check (quantity_ordered > 0),

    constraint po_quantity_received_valid
        check (quantity_received >= 0),

    constraint po_received_not_greater_than_ordered
        check (quantity_received <= quantity_ordered)

);


-- ============================================================
-- INDEXES
-- ============================================================

create index inventory_items_category_idx
on public.inventory_items(category_id);

create index inventory_items_subcategory_idx
on public.inventory_items(subcategory_id);

create index inventory_items_vendor_idx
on public.inventory_items(vendor_id);

create index inventory_items_location_idx
on public.inventory_items(location_id);

create index inventory_items_barcode_idx
on public.inventory_items(barcode);

create index inventory_items_description_idx
on public.inventory_items(description);

create index item_identifiers_item_idx
on public.item_identifiers(item_id);

create index inventory_transactions_item_idx
on public.inventory_transactions(item_id);

create index inventory_transactions_user_idx
on public.inventory_transactions(user_id);

create index inventory_transactions_job_idx
on public.inventory_transactions(job_id);

create index inventory_transactions_date_idx
on public.inventory_transactions(created_at);

create index inventory_transactions_type_idx
on public.inventory_transactions(transaction_type);

create index jobs_job_number_idx
on public.jobs(job_number);

create index purchase_orders_vendor_idx
on public.purchase_orders(vendor_id);

create index purchase_order_items_item_idx
on public.purchase_order_items(item_id);


-- ============================================================
-- UPDATED_AT FUNCTION
-- ============================================================

create or replace function public.update_updated_at()
returns trigger
language plpgsql
as $$
begin

    new.updated_at = now();

    return new;

end;
$$;


-- ============================================================
-- UPDATED_AT TRIGGERS
-- ============================================================

create trigger profiles_updated_at
before update on public.profiles
for each row
execute function public.update_updated_at();


create trigger categories_updated_at
before update on public.categories
for each row
execute function public.update_updated_at();


create trigger subcategories_updated_at
before update on public.subcategories
for each row
execute function public.update_updated_at();


create trigger vendors_updated_at
before update on public.vendors
for each row
execute function public.update_updated_at();


create trigger locations_updated_at
before update on public.locations
for each row
execute function public.update_updated_at();


create trigger inventory_items_updated_at
before update on public.inventory_items
for each row
execute function public.update_updated_at();


create trigger jobs_updated_at
before update on public.jobs
for each row
execute function public.update_updated_at();


create trigger purchase_orders_updated_at
before update on public.purchase_orders
for each row
execute function public.update_updated_at();


-- ============================================================
-- INVENTORY TRANSACTION FUNCTION
--
-- This is the important part.
--
-- When a transaction is inserted:
--
-- CHECK IN:
-- quantity_on_hand increases
--
-- CHECK OUT:
-- quantity_on_hand decreases
--
-- ADJUSTMENT:
-- quantity becomes the specified after quantity
-- ============================================================

create or replace function public.process_inventory_transaction()
returns trigger
language plpgsql
security definer
set search_path = public
as $$

declare

    current_quantity numeric(12,2);

    new_quantity numeric(12,2);

begin

    -- Lock the inventory row so two simultaneous scans
    -- cannot corrupt the quantity.

    select quantity_on_hand
    into current_quantity

    from public.inventory_items

    where id = new.item_id

    for update;


    if current_quantity is null then

        raise exception
            'Inventory item does not exist';

    end if;


    -- Store the quantity before the transaction.

    new.quantity_before = current_quantity;


    -- Determine the new quantity.

    if new.transaction_type = 'check_in' then

        new_quantity =
            current_quantity + new.quantity;


    elsif new.transaction_type = 'check_out' then

        new_quantity =
            current_quantity - new.quantity;


    elsif new.transaction_type = 'adjustment' then

        new_quantity =
            new.quantity_after;

    end if;


    -- Prevent inventory from going negative.

    if new_quantity < 0 then

        raise exception
            'Insufficient inventory. Available: %, Requested: %',
            current_quantity,
            new.quantity;

    end if;


    -- Store final quantity.

    new.quantity_after = new_quantity;


    -- Update inventory.

    update public.inventory_items

    set
        quantity_on_hand = new_quantity,
        updated_at = now()

    where id = new.item_id;


    return new;

end;
$$;


-- ============================================================
-- TRANSACTION TRIGGER
-- ============================================================

create trigger process_inventory_transaction_trigger

before insert on public.inventory_transactions

for each row

execute function public.process_inventory_transaction();


-- ============================================================
-- HELPER FUNCTION
--
-- Returns whether an item is below minimum stock.
-- ============================================================

create or replace function public.is_low_stock(
    item_id uuid
)

returns boolean

language sql
stable
security definer
set search_path = public

as $$

    select
        quantity_on_hand <= minimum_quantity

    from public.inventory_items

    where id = item_id;

$$;


-- ============================================================
-- INITIAL CATEGORIES
-- ============================================================

insert into public.categories
    (name, description)

values

    (
        'Electrical',
        'Electrical power and control components'
    ),

    (
        'Networking',
        'Industrial networking and communication components'
    ),

    (
        'Controls',
        'PLC, I/O, control system and automation components'
    ),

    (
        'Wiring',
        'Wire, cable, cord and wiring accessories'
    ),

    (
        'Thermal',
        'Heat sinks, thermal management and related components'
    ),

    (
        'Mechanical',
        'Mechanical hardware and components'
    ),

    (
        'Tools',
        'Tools and shop equipment'
    ),

    (
        'Safety',
        'Safety equipment and safety system components'
    )

on conflict (name)
do nothing;


-- ============================================================
-- INITIAL ELECTRICAL SUBCATEGORIES
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
            'Circuit breakers and protection devices'
        ),

        (
            'Relays',
            'Industrial relays and relay components'
        ),

        (
            'Contactors',
            'Contactors and motor switching devices'
        ),

        (
            'VFDs',
            'Variable frequency drives'
        ),

        (
            'Power Supplies',
            'Industrial DC and AC power supplies'
        ),

        (
            'Transformers',
            'Control and power transformers'
        )

) as v(name, description)

where c.name = 'Electrical'

on conflict (category_id, name)
do nothing;


-- ============================================================
-- INITIAL RELAY SUBCATEGORIES
--
-- These are intentionally kept under Relays as a naming
-- convention for future expansion if desired.
-- ============================================================

-- ============================================================
-- INITIAL NETWORKING SUBCATEGORIES
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
            'Ethernet',
            'Industrial Ethernet cable and components'
        ),

        (
            'Splitters',
            'Network splitters and distribution components'
        ),

        (
            'Connectors',
            'Network connectors and terminations'
        ),

        (
            'Switches',
            'Industrial Ethernet switches'
        )

) as v(name, description)

where c.name = 'Networking'

on conflict (category_id, name)
do nothing;


-- ============================================================
-- INITIAL WIRING SUBCATEGORIES
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
            'Control Cable',
            'Industrial control and signal cable'
        ),

        (
            'Ethernet Cable',
            'Industrial Ethernet cable'
        ),

        (
            'Wire',
            'General electrical wire'
        ),

        (
            'Cable Accessories',
            'Cable glands, ties and accessories'
        )

) as v(name, description)

where c.name = 'Wiring'

on conflict (category_id, name)
do nothing;


-- ============================================================
-- INITIAL THERMAL SUBCATEGORIES
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
            'Aluminum and other thermal heat sinks'
        ),

        (
            'Thermal Interface',
            'Thermal pads, compounds and interface materials'
        ),

        (
            'Fans',
            'Cooling fans and accessories'
        )

) as v(name, description)

where c.name = 'Thermal'

on conflict (category_id, name)
do nothing;


-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.profiles
enable row level security;

alter table public.categories
enable row level security;

alter table public.subcategories
enable row level security;

alter table public.vendors
enable row level security;

alter table public.locations
enable row level security;

alter table public.inventory_items
enable row level security;

alter table public.item_identifiers
enable row level security;

alter table public.jobs
enable row level security;

alter table public.inventory_transactions
enable row level security;

alter table public.inventory_adjustments
enable row level security;

alter table public.purchase_orders
enable row level security;

alter table public.purchase_order_items
enable row level security;


-- ============================================================
-- HELPER: CURRENT USER ROLE
-- ============================================================

create or replace function public.current_user_role()

returns public.user_role

language sql
stable
security definer
set search_path = public

as $$

    select role

    from public.profiles

    where id = auth.uid()

    and active = true

    limit 1;

$$;


-- ============================================================
-- PROFILE POLICIES
-- ============================================================

create policy "Users can view their own profile"

on public.profiles

for select

to authenticated

using (
    id = auth.uid()
);


create policy "Admins can view all profiles"

on public.profiles

for select

to authenticated

using (
    public.current_user_role() = 'admin'
);


create policy "Admins can update profiles"

on public.profiles

for update

to authenticated

using (
    public.current_user_role() = 'admin'
)

with check (
    public.current_user_role() = 'admin'
);


-- ============================================================
-- CATEGORY POLICIES
-- ============================================================

create policy "Authenticated users can view categories"

on public.categories

for select

to authenticated

using (active = true);


create policy "Managers can manage categories"

on public.categories

for all

to authenticated

using (
    public.current_user_role()
    in ('admin', 'manager')
)

with check (
    public.current_user_role()
    in ('admin', 'manager')
);


-- ============================================================
-- SUBCATEGORY POLICIES
-- ============================================================

create policy "Authenticated users can view subcategories"

on public.subcategories

for select

to authenticated

using (active = true);


create policy "Managers can manage subcategories"

on public.subcategories

for all

to authenticated

using (
    public.current_user_role()
    in ('admin', 'manager')
)

with check (
    public.current_user_role()
    in ('admin', 'manager')
);


-- ============================================================
-- VENDOR POLICIES
-- ============================================================

create policy "Authenticated users can view vendors"

on public.vendors

for select

to authenticated

using (active = true);


create policy "Managers can manage vendors"

on public.vendors

for all

to authenticated

using (
    public.current_user_role()
    in ('admin', 'manager')
)

with check (
    public.current_user_role()
    in ('admin', 'manager')
);


-- ============================================================
-- LOCATION POLICIES
-- ============================================================

create policy "Authenticated users can view locations"

on public.locations

for select

to authenticated

using (active = true);


create policy "Managers can manage locations"

on public.locations

for all

to authenticated

using (
    public.current_user_role()
    in ('admin', 'manager')
)

with check (
    public.current_user_role()
    in ('admin', 'manager')
);


-- ============================================================
-- INVENTORY POLICIES
-- ============================================================

create policy "Authenticated users can view inventory"

on public.inventory_items

for select

to authenticated

using (active = true);


create policy "Managers can manage inventory"

on public.inventory_items

for all

to authenticated

using (
    public.current_user_role()
    in ('admin', 'manager')
)

with check (
    public.current_user_role()
    in ('admin', 'manager')
);


-- ============================================================
-- IDENTIFIER POLICIES
-- ============================================================

create policy "Authenticated users can view item identifiers"

on public.item_identifiers

for select

to authenticated

using (true);


create policy "Managers can manage item identifiers"

on public.item_identifiers

for all

to authenticated

using (
    public.current_user_role()
    in ('admin', 'manager')
)

with check (
    public.current_user_role()
    in ('admin', 'manager')
);


-- ============================================================
-- JOB POLICIES
-- ============================================================

create policy "Authenticated users can view jobs"

on public.jobs

for select

to authenticated

using (true);


create policy "Managers can manage jobs"

on public.jobs

for all

to authenticated

using (
    public.current_user_role()
    in ('admin', 'manager')
)

with check (
    public.current_user_role()
    in ('admin', 'manager')
);


-- ============================================================
-- TRANSACTION POLICIES
-- ============================================================

create policy "Authenticated users can view transactions"

on public.inventory_transactions

for select

to authenticated

using (true);


create policy "Authenticated users can create transactions"

on public.inventory_transactions

for insert

to authenticated

with check (
    user_id = auth.uid()
);


-- ============================================================
-- ADJUSTMENT POLICIES
-- ============================================================

create policy "Managers can view adjustments"

on public.inventory_adjustments

for select

to authenticated

using (
    public.current_user_role()
    in ('admin', 'manager')
);


create policy "Managers can create adjustments"

on public.inventory_adjustments

for insert

to authenticated

with check (
    user_id = auth.uid()
    and
    public.current_user_role()
    in ('admin', 'manager')
);


-- ============================================================
-- PURCHASE ORDER POLICIES
-- ============================================================

create policy "Authenticated users can view purchase orders"

on public.purchase_orders

for select

to authenticated

using (true);


create policy "Managers can manage purchase orders"

on public.purchase_orders

for all

to authenticated

using (
    public.current_user_role()
    in ('admin', 'manager')
)

with check (
    public.current_user_role()
    in ('admin', 'manager')
);


create policy "Authenticated users can view purchase order items"

on public.purchase_order_items

for select

to authenticated

using (true);


create policy "Managers can manage purchase order items"

on public.purchase_order_items

for all

to authenticated

using (
    public.current_user_role()
    in ('admin', 'manager')
)

with check (
    public.current_user_role()
    in ('admin', 'manager')
);


-- ============================================================
-- END OF SCHEMA
-- ============================================================