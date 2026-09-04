-- Autorise uniquement les administrateurs CFP Connect à créer ou modifier
-- les filières depuis l'espace d'administration.
-- Ce script est idempotent et peut être relancé sans risque.

grant select, insert, update, delete on public.programs to authenticated;
grant usage, select on sequence public.programs_id_seq to authenticated;

drop policy if exists "admins manage programs" on public.programs;
create policy "admins manage programs"
on public.programs
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());
