-- Run this in the Supabase SQL Editor before using checkout delivery details.
create table if not exists public.user_account (
  id uuid primary key references auth.users (id) on delete cascade,
  receiver_name text,
  address_line1 text,
  address_line2 text,
  state_pincode text,
  updated_at timestamptz not null default now()
);

alter table public.user_account enable row level security;

create policy "Users can read their own account"
on public.user_account
for select
to authenticated
using (auth.uid() = id);

create policy "Users can create their own account"
on public.user_account
for insert
to authenticated
with check (auth.uid() = id);

create policy "Users can update their own account"
on public.user_account
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);
