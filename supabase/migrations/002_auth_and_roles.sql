-- =========================================================
-- AUTHENTICATION & USER ROLES
-- =========================================================

-- =========================================================
-- 1. PROFILES
-- =========================================================

create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text,
    role text not null default 'VIEWER'
        check (
            role in (
                'ADMIN',
                'MANAGER',
                'FOS',
                'VIEWER'
            )
        ),
    fos_id uuid references public.fos(id),
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- =========================================================
-- 2. ENABLE ROW LEVEL SECURITY
-- =========================================================

alter table public.profiles enable row level security;

-- =========================================================
-- 3. PROFILE POLICIES
-- =========================================================

-- Users can view their own profile
create policy "Users can view own profile"
on public.profiles
for select
to authenticated
using (
    id = auth.uid()
);

-- =========================================================
-- 4. AUTOMATIC PROFILE CREATION
-- =========================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (
        id,
        full_name,
        role
    )
    values (
        new.id,
        coalesce(
            new.raw_user_meta_data ->> 'full_name',
            ''
        ),
        'VIEWER'
    );

    return new;
end;
$$;

-- =========================================================
-- 5. CREATE AUTH USER TRIGGER
-- =========================================================

create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function public.handle_new_user();

-- =========================================================
-- 6. UPDATED_AT FUNCTION
-- =========================================================

create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

-- =========================================================
-- 7. UPDATED_AT TRIGGER FOR PROFILES
-- =========================================================

create trigger update_profiles_updated_at
    before update on public.profiles
    for each row
    execute function public.update_updated_at_column();