-- User-added attractions per city (anyone can add; everyone can rate)
create table if not exists public.city_attractions (
  id uuid primary key default uuid_generate_v4(),
  city_name text not null,
  country text not null,
  name text not null,
  category text not null,
  added_by uuid references auth.users(id) on delete set null,
  created_at timestamptz default now()
);

create index if not exists idx_city_attractions_city_country
  on public.city_attractions (city_name, country);

alter table public.city_attractions enable row level security;

create policy "Anyone can read city_attractions"
  on public.city_attractions for select using (true);
create policy "Authenticated users can insert city_attractions"
  on public.city_attractions for insert with check (auth.uid() is not null);
