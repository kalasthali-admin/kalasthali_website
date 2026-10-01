-- Run once in the Supabase SQL Editor after creating public.sales.
-- Checkout writes through the server with the service-role key; customers only
-- need read access to their own completed purchases in the account page.

alter table public.sales enable row level security;

drop policy if exists "Users can read their own sales" on public.sales;
create policy "Users can read their own sales" on public.sales
for select
to authenticated
using (auth.uid() = "user");
