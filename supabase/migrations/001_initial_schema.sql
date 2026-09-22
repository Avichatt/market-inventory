-- =========================================================
-- MARKET INVENTORY MANAGEMENT SYSTEM
-- Initial Database Schema
-- =========================================================

-- =========================================================
-- 1. CATEGORIES
-- =========================================================

create table public.categories (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    description text,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);


-- =========================================================
-- 2. LOCATIONS
-- =========================================================

create table public.locations (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    city text,
    district text,
    state text,
    pincode text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);


-- =========================================================
-- 3. RETAILERS
-- =========================================================

create table public.retailers (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    phone text,
    address text,
    location_id uuid references public.locations(id),
    latitude numeric(10, 7),
    longitude numeric(10, 7),
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);


-- =========================================================
-- 4. FOS
-- Field Officer / Field Sales Officer
-- =========================================================

create table public.fos (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    phone text,
    email text,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);


-- =========================================================
-- 5. PRODUCTS
-- =========================================================

create table public.products (
    id uuid primary key default gen_random_uuid(),

    sku text not null unique,

    name text not null,

    category_id uuid references public.categories(id),

    hsn_code text,

    unit text not null default 'PCS',

    purchase_price numeric(12, 2) not null default 0,

    selling_price numeric(12, 2) not null default 0,

    mrp numeric(12, 2) not null default 0,

    minimum_stock numeric(12, 3) not null default 0,

    is_active boolean not null default true,

    created_at timestamptz not null default now(),

    updated_at timestamptz not null default now()
);


-- =========================================================
-- 6. MARKET VISITS
-- =========================================================

create table public.market_visits (
    id uuid primary key default gen_random_uuid(),

    retailer_id uuid not null
        references public.retailers(id),

    fos_id uuid not null
        references public.fos(id),

    visit_date date not null default current_date,

    visit_time timestamptz not null default now(),

    latitude numeric(10, 7),

    longitude numeric(10, 7),

    status text not null default 'DRAFT'
        check (
            status in (
                'DRAFT',
                'SUBMITTED',
                'CONFIRMED',
                'CANCELLED'
            )
        ),

    notes text,

    created_at timestamptz not null default now(),

    updated_at timestamptz not null default now()
);


-- =========================================================
-- 7. MARKET VISIT ITEMS
-- =========================================================

create table public.visit_items (
    id uuid primary key default gen_random_uuid(),

    visit_id uuid not null
        references public.market_visits(id)
        on delete cascade,

    product_id uuid not null
        references public.products(id),

    quantity numeric(12, 3) not null
        check (quantity > 0),

    unit_price numeric(12, 2) not null default 0,

    total_value numeric(14, 2)
        generated always as (quantity * unit_price) stored,

    created_at timestamptz not null default now()
);


-- =========================================================
-- 8. STOCK TRANSACTIONS
-- =========================================================

create table public.stock_transactions (
    id uuid primary key default gen_random_uuid(),

    product_id uuid not null
        references public.products(id),

    transaction_type text not null
        check (
            transaction_type in (
                'IN',
                'OUT',
                'ADJUSTMENT'
            )
        ),

    quantity numeric(12, 3) not null
        check (quantity <> 0),

    reference_type text,

    reference_id uuid,

    notes text,

    created_at timestamptz not null default now()
);


-- =========================================================
-- 9. INDEXES
-- =========================================================

create index idx_products_category
    on public.products(category_id);

create index idx_retailers_location
    on public.retailers(location_id);

create index idx_market_visits_retailer
    on public.market_visits(retailer_id);

create index idx_market_visits_fos
    on public.market_visits(fos_id);

create index idx_market_visits_date
    on public.market_visits(visit_date);

create index idx_visit_items_visit
    on public.visit_items(visit_id);

create index idx_visit_items_product
    on public.visit_items(product_id);

create index idx_stock_transactions_product
    on public.stock_transactions(product_id);

create index idx_stock_transactions_created_at
    on public.stock_transactions(created_at);


-- =========================================================
-- 10. CURRENT STOCK VIEW
-- =========================================================

create view public.current_inventory as

select
    p.id as product_id,
    p.sku,
    p.name as product_name,
    p.category_id,
    p.hsn_code,
    p.unit,
    p.purchase_price,
    p.selling_price,
    p.mrp,
    p.minimum_stock,

    coalesce(
        sum(
            case
                when st.transaction_type = 'IN'
                    then st.quantity

                when st.transaction_type = 'OUT'
                    then -st.quantity

                when st.transaction_type = 'ADJUSTMENT'
                    then st.quantity

                else 0
            end
        ),
        0
    ) as current_stock

from public.products p

left join public.stock_transactions st
    on st.product_id = p.id

group by
    p.id,
    p.sku,
    p.name,
    p.category_id,
    p.hsn_code,
    p.unit,
    p.purchase_price,
    p.selling_price,
    p.mrp,
    p.minimum_stock;