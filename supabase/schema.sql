-- Run this script in Supabase SQL Editor.
-- It creates the tables used by the Flutter app and basic RLS policies.

create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  displayName text not null,
  photoUrl text,
  lastSeen timestamptz not null default now(),
  isOnline boolean not null default false,
  fcmToken text,
  createdAt timestamptz not null default now()
);

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  participants text[] not null default '{}',
  participantNames jsonb not null default '{}'::jsonb,
  participantPhotos jsonb not null default '{}'::jsonb,
  lastMessage text not null default '',
  lastMessageTime timestamptz not null default now(),
  lastMessageSenderId text not null default '',
  type text not null default 'individual',
  unreadCount jsonb not null default '{}'::jsonb,
  typingUsers text[] not null default '{}',
  createdAt timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  chatId uuid not null references public.chats(id) on delete cascade,
  senderId text not null,
  senderName text not null,
  text text,
  imageUrl text,
  audioUrl text,
  audioDurationMs integer,
  type text not null default 'text',
  replyTo jsonb,
  status text not null default 'sent',
  readBy text[] not null default '{}',
  reactions jsonb not null default '{}'::jsonb,
  deletedBy text[] not null default '{}',
  isDeleted boolean not null default false,
  timestamp timestamptz not null default now()
);

create table if not exists public.friend_requests (
  id text primary key,
  fromId text not null,
  fromName text not null,
  fromEmail text not null,
  fromPhoto text,
  toId text not null,
  status text not null default 'pending',
  timestamp timestamptz not null default now()
);

create index if not exists idx_users_email on public.users(email);
create index if not exists idx_chats_participants_gin on public.chats using gin(participants);
create index if not exists idx_messages_chatid_timestamp on public.messages(chatId, timestamp desc);
create index if not exists idx_friend_requests_to_status on public.friend_requests(toId, status);

alter table public.users enable row level security;
alter table public.chats enable row level security;
alter table public.messages enable row level security;
alter table public.friend_requests enable row level security;

-- Basic development-safe policies for authenticated users.
-- Tighten these for production.
drop policy if exists users_authenticated_all on public.users;
create policy users_authenticated_all
on public.users
for all
to authenticated
using (true)
with check (true);

drop policy if exists chats_authenticated_all on public.chats;
create policy chats_authenticated_all
on public.chats
for all
to authenticated
using (true)
with check (true);

drop policy if exists messages_authenticated_all on public.messages;
create policy messages_authenticated_all
on public.messages
for all
to authenticated
using (true)
with check (true);

drop policy if exists friend_requests_authenticated_all on public.friend_requests;
create policy friend_requests_authenticated_all
on public.friend_requests
for all
to authenticated
using (true)
with check (true);

-- Optional: auto-create user profile on signup.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email, displayName, createdAt, lastSeen, isOnline)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'displayName', split_part(coalesce(new.email, 'user'), '@', 1)),
    now(),
    now(),
    false
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Storage bucket for profile/chat media uploads.
insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists media_authenticated_upload on storage.objects;
create policy media_authenticated_upload
on storage.objects
for insert
to authenticated
with check (bucket_id = 'media');

drop policy if exists media_authenticated_update on storage.objects;
create policy media_authenticated_update
on storage.objects
for update
to authenticated
using (bucket_id = 'media')
with check (bucket_id = 'media');

drop policy if exists media_authenticated_delete on storage.objects;
create policy media_authenticated_delete
on storage.objects
for delete
to authenticated
using (bucket_id = 'media');
