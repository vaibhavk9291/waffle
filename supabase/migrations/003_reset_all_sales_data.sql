-- ==============================================================================
-- WIPE ALL SALES, BILLS & EXPENSES DATA (RESET COUNTER TO ZERO)
-- Paste and run this in your Supabase Dashboard -> SQL Editor
-- (This preserves all products, sections, settings, and user logins)
-- ==============================================================================

-- 1. Delete all bill line items
truncate table public.bill_items cascade;

-- 2. Delete all bills
truncate table public.bills cascade;

-- 3. Delete all recorded expenses
truncate table public.expenses cascade;

-- 4. Reset the daily bill number counter table
truncate table public.daily_bill_counters cascade;

-- Quick check: returns 0 bills, 0 gross, 0 net
select * from public.daily_totals;
