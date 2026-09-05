alter table public.user_cart
  alter column "user" set default auth.uid(),
  alter column quantity set default 1,
  alter column quantity set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'user_cart_user_fkey'
      and conrelid = 'public.user_cart'::regclass
  ) then
    alter table public.user_cart
      add constraint user_cart_user_fkey
      foreign key ("user") references auth.users (id)
      on delete cascade;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'user_cart_quantity_positive'
      and conrelid = 'public.user_cart'::regclass
  ) then
    alter table public.user_cart
      add constraint user_cart_quantity_positive
      check (quantity > 0);
  end if;
end $$;

alter table public.user_cart
  drop constraint if exists user_cart_pkey;

alter table public.user_cart
  add constraint user_cart_pkey primary key ("user", code);

alter table public.user_cart enable row level security;

drop policy if exists "Users can read their own cart" on public.user_cart;
drop policy if exists "Users can add to their own cart" on public.user_cart;
drop policy if exists "Users can update their own cart" on public.user_cart;
drop policy if exists "Users can delete their own cart" on public.user_cart;

create policy "Users can read their own cart" on public.user_cart
for select using (auth.uid() = "user");

create policy "Users can add to their own cart" on public.user_cart
for insert with check (auth.uid() = "user");

create policy "Users can update their own cart" on public.user_cart
for update using (auth.uid() = "user") with check (auth.uid() = "user");

create policy "Users can delete their own cart" on public.user_cart
for delete using (auth.uid() = "user");
