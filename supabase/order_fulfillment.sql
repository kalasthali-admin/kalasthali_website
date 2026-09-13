-- Run once in the Supabase SQL Editor before using the Admin Orders tab.
-- These fields preserve fulfillment information on the immutable sale record.

alter table public.sales
  add column if not exists tracking_id text,
  add column if not exists tracking_url text,
  add column if not exists shipping_confirmation_sent_at timestamp with time zone;
