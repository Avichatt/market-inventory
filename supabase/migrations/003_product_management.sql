-- ============================================
-- 003 PRODUCT MANAGEMENT
-- ============================================

-- --------------------------------------------
-- CATEGORY VALIDATION
-- --------------------------------------------

alter table public.categories
    add constraint categories_name_not_empty
    check (length(trim(name)) > 0);

-- Prevent duplicate category names
create unique index if not exists
    idx_categories_name_unique
on public.categories (lower(trim(name)));


-- --------------------------------------------
-- PRODUCT VALIDATION
-- --------------------------------------------

alter table public.products
    add constraint products_name_not_empty
    check (length(trim(name)) > 0);

alter table public.products
    add constraint products_purchase_price_non_negative
    check (purchase_price >= 0);

alter table public.products
    add constraint products_selling_price_non_negative
    check (selling_price >= 0);

alter table public.products
    add constraint products_mrp_non_negative
    check (mrp >= 0);

alter table public.products
    add constraint products_minimum_stock_non_negative
    check (minimum_stock >= 0);

alter table public.products
    add constraint products_sku_not_empty
    check (length(trim(sku)) > 0);


-- --------------------------------------------
-- PRODUCT INDEXES
-- --------------------------------------------

create index if not exists
    idx_products_name
on public.products (name);

create index if not exists
    idx_products_sku
on public.products (sku);

create index if not exists
    idx_products_hsn
on public.products (hsn_code);

create index if not exists
    idx_products_active
on public.products (is_active);


-- --------------------------------------------
-- UPDATED_AT TRIGGER
-- --------------------------------------------

drop trigger if exists update_products_updated_at
on public.products;

create trigger update_products_updated_at
    before update on public.products
    for each row
    execute function public.update_updated_at_column();


-- --------------------------------------------
-- UPDATED_AT FOR CATEGORIES
-- --------------------------------------------

drop trigger if exists update_categories_updated_at
on public.categories;

create trigger update_categories_updated_at
    before update on public.categories
    for each row
    execute function public.update_updated_at_column();


-- --------------------------------------------
-- UPDATED_AT FOR LOCATIONS
-- --------------------------------------------

drop trigger if exists update_locations_updated_at
on public.locations;

create trigger update_locations_updated_at
    before update on public.locations
    for each row
    execute function public.update_updated_at_column();


-- --------------------------------------------
-- UPDATED_AT FOR RETAILERS
-- --------------------------------------------

drop trigger if exists update_retailers_updated_at
on public.retailers;

create trigger update_retailers_updated_at
    before update on public.retailers
    for each row
    execute function public.update_updated_at_column();


-- --------------------------------------------
-- UPDATED_AT FOR FOS
-- --------------------------------------------

drop trigger if exists update_fos_updated_at
on public.fos;

create trigger update_fos_updated_at
    before update on public.fos
    for each row
    execute function public.update_updated_at_column();


-- --------------------------------------------
-- UPDATED_AT FOR MARKET VISITS
-- --------------------------------------------

drop trigger if exists update_market_visits_updated_at
on public.market_visits;

create trigger update_market_visits_updated_at
    before update on public.market_visits
    for each row
    execute function public.update_updated_at_column();