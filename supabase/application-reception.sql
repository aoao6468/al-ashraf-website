-- Al-Ashraf: volunteer and training application reception switch
-- Run once in Supabase SQL Editor.
create table if not exists public.application_settings (
    id integer primary key check (id = 1),
    is_open boolean not null default true,
    updated_at timestamptz not null default now()
);
insert into public.application_settings (id, is_open)
values (1, true) on conflict (id) do nothing;
alter table public.application_settings enable row level security;
drop policy if exists "Anyone can read application reception setting" on public.application_settings;
create policy "Anyone can read application reception setting"
on public.application_settings for select to anon, authenticated using (true);
drop policy if exists "Approved admins can update application reception setting" on public.application_settings;
create policy "Approved admins can update application reception setting"
on public.application_settings for update to authenticated
using (exists (select 1 from public.profiles p where p.user_id = auth.uid() and p.role = 'admin' and p.status = 'approved'))
with check (exists (select 1 from public.profiles p where p.user_id = auth.uid() and p.role = 'admin' and p.status = 'approved'));
grant select on public.application_settings to anon, authenticated;
grant update on public.application_settings to authenticated;
