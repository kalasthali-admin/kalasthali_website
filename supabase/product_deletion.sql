-- Run once in the Supabase SQL Editor before deleting products that have
-- already been purchased. Sales retain their product-name and price snapshots,
-- while product_code becomes null when its catalog product is removed.

alter table public.sales
  alter column product_code drop not null;

alter table public.sales
  drop constraint if exists sales_product_code_fkey;

alter table public.sales
  add constraint sales_product_code_fkey
  foreign key (product_code)
  references public.products(code)
  on delete set null;
