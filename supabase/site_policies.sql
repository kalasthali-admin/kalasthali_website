create table if not exists public.site_policies (
  slug text primary key check (slug in (
    'privacy-policy',
    'terms-of-service',
    'refund-policy'
  )),
  title text not null,
  content text not null,
  updated_at timestamp with time zone not null default now()
);

alter table public.site_policies enable row level security;

drop policy if exists "Anyone can read site policies" on public.site_policies;
create policy "Anyone can read site policies"
on public.site_policies
for select
to anon, authenticated
using (true);
