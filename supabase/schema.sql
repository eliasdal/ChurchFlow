-- ChurchFlow starter schema for Supabase/Postgres.
-- Run in the Supabase SQL Editor. RLS is enabled on all tenant data.
create extension if not exists pgcrypto;

create table if not exists public.churches (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 2 and 120),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);
create table if not exists public.church_members (
  church_id uuid not null references public.churches(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'team_member' check (role in ('church_admin','worship_admin','team_member','viewer')),
  created_at timestamptz not null default now(),
  primary key (church_id,user_id)
);
create table if not exists public.songs (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null references public.churches(id) on delete cascade,
  title text not null,
  artist text,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists public.chord_charts (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null references public.churches(id) on delete cascade,
  song_id uuid not null references public.songs(id) on delete cascade,
  musical_key text not null,
  storage_path text not null,
  created_at timestamptz not null default now(),
  unique(song_id,musical_key)
);
create table if not exists public.service_plans (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null references public.churches(id) on delete cascade,
  title text not null,
  service_date date not null,
  service_time text,
  location text,
  status text not null default 'draft' check (status in ('draft','planning','ready','completed')),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.service_plan_items (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null references public.churches(id) on delete cascade,
  service_plan_id uuid not null references public.service_plans(id) on delete cascade,
  song_id uuid references public.songs(id) on delete set null,
  title_snapshot text not null,
  musical_key text,
  sort_order integer not null default 0,
  team_note text,
  chart_id uuid references public.chord_charts(id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists public.team_profiles (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null references public.churches(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  display_name text not null,
  email text,
  ministry_role text,
  created_at timestamptz not null default now()
);

create or replace function public.is_church_member(target_church uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.church_members m where m.church_id=target_church and m.user_id=auth.uid()); $$;
create or replace function public.has_church_role(target_church uuid, allowed_roles text[])
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.church_members m where m.church_id=target_church and m.user_id=auth.uid() and m.role=any(allowed_roles)); $$;
revoke all on function public.is_church_member(uuid) from public;
revoke all on function public.has_church_role(uuid,text[]) from public;
grant execute on function public.is_church_member(uuid) to authenticated;
grant execute on function public.has_church_role(uuid,text[]) to authenticated;

alter table public.churches enable row level security;
alter table public.church_members enable row level security;
alter table public.songs enable row level security;
alter table public.chord_charts enable row level security;
alter table public.service_plans enable row level security;
alter table public.service_plan_items enable row level security;
alter table public.team_profiles enable row level security;

drop policy if exists "members read their churches" on public.churches;
create policy "members read their churches" on public.churches for select to authenticated using (public.is_church_member(id));
drop policy if exists "church admin update church" on public.churches;
create policy "church admin update church" on public.churches for update to authenticated using (public.has_church_role(id,array['church_admin'])) with check (public.has_church_role(id,array['church_admin']));
drop policy if exists "members read membership" on public.church_members;
create policy "members read membership" on public.church_members for select to authenticated using (public.is_church_member(church_id));
drop policy if exists "admins manage membership" on public.church_members;
create policy "admins manage membership" on public.church_members for all to authenticated using (public.has_church_role(church_id,array['church_admin'])) with check (public.has_church_role(church_id,array['church_admin']));

drop policy if exists "members read songs" on public.songs;
create policy "members read songs" on public.songs for select to authenticated using (public.is_church_member(church_id));
drop policy if exists "worship admins manage songs" on public.songs;
create policy "worship admins manage songs" on public.songs for all to authenticated using (public.has_church_role(church_id,array['church_admin','worship_admin'])) with check (public.has_church_role(church_id,array['church_admin','worship_admin']));
drop policy if exists "members read charts" on public.chord_charts;
create policy "members read charts" on public.chord_charts for select to authenticated using (public.is_church_member(church_id));
drop policy if exists "worship admins manage charts" on public.chord_charts;
create policy "worship admins manage charts" on public.chord_charts for all to authenticated using (public.has_church_role(church_id,array['church_admin','worship_admin'])) with check (public.has_church_role(church_id,array['church_admin','worship_admin']));
drop policy if exists "members read services" on public.service_plans;
create policy "members read services" on public.service_plans for select to authenticated using (public.is_church_member(church_id));
drop policy if exists "worship admins manage services" on public.service_plans;
create policy "worship admins manage services" on public.service_plans for all to authenticated using (public.has_church_role(church_id,array['church_admin','worship_admin'])) with check (public.has_church_role(church_id,array['church_admin','worship_admin']));
drop policy if exists "members read plan items" on public.service_plan_items;
create policy "members read plan items" on public.service_plan_items for select to authenticated using (public.is_church_member(church_id));
drop policy if exists "worship admins manage plan items" on public.service_plan_items;
create policy "worship admins manage plan items" on public.service_plan_items for all to authenticated using (public.has_church_role(church_id,array['church_admin','worship_admin'])) with check (public.has_church_role(church_id,array['church_admin','worship_admin']));
drop policy if exists "members read team profiles" on public.team_profiles;
create policy "members read team profiles" on public.team_profiles for select to authenticated using (public.is_church_member(church_id));
drop policy if exists "admins manage team profiles" on public.team_profiles;
create policy "admins manage team profiles" on public.team_profiles for all to authenticated using (public.has_church_role(church_id,array['church_admin','worship_admin'])) with check (public.has_church_role(church_id,array['church_admin','worship_admin']));

-- IMPORTANT: create the first church and its church_admin membership via a trusted
-- server-side setup flow or SQL run by the project owner. Do not let anonymous clients
-- insert arbitrary membership rows. Do not expose a service-role key in the frontend.
