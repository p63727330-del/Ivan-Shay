-- RSVP aberto: sem convite individual e sem limite de acompanhantes.
alter table public.guests alter column invitation_code drop not null;
alter table public.guests drop column if exists max_companions;
alter table public.guests drop column if exists companions_count;

create table if not exists public.guest_companions (
  id uuid primary key default gen_random_uuid(),
  guest_id uuid not null references public.guests(id) on delete cascade,
  full_name text not null check (length(trim(full_name)) > 0),
  created_at timestamptz not null default now()
);
create index if not exists guest_companions_guest_id_idx on public.guest_companions(guest_id);
alter table public.guest_companions enable row level security;

create policy "Admins manage guest companions" on public.guest_companions
  for all to authenticated using ((select private.is_admin()))
  with check ((select private.is_admin()));

create or replace function public.submit_rsvp(
  p_full_name text,
  p_companion_names text[] default array[]::text[],
  p_guest_message text default null
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_guest_id uuid;
  clean_name text;
begin
  if p_full_name is null or length(trim(p_full_name)) < 2 then
    raise exception 'Informe seu nome completo.';
  end if;
  if p_companion_names is not null and exists (
    select 1 from unnest(p_companion_names) n
    where n is null or length(trim(n)) < 2
  ) then
    raise exception 'Informe o nome completo de cada acompanhante.';
  end if;
  insert into public.guests(full_name, rsvp_status, guest_message, responded_at)
  values (trim(p_full_name), 'confirmed', nullif(trim(p_guest_message), ''), now())
  returning id into new_guest_id;
  if p_companion_names is not null then
    foreach clean_name in array p_companion_names loop
      if length(trim(clean_name)) > 0 then
        insert into public.guest_companions(guest_id, full_name)
        values (new_guest_id, trim(clean_name));
      end if;
    end loop;
  end if;
  return new_guest_id;
end;
$$;
revoke all on function public.submit_rsvp(text,text[],text) from public;
grant execute on function public.submit_rsvp(text,text[],text) to anon, authenticated;
grant select, insert, update, delete on public.guest_companions to authenticated;
