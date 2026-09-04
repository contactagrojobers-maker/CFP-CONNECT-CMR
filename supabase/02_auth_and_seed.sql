-- Exécuter après schema.sql. Ce script peut être relancé sans dupliquer les données.

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public
as $$ begin
  insert into public.profiles(id,full_name,phone,role)
  values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),new.phone,'learner')
  on conflict(id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

insert into public.profiles(id,full_name,phone,role)
select id,coalesce(raw_user_meta_data->>'full_name',''),phone,'learner'::public.user_role from auth.users
on conflict(id) do nothing;

grant usage on schema public to anon, authenticated;
grant select on public.regions,public.departments,public.cities,public.programs to anon,authenticated;
grant select on public.centers,public.center_programs,public.center_photos,public.reviews to anon,authenticated;
grant insert on public.contact_requests to anon,authenticated;
grant select,insert,update,delete on all tables in schema public to authenticated;
grant usage,select on all sequences in schema public to authenticated;
grant execute on function public.is_admin() to anon,authenticated;
grant execute on function public.manages_center(uuid) to anon,authenticated;

drop policy if exists "admins manage profiles" on public.profiles;
create policy "admins manage profiles" on public.profiles for all using(public.is_admin()) with check(public.is_admin());
drop policy if exists "admins manage programs" on public.programs;
create policy "admins manage programs" on public.programs for all to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "managers manage center programs" on public.center_programs;
create policy "managers manage center programs" on public.center_programs for all using(public.manages_center(center_id)) with check(public.manages_center(center_id));
drop policy if exists "managers manage center photos" on public.center_photos;
create policy "managers manage center photos" on public.center_photos for all using(public.manages_center(center_id)) with check(public.manages_center(center_id));

insert into public.programs(name,category) values
('Secrétariat bureautique','Gestion'),('Maintenance informatique','Numérique'),('Comptabilité informatisée','Gestion'),('Infographie','Numérique'),
('Conduite d''engins lourds','Technique'),('Mécanique automobile','Technique'),('Électricité automobile','Technique'),('Assistant dentaire','Santé'),
('Auxiliaire de vie sociale','Santé'),('Secrétariat médical','Santé'),('Marketing digital','Numérique'),('Comptabilité','Gestion'),
('Coiffure esthétique','Beauté'),('Électricité bâtiment','Technique'),('Froid et climatisation','Technique'),('Énergie solaire','Technique'),
('Gestion des ressources humaines','Gestion'),('Informatique de gestion','Numérique'),('Couture et stylisme','Mode'),('Modélisme','Mode'),
('Production animale','Agriculture'),('Entrepreneuriat agropastoral','Agriculture'),('Transformation agroalimentaire','Agriculture'),
('Cuisine et restauration','Hôtellerie'),('Hôtellerie','Hôtellerie'),('Pâtisserie','Hôtellerie'),('Développement web','Numérique')
on conflict(name) do nothing;

with bertoua as (select id from public.cities where name='Bertoua' limit 1)
insert into public.centers(city_id,name,slug,acronym,center_type,district,description,phone,whatsapp,accreditation_number,accreditation_verified,status)
select bertoua.id,v.name,v.slug,v.acronym,v.center_type,v.district,v.description,v.phone,v.whatsapp,v.accreditation,v.verified,'published'::public.center_status
from bertoua cross join (values
(E'ISHEM''S Academy','ishems-academy','IA','CFP privé bilingue','Mont Cameroun','Centre bilingue orienté vers des compétences professionnelles concrètes.','+237 694 575 967','237694575967','Centre agréé MINEFOP',true),
('CFP-CIC Bertoua','cfp-cic','CIC','Centre professionnel privé','Koumé-Bonis, face SOACAM','Centre spécialisé dans les métiers techniques et la conduite des engins.','+237 698 512 525','237698512525','Agrément MINEFOP n°000048',true),
('CEFOPROMSA','cefopromsa','CEF','Centre de formation privé','Nkolbikon','Centre orienté vers les métiers de la santé et de l’accompagnement social.','+237 677 320 184','237677320184','Informations à confirmer',false),
('Institut La Réussite','institut-la-reussite','ILR','Institut professionnel privé','Tigaza','Formation dans le numérique, la gestion et les métiers de service.','+237 650 884 221','237650884221','Informations à confirmer',false),
('CFP Multitech Bertoua','cfp-multitech','CMB','Centre professionnel privé','Mokolo','Formation aux métiers techniques et à la maintenance.','+237 600 000 105','237600000105','Données de démonstration à vérifier',false),
('Institut Professionnel Horizon','institut-horizon','IPH','Institut professionnel privé','Nkolbikon','Parcours en gestion, administration et outils numériques.','+237 600 000 106','237600000106','Données de démonstration à vérifier',false),
('Académie des Métiers de la Mode de l’Est','academie-mode-est','AMME','Centre professionnel privé','Mokolo II','Formation en couture, stylisme et métiers de la beauté.','+237 600 000 107','237600000107','Données de démonstration à vérifier',false),
('CFP Agropastoral de l’Est','cfp-agropastoral-est','CAPE','Centre professionnel privé','Bonis','Formation aux métiers agricoles et à la transformation agroalimentaire.','+237 600 000 108','237600000108','Données de démonstration à vérifier',false),
('École Hôtelière de Bertoua','ecole-hoteliere-bertoua','EHB','École professionnelle privée','Tigaza','Formation en hôtellerie, restauration et services d’accueil.','+237 600 000 109','237600000109','Données de démonstration à vérifier',false),
('Centre Numérique de Bertoua','centre-numerique-bertoua','CNB','Centre professionnel privé','Enia','Formation aux métiers du numérique et de la communication.','+237 600 000 110','237600000110','Données de démonstration à vérifier',false)
) as v(name,slug,acronym,center_type,district,description,phone,whatsapp,accreditation,verified)
on conflict(slug) do update set name=excluded.name,description=excluded.description,updated_at=now();

insert into public.center_programs(center_id,program_id,duration,diploma,admission_level)
select c.id,p.id,v.duration,v.diploma,v.admission
from (values
('ishems-academy','Secrétariat bureautique','12 mois','DQP','BEPC'),('ishems-academy','Maintenance informatique','12 mois','DQP','BEPC'),('ishems-academy','Comptabilité informatisée','12 mois','DQP','BEPC'),('ishems-academy','Infographie','9 mois','CQP','CEP'),
('cfp-cic','Conduite d''engins lourds','6 mois','CQP','CEP'),('cfp-cic','Mécanique automobile','12 mois','DQP','BEPC'),('cfp-cic','Électricité automobile','9 mois','CQP','CEP'),
('cefopromsa','Assistant dentaire','12 mois','DQP','BEPC'),('cefopromsa','Auxiliaire de vie sociale','9 mois','CQP','CEP'),('cefopromsa','Secrétariat médical','12 mois','DQP','BEPC'),
('institut-la-reussite','Marketing digital','6 mois','Attestation','Tous niveaux'),('institut-la-reussite','Comptabilité','12 mois','DQP','BEPC'),('institut-la-reussite','Coiffure esthétique','9 mois','CQP','CEP'),
('cfp-multitech','Électricité bâtiment','9 mois','CQP','CEP'),('cfp-multitech','Froid et climatisation','12 mois','DQP','BEPC'),('cfp-multitech','Énergie solaire','6 mois','Attestation','Tous niveaux'),
('institut-horizon','Secrétariat bureautique','12 mois','DQP','BEPC'),('institut-horizon','Gestion des ressources humaines','12 mois','DQP','Probatoire'),('institut-horizon','Informatique de gestion','9 mois','CQP','BEPC'),
('academie-mode-est','Couture et stylisme','12 mois','DQP','CEP'),('academie-mode-est','Modélisme','9 mois','CQP','CEP'),('academie-mode-est','Coiffure esthétique','9 mois','CQP','CEP'),
('cfp-agropastoral-est','Production animale','12 mois','DQP','BEPC'),('cfp-agropastoral-est','Entrepreneuriat agropastoral','9 mois','CQP','CEP'),('cfp-agropastoral-est','Transformation agroalimentaire','6 mois','Attestation','Tous niveaux'),
('ecole-hoteliere-bertoua','Cuisine et restauration','12 mois','DQP','BEPC'),('ecole-hoteliere-bertoua','Hôtellerie','12 mois','DQP','BEPC'),('ecole-hoteliere-bertoua','Pâtisserie','9 mois','CQP','CEP'),
('centre-numerique-bertoua','Développement web','9 mois','CQP','BEPC'),('centre-numerique-bertoua','Infographie','6 mois','Attestation','Tous niveaux'),('centre-numerique-bertoua','Marketing digital','6 mois','Attestation','Tous niveaux')
) as v(slug,program_name,duration,diploma,admission)
join public.centers c on c.slug=v.slug
join public.programs p on p.name=v.program_name
on conflict(center_id,program_id) do update set duration=excluded.duration,diploma=excluded.diploma,admission_level=excluded.admission_level;

-- Après avoir créé votre propre utilisateur dans Authentication > Users,
-- remplacez l’adresse ci-dessous puis exécutez cette instruction séparément :
-- update public.profiles set role='admin'
-- where id=(select id from auth.users where email='VOTRE_EMAIL_ADMIN');
