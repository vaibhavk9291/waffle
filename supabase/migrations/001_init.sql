-- ==============================================================================
-- SHRIMANT STREET FOOD: Supabase Backend Migration 001_init.sql
-- ==============================================================================

-- 1. EXTENSIONS
create extension if not exists "uuid-ossp";

-- 2. SECTIONS TABLE
create table if not exists public.sections (
    id uuid primary key default uuid_generate_v4(),
    name text not null unique,
    sort_order integer not null default 0,
    created_at timestamptz default now()
);

-- 3. PRODUCTS TABLE
create table if not exists public.products (
    id uuid primary key default uuid_generate_v4(),
    section_id uuid not null references public.sections(id) on delete restrict,
    sub_group text, -- e.g. 'Waffle with Ice Cream Flavors'
    name text not null,
    price integer not null check (price >= 0),
    sort_order integer not null default 0,
    is_active boolean not null default true,
    is_new boolean not null default false,
    image_key text,
    created_at timestamptz default now()
);

-- 4. USER PROFILES TABLE (Staff & Owner)
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    display_name text not null,
    role text not null default 'staff' check (role in ('staff', 'owner')),
    pin_hash text, -- Optional 4-digit PIN hash for owners
    created_at timestamptz default now()
);

-- 5. DAILY BILL COUNTER (For concurrent-safe sequential bill numbering per IST date)
create table if not exists public.daily_bill_counters (
    business_date date primary key,
    last_bill_no integer not null default 0
);

-- 6. BILLS TABLE
create table if not exists public.bills (
    id uuid primary key default uuid_generate_v4(),
    bill_no integer not null,
    business_date date not null default (timezone('Asia/Kolkata', now()))::date,
    subtotal integer not null check (subtotal >= 0),
    discount integer not null default 0 check (discount >= 0 and discount <= subtotal),
    total integer not null check (total >= 0),
    payment_mode text not null default 'cash' check (payment_mode in ('cash', 'upi')),
    status text not null default 'paid' check (status in ('paid', 'void')),
    void_reason text,
    created_by uuid references auth.users(id),
    created_at timestamptz not null default now(),
    voided_by uuid references auth.users(id),
    voided_at timestamptz,
    client_tx_id text unique, -- For offline idempotency
    constraint unique_date_bill_no unique (business_date, bill_no)
);

-- 7. BILL ITEMS TABLE
create table if not exists public.bill_items (
    id uuid primary key default uuid_generate_v4(),
    bill_id uuid not null references public.bills(id) on delete cascade,
    product_id uuid references public.products(id) on delete set null,
    product_name text not null,
    unit_price integer not null check (unit_price >= 0),
    qty integer not null check (qty > 0),
    line_total integer not null check (line_total >= 0)
);

-- 8. EXPENSES TABLE
create table if not exists public.expenses (
    id uuid primary key default uuid_generate_v4(),
    business_date date not null default (timezone('Asia/Kolkata', now()))::date,
    note text not null,
    amount integer not null check (amount > 0),
    created_by uuid references auth.users(id),
    created_at timestamptz not null default now(),
    is_deleted boolean not null default false,
    deleted_by uuid references auth.users(id),
    deleted_at timestamptz,
    client_tx_id text unique
);

-- 9. SHOP SETTINGS TABLE (Single row)
create table if not exists public.shop_settings (
    id integer primary key default 1 check (id = 1),
    shop_name text not null default 'Shrimant Street Food',
    address text not null default 'Shop No. 1, Main Road, Pune',
    phone text not null default '+91 9876543210',
    gstin text,
    receipt_footer text not null default 'Thank you! Visit again.',
    paper_width_mm integer not null default 58 check (paper_width_mm in (58, 80)),
    updated_at timestamptz default now()
);

-- Seed shop settings
insert into public.shop_settings (id, shop_name, address, phone, receipt_footer, paper_width_mm)
values (1, 'Shrimant Street Food', 'Main Road, Counter 1', '+91 9876543210', 'Thank you! Visit again.', 58)
on conflict (id) do nothing;

-- 10. TRIGGER FOR AUTO-INCREMENTING BILL_NO PER BUSINESS_DATE
create or replace function public.assign_bill_number()
returns trigger as $$
declare
    next_no integer;
begin
    if new.bill_no is null or new.bill_no <= 0 then
        -- Insert or lock counter for the business date
        insert into public.daily_bill_counters (business_date, last_bill_no)
        values (new.business_date, 1)
        on conflict (business_date) do update
        set last_bill_no = public.daily_bill_counters.last_bill_no + 1
        returning last_bill_no into next_no;
        
        new.bill_no := next_no;
    end if;
    return new;
end;
$$ language plpgsql;

drop trigger if exists trg_assign_bill_number on public.bills;
create trigger trg_assign_bill_number
before insert on public.bills
for each row
execute function public.assign_bill_number();

-- 11. VIEWS
create or replace view public.daily_totals as
select 
    d.business_date,
    coalesce(b.bills_count, 0)::int as bills_count,
    coalesce(b.items_sold, 0)::int as items_sold,
    coalesce(b.gross_revenue, 0)::int as gross_revenue,
    coalesce(b.total_discount, 0)::int as total_discount,
    coalesce(e.expenses_total, 0)::int as expenses_total,
    (coalesce(b.gross_revenue, 0) - coalesce(e.expenses_total, 0))::int as net
from (
    select distinct business_date from public.bills where status = 'paid'
    union
    select distinct business_date from public.expenses where is_deleted = false
    union
    select (timezone('Asia/Kolkata', now()))::date
) d
left join (
    select 
        b.business_date,
        count(distinct b.id) as bills_count,
        coalesce(sum(bi.qty), 0) as items_sold,
        coalesce(sum(b.total), 0) as gross_revenue,
        coalesce(sum(b.discount), 0) as total_discount
    from public.bills b
    left join public.bill_items bi on bi.bill_id = b.id
    where b.status = 'paid'
    group by b.business_date
) b on b.business_date = d.business_date
left join (
    select 
        business_date,
        coalesce(sum(amount), 0) as expenses_total
    from public.expenses
    where is_deleted = false
    group by business_date
) e on e.business_date = d.business_date;

create or replace view public.daily_product_summary as
select 
    b.business_date,
    s.name as section_name,
    bi.product_id,
    bi.product_name,
    sum(bi.qty)::int as units_sold,
    sum(bi.line_total)::int as revenue
from public.bills b
join public.bill_items bi on bi.bill_id = b.id
left join public.products p on p.id = bi.product_id
left join public.sections s on s.id = p.section_id
where b.status = 'paid'
group by b.business_date, s.name, bi.product_id, bi.product_name;

create or replace view public.daily_section_totals as
select 
    b.business_date,
    coalesce(s.name, 'Other') as section_name,
    sum(bi.qty)::int as units_sold,
    sum(bi.line_total)::int as revenue
from public.bills b
join public.bill_items bi on bi.bill_id = b.id
left join public.products p on p.id = bi.product_id
left join public.sections s on s.id = p.section_id
where b.status = 'paid'
group by b.business_date, coalesce(s.name, 'Other');

-- 12. RPC FUNCTIONS: create_bill, void_bill, delete_expense
create or replace function public.create_bill(
    items jsonb,
    discount integer default 0,
    payment_mode text default 'cash',
    client_tx_id text default null
)
returns jsonb
language plpgsql
security definer
as $$
declare
    v_business_date date := (timezone('Asia/Kolkata', now()))::date;
    v_subtotal integer := 0;
    v_discount integer := coalesce(discount, 0);
    v_total integer := 0;
    v_bill_id uuid;
    v_bill_no integer;
    v_item record;
    v_prod record;
    v_result jsonb;
    v_created_by uuid := auth.uid();
begin
    -- Check idempotency
    if client_tx_id is not null then
        select id, bill_no, total into v_bill_id, v_bill_no, v_total
        from public.bills where bills.client_tx_id = create_bill.client_tx_id;
        if found then
            return jsonb_build_object(
                'id', v_bill_id,
                'bill_no', v_bill_no,
                'total', v_total,
                'status', 'duplicate_resolved'
            );
        end if;
    end if;

    if jsonb_array_length(items) = 0 then
        raise exception 'Cart cannot be empty';
    end if;

    -- Calculate subtotal by verifying prices from products table
    for v_item in select * from jsonb_to_recordset(items) as x(product_id uuid, qty int) loop
        select * into v_prod from public.products where id = v_item.product_id and is_active = true;
        if not found then
            raise exception 'Product % not found or inactive', v_item.product_id;
        end if;
        if v_item.qty <= 0 then
            raise exception 'Invalid quantity % for product %', v_item.qty, v_prod.name;
        end if;
        v_subtotal := v_subtotal + (v_prod.price * v_item.qty);
    end loop;

    if v_discount > v_subtotal then
        raise exception 'Discount (%) cannot exceed subtotal (%)', v_discount, v_subtotal;
    end if;

    v_total := v_subtotal - v_discount;

    -- Insert bill
    insert into public.bills (
        business_date, subtotal, discount, total, payment_mode, created_by, client_tx_id
    ) values (
        v_business_date, v_subtotal, v_discount, v_total, payment_mode, v_created_by, client_tx_id
    ) returning id, bill_no into v_bill_id, v_bill_no;

    -- Insert items
    for v_item in select * from jsonb_to_recordset(items) as x(product_id uuid, qty int) loop
        select * into v_prod from public.products where id = v_item.product_id;
        insert into public.bill_items (
            bill_id, product_id, product_name, unit_price, qty, line_total
        ) values (
            v_bill_id, v_prod.id, v_prod.name, v_prod.price, v_item.qty, (v_prod.price * v_item.qty)
        );
    end loop;

    select jsonb_build_object(
        'id', b.id,
        'bill_no', b.bill_no,
        'business_date', b.business_date,
        'subtotal', b.subtotal,
        'discount', b.discount,
        'total', b.total,
        'payment_mode', b.payment_mode,
        'created_at', b.created_at
    ) into v_result
    from public.bills b where b.id = v_bill_id;

    return v_result;
end;
$$;

create or replace function public.void_bill(p_bill_id uuid, p_reason text)
returns boolean
language plpgsql
security definer
as $$
declare
    v_role text;
begin
    -- Check role
    select role into v_role from public.profiles where id = auth.uid();
    if v_role <> 'owner' then
        raise exception 'Only owners can void bills';
    end if;

    update public.bills
    set status = 'void',
        void_reason = p_reason,
        voided_by = auth.uid(),
        voided_at = now()
    where id = p_bill_id and status = 'paid';

    return found;
end;
$$;

create or replace function public.delete_expense(p_expense_id uuid)
returns boolean
language plpgsql
security definer
as $$
declare
    v_role text;
begin
    select role into v_role from public.profiles where id = auth.uid();
    if v_role <> 'owner' then
        raise exception 'Only owners can delete expenses';
    end if;

    update public.expenses
    set is_deleted = true,
        deleted_by = auth.uid(),
        deleted_at = now()
    where id = p_expense_id and is_deleted = false;

    return found;
end;
$$;

-- 13. ROW LEVEL SECURITY (RLS) & PUBLIC GRANTS
grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to anon, authenticated;
grant all on all sequences in schema public to anon, authenticated;
grant all on all routines in schema public to anon, authenticated;

alter table public.sections enable row level security;
alter table public.products enable row level security;
alter table public.profiles enable row level security;
alter table public.bills enable row level security;
alter table public.bill_items enable row level security;
alter table public.expenses enable row level security;
alter table public.shop_settings enable row level security;

-- Sections: Read all (anon + authenticated), write owner
create policy "Sections are viewable by all" on public.sections
    for select to anon, authenticated using (true);
create policy "Sections are editable by owner only" on public.sections
    for all to authenticated using (
        exists (select 1 from public.profiles where id = auth.uid() and role = 'owner')
    );

-- Products: Read all (anon + authenticated), write owner
create policy "Products are viewable by all" on public.products
    for select to anon, authenticated using (true);
create policy "Products are editable by owner only" on public.products
    for all to authenticated using (
        exists (select 1 from public.profiles where id = auth.uid() and role = 'owner')
    );

-- Profiles: Viewable by all, user updates own or owner updates
create policy "Profiles are viewable by all" on public.profiles
    for select to anon, authenticated using (true);
create policy "Profiles can be updated by self or owner" on public.profiles
    for update to authenticated using (
        id = auth.uid() or exists (select 1 from public.profiles where id = auth.uid() and role = 'owner')
    );
create policy "Profiles can be inserted by all" on public.profiles
    for insert to anon, authenticated with check (true);

-- Bills: Read & Insert for counter (anon + authenticated), update owner only
create policy "Bills are viewable by all" on public.bills
    for select to anon, authenticated using (true);
create policy "Bills insertable by all" on public.bills
    for insert to anon, authenticated with check (true);
create policy "Bills updatable by owner only" on public.bills
    for update to authenticated using (
        exists (select 1 from public.profiles where id = auth.uid() and role = 'owner')
    );

-- Bill Items: Read & Insert for all
create policy "Bill items are viewable by all" on public.bill_items
    for select to anon, authenticated using (true);
create policy "Bill items insertable by all" on public.bill_items
    for insert to anon, authenticated with check (true);

-- Expenses: Read for all, insert for all, soft-delete owner only
create policy "Expenses are viewable by all" on public.expenses
    for select to anon, authenticated using (
        is_deleted = false or exists (select 1 from public.profiles where id = auth.uid() and role = 'owner')
    );
create policy "Expenses can be inserted by all" on public.expenses
    for insert to anon, authenticated with check (true);

-- Shop Settings: Read all, update owner
create policy "Shop settings viewable by all" on public.shop_settings
    for select to anon, authenticated using (true);
create policy "Shop settings editable by owner only" on public.shop_settings
    for update to authenticated using (
        exists (select 1 from public.profiles where id = auth.uid() and role = 'owner')
    );

-- 14. REALTIME PUBLICATION
alter publication supabase_realtime add table public.bills;
alter publication supabase_realtime add table public.bill_items;
alter publication supabase_realtime add table public.expenses;
alter publication supabase_realtime add table public.products;
alter publication supabase_realtime add table public.shop_settings;

-- 15. SEED MENU DATA
do $$
declare
    v_choc_id uuid;
    v_waffle_id uuid;
begin
    -- 1. Insert Sections
    insert into public.sections (name, sort_order)
    values ('Chocolate Bowl', 1)
    on conflict (name) do update set sort_order = 1
    returning id into v_choc_id;

    insert into public.sections (name, sort_order)
    values ('Waffle', 2)
    on conflict (name) do update set sort_order = 2
    returning id into v_waffle_id;

    -- 2. Insert Chocolate Bowl Products
    insert into public.products (section_id, name, price, sort_order, is_active, is_new, image_key) values
    (v_choc_id, 'Dark Chocolate Bowl', 70, 1, true, false, 'choc_dark'),
    (v_choc_id, 'Milk Chocolate Bowl', 80, 2, true, false, 'choc_milk'),
    (v_choc_id, 'Kit Kat Bowl', 90, 3, true, false, 'choc_kitkat'),
    (v_choc_id, 'Double Chocolate Bowl', 80, 4, true, false, 'choc_double'),
    (v_choc_id, 'White Chocolate Bowl', 100, 5, true, false, 'choc_white'),
    (v_choc_id, 'Triple Chocolate Bowl', 110, 6, true, false, 'choc_triple'),
    (v_choc_id, 'Oreo Bowl', 90, 7, true, false, 'choc_oreo'),
    (v_choc_id, 'Biscoff Biscuit Bowl', 110, 8, true, false, 'choc_biscoff'),
    (v_choc_id, 'Strawberry Chocolate Bowl', 110, 9, true, true, 'choc_strawberry');

    -- 3. Insert Waffle Standard Products
    insert into public.products (section_id, name, price, sort_order, is_active, is_new, image_key) values
    (v_waffle_id, 'Dark Waffle', 60, 1, true, false, 'waffle_dark'),
    (v_waffle_id, 'Milk Waffle', 70, 2, true, false, 'waffle_milk'),
    (v_waffle_id, 'Kitkat Waffle', 80, 3, true, false, 'waffle_kitkat'),
    (v_waffle_id, 'Double Chocolate Waffle', 70, 4, true, false, 'waffle_double'),
    (v_waffle_id, 'White Waffle', 90, 5, true, false, 'waffle_white'),
    (v_waffle_id, 'Triple Chocolate Waffle', 100, 6, true, false, 'waffle_triple'),
    (v_waffle_id, 'Oreo Waffle', 80, 7, true, false, 'waffle_oreo'),
    (v_waffle_id, 'Biscoff Waffle', 100, 8, true, false, 'waffle_biscoff'),
    (v_waffle_id, 'Waffle with Ice Cream', 110, 9, true, false, 'waffle_icecream');

    -- 4. Insert Waffle Sub-group: Waffle with Ice Cream Flavors
    insert into public.products (section_id, sub_group, name, price, sort_order, is_active, is_new, image_key) values
    (v_waffle_id, 'Waffle with Ice Cream Flavors', 'Waffle with Pista Ice Cream', 105, 10, true, false, 'waffle_pista'),
    (v_waffle_id, 'Waffle with Ice Cream Flavors', 'Waffle with Chocolate Ice Cream', 110, 11, true, false, 'waffle_chocolate_ic'),
    (v_waffle_id, 'Waffle with Ice Cream Flavors', 'Waffle with Kesar Kulfi Ice Cream', 110, 12, true, false, 'waffle_kesar_kulfi'),
    (v_waffle_id, 'Waffle with Ice Cream Flavors', 'Waffle with Strawberry Ice Cream', 110, 13, true, false, 'waffle_strawberry_ic');
end $$;
