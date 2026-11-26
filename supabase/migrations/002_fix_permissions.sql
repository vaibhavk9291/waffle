-- ==============================================================================
-- RUN THIS SCRIPT IN SUPABASE SQL EDITOR TO GRANT COUNTER & RESET PERMISSIONS
-- ==============================================================================

grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to anon, authenticated;
grant all on all sequences in schema public to anon, authenticated;
grant all on all routines in schema public to anon, authenticated;

-- Ensure RLS allows anon access for fast counter sales
drop policy if exists "Sections are viewable by all" on public.sections;
drop policy if exists "Sections are viewable by authenticated users" on public.sections;
create policy "Sections are viewable by all" on public.sections for select to anon, authenticated using (true);

drop policy if exists "Products are viewable by all" on public.products;
drop policy if exists "Products are viewable by authenticated users" on public.products;
create policy "Products are viewable by all" on public.products for select to anon, authenticated using (true);

drop policy if exists "Bills are viewable by all" on public.bills;
drop policy if exists "Bills are viewable by authenticated users" on public.bills;
create policy "Bills are viewable by all" on public.bills for select to anon, authenticated using (true);

drop policy if exists "Bills insertable by all" on public.bills;
drop policy if exists "Bills insertable by authenticated users" on public.bills;
create policy "Bills insertable by all" on public.bills for insert to anon, authenticated with check (true);

drop policy if exists "Bills deletable by all" on public.bills;
create policy "Bills deletable by all" on public.bills for delete to anon, authenticated using (true);

drop policy if exists "Bill items are viewable by all" on public.bill_items;
drop policy if exists "Bill items are viewable by authenticated users" on public.bill_items;
create policy "Bill items are viewable by all" on public.bill_items for select to anon, authenticated using (true);

drop policy if exists "Bill items insertable by all" on public.bill_items;
drop policy if exists "Bill items insertable by authenticated users" on public.bill_items;
create policy "Bill items insertable by all" on public.bill_items for insert to anon, authenticated with check (true);

drop policy if exists "Bill items deletable by all" on public.bill_items;
create policy "Bill items deletable by all" on public.bill_items for delete to anon, authenticated using (true);

drop policy if exists "Expenses are viewable by all" on public.expenses;
drop policy if exists "Expenses are viewable by authenticated users" on public.expenses;
create policy "Expenses are viewable by all" on public.expenses for select to anon, authenticated using (true);

drop policy if exists "Expenses can be inserted by all" on public.expenses;
drop policy if exists "Expenses can be inserted by authenticated users" on public.expenses;
create policy "Expenses can be inserted by all" on public.expenses for insert to anon, authenticated with check (true);

drop policy if exists "Expenses deletable by all" on public.expenses;
create policy "Expenses deletable by all" on public.expenses for delete to anon, authenticated using (true);

drop policy if exists "Shop settings viewable by all" on public.shop_settings;
drop policy if exists "Shop settings viewable by authenticated users" on public.shop_settings;
create policy "Shop settings viewable by all" on public.shop_settings for select to anon, authenticated using (true);

-- Allow clearing daily counter
grant delete on public.daily_bill_counters to anon, authenticated;

-- Fast atomic server-side reset function
create or replace function public.reset_sales_data(p_all_dates boolean default false)
returns boolean
language plpgsql
security definer
as $$
declare
    v_today date := (timezone('Asia/Kolkata', now()))::date;
begin
    if p_all_dates then
        delete from public.bill_items;
        delete from public.bills;
        delete from public.expenses;
        delete from public.daily_bill_counters;
    else
        delete from public.bill_items where bill_id in (select id from public.bills where business_date = v_today);
        delete from public.bills where business_date = v_today;
        delete from public.expenses where business_date = v_today;
        delete from public.daily_bill_counters where business_date = v_today;
    end if;
    return true;
end;
$$;

grant execute on function public.reset_sales_data(boolean) to anon, authenticated;
grant execute on function public.create_bill(jsonb, integer, text, text) to anon, authenticated;
grant execute on function public.assign_bill_number() to anon, authenticated;
