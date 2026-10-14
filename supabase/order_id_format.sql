-- Run once in the Supabase SQL Editor before deploying the updated
-- api/verify-payment.js function. This also converts legacy order_* IDs.

begin;

alter table public.sales
  add column if not exists razorpay_order_id text;

-- Existing records used the Razorpay order ID as their public order ID.
-- Preserve that value for payment audit and duplicate-payment protection.
update public.sales
set razorpay_order_id = order_id
where razorpay_order_id is null
  and razorpay_payment_id is not null;

create unique index if not exists sales_order_id_unique_idx
  on public.sales (order_id);

create unique index if not exists sales_razorpay_order_id_unique_idx
  on public.sales (razorpay_order_id)
  where razorpay_order_id is not null;

create temporary table order_id_migration_map (
  old_order_id text primary key,
  new_order_id text not null unique
) on commit drop;

do $$
declare
  sale record;
  prefix text;
  clean_product_code text;
  candidate text;
  suffix_number integer;
begin
  for sale in
    select order_id, product_code, items, paid_at
    from public.sales
    where order_id like 'order\_%' escape '\'
    order by paid_at nulls last, order_id
  loop
    if jsonb_typeof(coalesce(sale.items::jsonb, '[]'::jsonb)) = 'array'
       and jsonb_array_length(coalesce(sale.items::jsonb, '[]'::jsonb)) > 1 then
      prefix := 'KGR';
    else
      clean_product_code := upper(
        regexp_replace(
          coalesce(
            nullif(sale.product_code, ''),
            nullif(sale.items::jsonb -> 0 ->> 'product_code', ''),
            'ORDER'
          ),
          '[^A-Za-z0-9_-]',
          '',
          'g'
        )
      );
      prefix := 'K' || clean_product_code;
    end if;

    candidate := null;
    for suffix_number in 1..9999 loop
      candidate := prefix || lpad(suffix_number::text, 4, '0');
      if not exists (
        select 1 from public.sales where order_id = candidate
      ) and not exists (
        select 1 from order_id_migration_map where new_order_id = candidate
      ) then
        exit;
      end if;
      candidate := null;
    end loop;

    if candidate is null then
      raise exception 'No four-digit order IDs remain available for prefix %', prefix;
    end if;

    insert into order_id_migration_map (old_order_id, new_order_id)
    values (sale.order_id, candidate);
  end loop;
end
$$;

-- Reviews retain their association after historical sales IDs are renamed.
do $$
begin
  if to_regclass('public.product_reviews') is not null then
    execute $update_reviews$
      update public.product_reviews as review
      set order_id = mapping.new_order_id
      from order_id_migration_map as mapping
      where review.order_id = mapping.old_order_id
    $update_reviews$;
  end if;
end
$$;

update public.sales as sale
set order_id = mapping.new_order_id
from order_id_migration_map as mapping
where sale.order_id = mapping.old_order_id;

comment on column public.sales.razorpay_order_id is
  'Private Razorpay order identifier used for verification and idempotency. order_id is the customer-facing Kalasthali identifier.';

commit;
