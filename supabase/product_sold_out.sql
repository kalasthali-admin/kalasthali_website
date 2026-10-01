-- Run once in the Supabase SQL Editor.
alter table public.products
  add column if not exists is_sold_out boolean not null default false;
