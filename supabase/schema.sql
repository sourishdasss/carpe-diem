-- Run this in Supabase Dashboard → SQL Editor
-- Direct link: https://supabase.com/dashboard/project/ghgyqptnsgbytmuajhvl/sql/new

-- Enable UUID extension if not already
create extension if not exists "uuid-ossp";

-- Profiles: display name for feed (required by app + handle_new_user trigger)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Traveler',
  first_name text default '',
  last_name text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- If `profiles` already existed, ensure all columns the app expects are present.
alter table public.profiles add column if not exists display_name text default 'Traveler';
alter table public.profiles add column if not exists first_name text default '';
alter table public.profiles add column if not exists last_name text default '';
alter table public.profiles add column if not exists created_at timestamptz default now();

-- Rated cities: one row per user per city
create table if not exists public.rated_cities (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  city_name text not null,
  country text not null,
  flag text not null default '',
  photo_url text not null default '',
  cumulative_score double precision not null,
  summary text not null default '',
  highlight text not null default '',
  would_recommend_if text not null default '',
  score_breakdown jsonb,
  top_attraction_name text,
  ratings jsonb not null default '[]',  -- [{ "attractionId": "uuid", "score": 5 }]
  created_at timestamptz default now(),
  unique(user_id, city_name, country)
);

-- Travel profile: one row per user
create table if not exists public.travel_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  personality_type text not null default '',
  personality_description text not null default '',
  taste_traits jsonb not null default '[]',
  recommendations jsonb not null default '[]',  -- [{ "destination", "matchReason", "vibeTags" }]
  updated_at timestamptz default now()
);

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
create index if not exists idx_city_attractions_city_country on public.city_attractions (city_name, country);
alter table public.city_attractions enable row level security;
create policy "Anyone can read city_attractions" on public.city_attractions for select using (true);
create policy "Authenticated users can insert city_attractions" on public.city_attractions for insert with check (auth.uid() is not null);

-- Feed activities: for social feed
create table if not exists public.feed_activities (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null default 'Traveler',
  activity_type text not null,  -- 'rated_attraction' | 'visited_city' | 'added_favourite'
  city text not null,
  country text not null,
  city_photo_url text,
  score double precision,
  review text,
  data jsonb default '{}',  -- e.g. { "attractionName": "Eiffel Tower", "score": 5 }
  created_at timestamptz default now()
);

-- RLS
alter table public.profiles enable row level security;
alter table public.rated_cities enable row level security;
alter table public.travel_profiles enable row level security;
alter table public.feed_activities enable row level security;

-- Profiles: own row only
create policy "Users can read own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);

-- Rated cities: own rows only
create policy "Users can read own rated_cities" on public.rated_cities for select using (auth.uid() = user_id);
create policy "Users can insert own rated_cities" on public.rated_cities for insert with check (auth.uid() = user_id);
create policy "Users can delete own rated_cities" on public.rated_cities for delete using (auth.uid() = user_id);

-- Travel profiles: own row only
create policy "Users can read own travel_profiles" on public.travel_profiles for select using (auth.uid() = user_id);
create policy "Users can insert own travel_profiles" on public.travel_profiles for insert with check (auth.uid() = user_id);
create policy "Users can update own travel_profiles" on public.travel_profiles for update using (auth.uid() = user_id);

-- Feed: everyone can read; users can insert own
create policy "Anyone can read feed_activities" on public.feed_activities for select using (true);
create policy "Users can insert own feed_activities" on public.feed_activities for insert with check (auth.uid() = user_id);

-- Create profile on first sign-in (optional trigger; or create from app)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', 'Traveler'))
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
