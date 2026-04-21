-- Supabase in-app notification bridge for new messages.
-- Run this in Supabase SQL Editor after deploying the edge function.

create extension if not exists pg_net;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.users(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  chat_id uuid not null references public.chats(id) on delete cascade,
  type text not null default 'new_message',
  title text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_recipient_created_at
  on public.notifications (recipient_id, created_at desc);

alter table public.notifications enable row level security;

drop policy if exists notifications_owner_read on public.notifications;
create policy notifications_owner_read
on public.notifications
for select
to authenticated
using (recipient_id = auth.uid());

drop policy if exists notifications_owner_update on public.notifications;
create policy notifications_owner_update
on public.notifications
for update
to authenticated
using (recipient_id = auth.uid())
with check (recipient_id = auth.uid());

create table if not exists public.app_config (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

-- Upsert these values for your environment.
-- Keep push_webhook_secret equal to the edge function secret PUSH_WEBHOOK_SECRET.
insert into public.app_config (key, value)
values
  ('push_edge_url', 'https://<project-ref>.functions.supabase.co/functions/v1/push-notify'),
  ('push_webhook_secret', '<same-secret-as-PUSH_WEBHOOK_SECRET>')
on conflict (key) do update
set value = excluded.value,
    updated_at = now();

create or replace function public.notify_push_on_new_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  edge_url text;
  webhook_secret text;
begin
  select value into edge_url
  from public.app_config
  where key = 'push_edge_url';

  select value into webhook_secret
  from public.app_config
  where key = 'push_webhook_secret';

  if edge_url is null or edge_url = '' then
    return new;
  end if;

  perform net.http_post(
    url := edge_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', coalesce(webhook_secret, '')
    ),
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'messages',
      'record', to_jsonb(new)
    )
  );

  return new;
end;
$$;

drop trigger if exists trg_notify_push_on_new_message on public.messages;
create trigger trg_notify_push_on_new_message
after insert on public.messages
for each row execute function public.notify_push_on_new_message();
