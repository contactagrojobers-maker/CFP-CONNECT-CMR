-- Demandes publiques de revendication de fiche CFP.
-- À exécuter une seule fois dans Supabase > SQL Editor.

create table if not exists public.claim_requests (
  id uuid primary key default gen_random_uuid(),
  center_id uuid references public.centers(id) on delete set null,
  center_name text not null check (char_length(trim(center_name)) between 2 and 180),
  full_name text not null check (char_length(trim(full_name)) between 2 and 160),
  function_title text not null check (char_length(trim(function_title)) between 2 and 100),
  phone text not null check (char_length(trim(phone)) between 6 and 40),
  status public.claim_status not null default 'pending',
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.claim_requests enable row level security;

create policy "public submits claim requests"
on public.claim_requests
for insert
to anon, authenticated
with check (status = 'pending');

create policy "admins read claim requests"
on public.claim_requests
for select
to authenticated
using (public.is_admin());

create policy "admins update claim requests"
on public.claim_requests
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());
