-- ==============================================================================
-- RUN THIS SCRIPT IN SUPABASE SQL EDITOR TO ENABLE IN-APP RESET & WIPE
-- ==============================================================================

-- 1. Create the atomic server-side reset function (runs as admin via SECURITY DEFINER)
create or replace function public.reset_sales_data(p_all_dates boolean default false)
returns boolean
language plpgsql
security definer
as $$
begin
    if p_all_dates then
        truncate table public.bill_items cascade;
        truncate table public.bills cascade;
        truncate table public.expenses cascade;
        truncate table public.daily_bill_counters cascade;
    else
        delete from public.bill_items where bill_id in (
            select id from public.bills where business_date = (timezone('Asia/Kolkata', now()))::date
        );
        delete from public.bills where business_date = (timezone('Asia/Kolkata', now()))::date;
        delete from public.expenses where business_date = (timezone('Asia/Kolkata', now()))::date;
        delete from public.daily_bill_counters where business_date = (timezone('Asia/Kolkata', now()))::date;
    end if;
    return true;
end;
$$;

-- 2. Allow the mobile app (anon & authenticated) to call this function
grant execute on function public.reset_sales_data(boolean) to anon, authenticated, service_role;

-- 3. Grant direct delete permissions as fallback
grant delete on public.bills to anon, authenticated;
grant delete on public.bill_items to anon, authenticated;
grant delete on public.expenses to anon, authenticated;
grant delete on public.daily_bill_counters to anon, authenticated;

drop policy if exists "Bills deletable by all" on public.bills;
create policy "Bills deletable by all" on public.bills for delete to anon, authenticated using (true);

drop policy if exists "Bill items deletable by all" on public.bill_items;
create policy "Bill items deletable by all" on public.bill_items for delete to anon, authenticated using (true);

drop policy if exists "Expenses deletable by all" on public.expenses;
create policy "Expenses deletable by all" on public.expenses for delete to anon, authenticated using (true);
