-- ============================================
-- 004 PRODUCT CRUD FUNCTIONS
-- ============================================


-- --------------------------------------------
-- CHECK ADMIN / MANAGER ACCESS
-- --------------------------------------------

create or replace function public.can_manage_products()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
    return exists (
        select 1
        from public.profiles
        where id = auth.uid()
          and is_active = true
          and role in ('ADMIN', 'MANAGER')
    );
end;
$$;


-- --------------------------------------------
-- CREATE PRODUCT
-- --------------------------------------------

create or replace function public.create_product(
    p_sku text,
    p_name text,
    p_category_id uuid default null,
    p_hsn_code text default null,
    p_unit text default 'PCS',
    p_purchase_price numeric default 0,
    p_selling_price numeric default 0,
    p_mrp numeric default 0,
    p_minimum_stock numeric default 0
)
returns public.products
language plpgsql
security definer
set search_path = public
as $$
declare
    new_product public.products;
begin

    -- Permission check
    if not public.can_manage_products() then
        raise exception 'You do not have permission to create products';
    end if;

    -- Validate SKU
    if trim(coalesce(p_sku, '')) = '' then
        raise exception 'SKU is required';
    end if;

    -- Validate product name
    if trim(coalesce(p_name, '')) = '' then
        raise exception 'Product name is required';
    end if;

    -- Validate unit
    if trim(coalesce(p_unit, '')) = '' then
        raise exception 'Unit is required';
    end if;

    -- Validate numeric values
    if p_purchase_price < 0 then
        raise exception 'Purchase price cannot be negative';
    end if;

    if p_selling_price < 0 then
        raise exception 'Selling price cannot be negative';
    end if;

    if p_mrp < 0 then
        raise exception 'MRP cannot be negative';
    end if;

    if p_minimum_stock < 0 then
        raise exception 'Minimum stock cannot be negative';
    end if;

    -- Insert product
    insert into public.products (
        sku,
        name,
        category_id,
        hsn_code,
        unit,
        purchase_price,
        selling_price,
        mrp,
        minimum_stock
    )
    values (
        trim(p_sku),
        trim(p_name),
        p_category_id,
        nullif(trim(p_hsn_code), ''),
        upper(trim(p_unit)),
        p_purchase_price,
        p_selling_price,
        p_mrp,
        p_minimum_stock
    )
    returning *
    into new_product;

    return new_product;

exception
    when unique_violation then
        raise exception 'A product with SKU "%" already exists', p_sku;
end;
$$;


-- --------------------------------------------
-- UPDATE PRODUCT
-- --------------------------------------------

create or replace function public.update_product(
    p_product_id uuid,
    p_sku text,
    p_name text,
    p_category_id uuid default null,
    p_hsn_code text default null,
    p_unit text default 'PCS',
    p_purchase_price numeric default 0,
    p_selling_price numeric default 0,
    p_mrp numeric default 0,
    p_minimum_stock numeric default 0
)
returns public.products
language plpgsql
security definer
set search_path = public
as $$
declare
    updated_product public.products;
begin

    -- Permission check
    if not public.can_manage_products() then
        raise exception 'You do not have permission to update products';
    end if;

    -- Validate product ID
    if p_product_id is null then
        raise exception 'Product ID is required';
    end if;

    -- Validate SKU
    if trim(coalesce(p_sku, '')) = '' then
        raise exception 'SKU is required';
    end if;

    -- Validate product name
    if trim(coalesce(p_name, '')) = '' then
        raise exception 'Product name is required';
    end if;

    -- Validate unit
    if trim(coalesce(p_unit, '')) = '' then
        raise exception 'Unit is required';
    end if;

    -- Validate numeric values
    if p_purchase_price < 0 then
        raise exception 'Purchase price cannot be negative';
    end if;

    if p_selling_price < 0 then
        raise exception 'Selling price cannot be negative';
    end if;

    if p_mrp < 0 then
        raise exception 'MRP cannot be negative';
    end if;

    if p_minimum_stock < 0 then
        raise exception 'Minimum stock cannot be negative';
    end if;

    -- Update product
    update public.products
    set
        sku = trim(p_sku),
        name = trim(p_name),
        category_id = p_category_id,
        hsn_code = nullif(trim(p_hsn_code), ''),
        unit = upper(trim(p_unit)),
        purchase_price = p_purchase_price,
        selling_price = p_selling_price,
        mrp = p_mrp,
        minimum_stock = p_minimum_stock
    where id = p_product_id
    returning *
    into updated_product;

    if updated_product.id is null then
        raise exception 'Product not found';
    end if;

    return updated_product;

exception
    when unique_violation then
        raise exception 'A product with SKU "%" already exists', p_sku;
end;
$$;


-- --------------------------------------------
-- DEACTIVATE PRODUCT
-- --------------------------------------------

create or replace function public.deactivate_product(
    p_product_id uuid
)
returns public.products
language plpgsql
security definer
set search_path = public
as $$
declare
    deactivated_product public.products;
begin

    -- Permission check
    if not public.can_manage_products() then
        raise exception 'You do not have permission to deactivate products';
    end if;

    if p_product_id is null then
        raise exception 'Product ID is required';
    end if;

    update public.products
    set
        is_active = false
    where id = p_product_id
    returning *
    into deactivated_product;

    if deactivated_product.id is null then
        raise exception 'Product not found';
    end if;

    return deactivated_product;
end;
$$;


-- --------------------------------------------
-- SECURITY
-- --------------------------------------------

revoke all on function public.can_manage_products()
from public;

revoke all on function public.create_product(
    text,
    text,
    uuid,
    text,
    text,
    numeric,
    numeric,
    numeric,
    numeric
)
from public;

revoke all on function public.update_product(
    uuid,
    text,
    text,
    uuid,
    text,
    text,
    numeric,
    numeric,
    numeric,
    numeric
)
from public;

revoke all on function public.deactivate_product(uuid)
from public;


grant execute on function public.can_manage_products()
to authenticated;

grant execute on function public.create_product(
    text,
    text,
    uuid,
    text,
    text,
    numeric,
    numeric,
    numeric,
    numeric
)
to authenticated;

grant execute on function public.update_product(
    uuid,
    text,
    text,
    uuid,
    text,
    text,
    numeric,
    numeric,
    numeric,
    numeric
)
to authenticated;

grant execute on function public.deactivate_product(uuid)
to authenticated;