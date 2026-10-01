-- Run once in the Supabase SQL Editor before deploying the review UI.
create table if not exists public.product_reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  order_id text not null,
  product_code text not null references public.products(code) on delete cascade,
  reviewer_name text not null check (char_length(reviewer_name) between 1 and 80),
  rating smallint not null check (rating between 1 and 5),
  review_text text not null check (char_length(review_text) between 3 and 1000),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint product_reviews_user_product_unique unique (user_id, product_code)
);

create index if not exists product_reviews_product_code_created_at_idx
  on public.product_reviews (product_code, created_at desc);

alter table public.product_reviews enable row level security;

drop policy if exists "Anyone can read product reviews" on public.product_reviews;
revoke all on table public.product_reviews from anon, authenticated;

create or replace function public.get_product_reviews(
  requested_product_code text
)
returns table (
  id uuid,
  product_code text,
  reviewer_name text,
  rating smallint,
  review_text text,
  created_at timestamp with time zone
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    review.id,
    review.product_code,
    review.reviewer_name,
    review.rating,
    review.review_text,
    review.created_at
  from public.product_reviews as review
  where review.product_code = requested_product_code
  order by review.created_at desc;
$$;

create or replace function public.get_my_product_reviews()
returns table (
  id uuid,
  order_id text,
  product_code text,
  rating smallint,
  review_text text,
  created_at timestamp with time zone
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    review.id,
    review.order_id,
    review.product_code,
    review.rating,
    review.review_text,
    review.created_at
  from public.product_reviews as review
  where review.user_id = auth.uid()
  order by review.created_at desc;
$$;

revoke all on function public.get_product_reviews(text) from public;
revoke all on function public.get_my_product_reviews() from public;
grant execute on function public.get_product_reviews(text) to anon, authenticated;
grant execute on function public.get_my_product_reviews() to authenticated;

-- Inserts and updates intentionally have no client RLS policy. The authenticated
-- order API verifies purchase ownership and writes with the service-role key.
