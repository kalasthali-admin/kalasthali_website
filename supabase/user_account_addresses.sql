-- Run this once in the Supabase SQL Editor. It extends the existing
-- user_account profile table and replaces the single delivery address model
-- with multiple saved addresses per authenticated user.

create extension if not exists pgcrypto;

create table if not exists public.user_account (
  id uuid primary key references auth.users (id) on delete cascade,
  phone_number text,
  updated_at timestamptz not null default now()
);

alter table public.user_account
  add column if not exists phone_number text,
  add column if not exists receiver_name text,
  add column if not exists address_line1 text,
  add column if not exists address_line2 text,
  add column if not exists state_pincode text;

create table if not exists public.user_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  receiver_name text not null,
  phone_number text,
  address_line1 text not null,
  address_line2 text,
  city text,
  state_pincode text not null,
  country text not null default 'India',
  is_selected boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Only one address can be selected for each account.
create unique index if not exists user_addresses_one_selected_per_user
on public.user_addresses (user_id)
where is_selected;

-- Preserve any address customers saved through the initial checkout flow.
insert into public.user_addresses (
  user_id, receiver_name, address_line1, address_line2, state_pincode,
  is_selected
)
select
  id, receiver_name, address_line1, address_line2, state_pincode, true
from public.user_account
where coalesce(trim(receiver_name), '') <> ''
  and coalesce(trim(address_line1), '') <> ''
  and coalesce(trim(state_pincode), '') <> ''
  and not exists (
    select 1 from public.user_addresses addresses
    where addresses.user_id = user_account.id
  );

-- A newly created address becomes selected when it is the customer's first
-- address. Selecting another address deselects the prior one atomically.
create or replace function public.manage_selected_address()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if tg_op = 'INSERT' and not exists (
    select 1 from public.user_addresses where user_id = new.user_id
  ) then
    new.is_selected := true;
  end if;

  if new.is_selected then
    update public.user_addresses
    set is_selected = false, updated_at = now()
    where user_id = new.user_id
      and id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
      and is_selected;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists manage_selected_address on public.user_addresses;
create trigger manage_selected_address
before insert or update of is_selected on public.user_addresses
for each row execute function public.manage_selected_address();

alter table public.user_account enable row level security;
alter table public.user_addresses enable row level security;

drop policy if exists "Users can read their own account" on public.user_account;
drop policy if exists "Users can create their own account" on public.user_account;
drop policy if exists "Users can update their own account" on public.user_account;
create policy "Users can read their own account" on public.user_account
for select to authenticated using (auth.uid() = id);
create policy "Users can create their own account" on public.user_account
for insert to authenticated with check (auth.uid() = id);
create policy "Users can update their own account" on public.user_account
for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

create policy "Users can read their own addresses" on public.user_addresses
for select to authenticated using (auth.uid() = user_id);
create policy "Users can create their own addresses" on public.user_addresses
for insert to authenticated with check (auth.uid() = user_id);
create policy "Users can update their own addresses" on public.user_addresses
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete their own addresses" on public.user_addresses
for delete to authenticated using (auth.uid() = user_id);
