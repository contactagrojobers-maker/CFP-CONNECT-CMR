-- CFP Connect — schéma initial Supabase
create extension if not exists pgcrypto;

create type public.user_role as enum ('learner', 'center_manager', 'admin');
create type public.center_status as enum ('draft', 'pending', 'published', 'rejected', 'suspended');
create type public.claim_status as enum ('pending', 'approved', 'rejected');
create type public.review_status as enum ('pending', 'published', 'hidden');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role public.user_role not null default 'learner',
  created_at timestamptz not null default now()
);

create table public.regions (
  id bigint generated always as identity primary key,
  name text not null unique
);
create table public.departments (
  id bigint generated always as identity primary key,
  region_id bigint not null references public.regions(id) on delete cascade,
  name text not null,
  unique(region_id, name)
);
create table public.cities (
  id bigint generated always as identity primary key,
  department_id bigint not null references public.departments(id) on delete cascade,
  name text not null,
  unique(department_id, name)
);

create table public.centers (
  id uuid primary key default gen_random_uuid(),
  city_id bigint references public.cities(id),
  name text not null,
  slug text not null unique,
  acronym text,
  center_type text,
  district text,
  description text,
  phone text,
  whatsapp text,
  email text,
  map_url text,
  accreditation_number text,
  accreditation_verified boolean not null default false,
  next_intake date,
  status public.center_status not null default 'pending',
  is_featured boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.programs (
  id bigint generated always as identity primary key,
  name text not null unique,
  category text
);
create table public.center_programs (
  center_id uuid references public.centers(id) on delete cascade,
  program_id bigint references public.programs(id) on delete cascade,
  duration text,
  diploma text,
  admission_level text,
  primary key(center_id, program_id)
);
create table public.center_managers (
  center_id uuid references public.centers(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  approved_at timestamptz,
  primary key(center_id, user_id)
);
create table public.center_photos (
  id uuid primary key default gen_random_uuid(),
  center_id uuid not null references public.centers(id) on delete cascade,
  storage_path text not null,
  caption text,
  is_cover boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
create table public.center_claims (
  id uuid primary key default gen_random_uuid(),
  center_id uuid not null references public.centers(id) on delete cascade,
  requester_id uuid not null references public.profiles(id) on delete cascade,
  function_title text,
  proof_path text,
  status public.claim_status not null default 'pending',
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  center_id uuid not null references public.centers(id) on delete cascade,
  author_id uuid references public.profiles(id) on delete set null,
  author_name text not null,
  rating integer not null check (rating between 1 and 5),
  comment text not null check (char_length(comment) between 10 and 1500),
  status public.review_status not null default 'pending',
  created_at timestamptz not null default now()
);
create table public.contact_requests (
  id uuid primary key default gen_random_uuid(),
  center_id uuid references public.centers(id) on delete set null,
  full_name text not null,
  contact text not null,
  subject text not null,
  message text not null,
  processed_at timestamptz,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin') $$;
create or replace function public.manages_center(target uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.center_managers where center_id=target and user_id=auth.uid() and approved_at is not null) $$;

alter table public.profiles enable row level security;
alter table public.regions enable row level security;
alter table public.departments enable row level security;
alter table public.cities enable row level security;
alter table public.centers enable row level security;
alter table public.programs enable row level security;
alter table public.center_programs enable row level security;
alter table public.center_photos enable row level security;
alter table public.center_managers enable row level security;
alter table public.center_claims enable row level security;
alter table public.reviews enable row level security;
alter table public.contact_requests enable row level security;

create policy "users read own profile" on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
create policy "users update own profile" on public.profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid());
create policy "public reads regions" on public.regions for select using (true);
create policy "public reads departments" on public.departments for select using (true);
create policy "public reads cities" on public.cities for select using (true);
create policy "public reads programs" on public.programs for select using (true);
create policy "admins manage programs" on public.programs for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "public reads published centers" on public.centers for select using (status='published' or public.is_admin() or public.manages_center(id));
create policy "admins manage centers" on public.centers for all using (public.is_admin()) with check (public.is_admin());
create policy "managers update their centers" on public.centers for update using (public.manages_center(id)) with check (public.manages_center(id));
create policy "public reads center programs" on public.center_programs for select using (true);
create policy "admins manage center programs" on public.center_programs for all using (public.is_admin()) with check (public.is_admin());
create policy "public reads center photos" on public.center_photos for select using (true);
create policy "admins manage center photos" on public.center_photos for all using (public.is_admin()) with check (public.is_admin());
create policy "managers read their access" on public.center_managers for select to authenticated using (user_id=auth.uid() or public.is_admin());
create policy "admins manage manager access" on public.center_managers for all using (public.is_admin()) with check (public.is_admin());
create policy "users create claims" on public.center_claims for insert to authenticated with check (requester_id=auth.uid());
create policy "users read own claims" on public.center_claims for select to authenticated using (requester_id=auth.uid() or public.is_admin());
create policy "admins manage claims" on public.center_claims for all using (public.is_admin()) with check (public.is_admin());
create policy "public reads published reviews" on public.reviews for select using (status='published' or public.is_admin());
create policy "authenticated users create reviews" on public.reviews for insert to authenticated with check (author_id=auth.uid());
create policy "admins moderate reviews" on public.reviews for all using (public.is_admin()) with check (public.is_admin());
create policy "anyone sends contact requests" on public.contact_requests for insert with check (true);
create policy "admins read contacts" on public.contact_requests for select using (public.is_admin());

insert into public.regions(name) values
('Adamaoua'),('Centre'),('Est'),('Extrême-Nord'),('Littoral'),('Nord'),('Nord-Ouest'),('Ouest'),('Sud'),('Sud-Ouest')
on conflict do nothing;
insert into public.departments(region_id,name)
select id,'Lom-et-Djérem' from public.regions where name='Est' on conflict do nothing;
insert into public.cities(department_id,name)
select id,'Bertoua' from public.departments where name='Lom-et-Djérem' on conflict do nothing;

insert into storage.buckets(id,name,public) values
('center-photos','center-photos',true),
('accreditations','accreditations',false)
on conflict (id) do nothing;

create policy "public reads center photo files" on storage.objects for select using (bucket_id='center-photos');
create policy "admins upload center photo files" on storage.objects for insert to authenticated with check (bucket_id='center-photos' and public.is_admin());
create policy "admins manage accreditation files" on storage.objects for all to authenticated using (bucket_id='accreditations' and public.is_admin()) with check (bucket_id='accreditations' and public.is_admin());
