-- Run once in the Supabase SQL Editor before using the Admin Orders tab.
-- These fields preserve fulfillment information on the immutable sale record.

alter table public.sales
  add column if not exists tracking_id text,
  add column if not exists tracking_url text,
  add column if not exists shipping_confirmation_sent_at timestamp with time zone,
  add column if not exists order_status text not null default 'order_placed'
    check (order_status in ('order_placed', 'out_for_delivery', 'delivered', 'cancelled')),
  add column if not exists out_for_delivery_at timestamp with time zone,
  add column if not exists delivered_at timestamp with time zone,
  add column if not exists cancelled_at timestamp with time zone,
  add column if not exists cancellation_message text,
  add column if not exists return_status text
    check (return_status in ('requested', 'accepted_for_return', 'refund_processed', 'rejected')),
  add column if not exists return_requested_at timestamp with time zone,
  add column if not exists return_evidence jsonb not null default '[]'::jsonb,
  add column if not exists return_tracking_id text,
  add column if not exists return_tracking_url text,
  add column if not exists return_accepted_at timestamp with time zone,
  add column if not exists refund_processed_at timestamp with time zone,
  add column if not exists return_rejected_at timestamp with time zone,
  add column if not exists return_rejection_reason text;

alter table public.sales drop constraint if exists sales_return_status_check;
alter table public.sales add constraint sales_return_status_check
  check (return_status in ('requested', 'accepted_for_return', 'refund_processed', 'rejected'));

-- Existing shipment-confirmed orders entered before order_status was introduced
-- are already on their way to the customer.
update public.sales
set order_status = 'out_for_delivery',
    out_for_delivery_at = coalesce(out_for_delivery_at, shipping_confirmation_sent_at)
where shipping_confirmation_sent_at is not null
  and order_status = 'order_placed';

insert into storage.buckets (id, name, public)
values ('return_evidence', 'return_evidence', false)
on conflict (id) do update set public = false;
