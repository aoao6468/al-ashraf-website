-- Al-Ashraf: volunteer and training application reception switch
-- Run once in Supabase SQL Editor.
create table if not exists public.application_settings (
    id integer primary key check (id = 1),
    is_open boolean not null default true,
    updated_at timestamptz not null default now()
);
-- Upgrade an already-existing table safely (CREATE TABLE IF NOT EXISTS
-- does not add columns to a table that was created earlier).
alter table public.application_settings
    add column if not exists is_open boolean not null default true;

alter table public.application_settings
    add column if not exists updated_at timestamptz not null default now();

insert into public.application_settings (id, is_open)
values (1, true) on conflict (id) do nothing;

alter table public.application_settings enable row level security;
drop policy if exists "Anyone can read application reception setting" on public.application_settings;
create policy "Anyone can read application reception setting"
on public.application_settings for select to anon, authenticated using (true);

drop policy if exists "Approved admins can update application reception setting" on public.application_settings;
create policy "Approved admins can update application reception setting"
on public.application_settings for update to authenticated
using (exists (
    select 1 from public.profiles p
    where p.user_id = auth.uid() and p.role = 'admin' and p.status = 'approved'
))
with check (exists (
    select 1 from public.profiles p
    where p.user_id = auth.uid() and p.role = 'admin' and p.status = 'approved'
));
grant select on public.application_settings to anon, authenticated;
grant update on public.application_settings to authenticated;

-- Server-side enforcement: direct API inserts are rejected while reception is closed.
create or replace function public.enforce_application_reception()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    reception_open boolean;
begin
    select is_open into reception_open
    from public.application_settings
    where id = 1;

    if coalesce(reception_open, false) = false then
        raise exception 'APPLICATIONS_CLOSED'
            using errcode = 'P0001',
                  detail = 'Volunteer and training applications are currently closed.';
    end if;

    return new;
end;
$$;

drop trigger if exists enforce_application_reception_before_insert on public.volunteer_applications;
create trigger enforce_application_reception_before_insert
before insert on public.volunteer_applications
for each row execute function public.enforce_application_reception();
