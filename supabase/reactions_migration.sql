-- Message reactions migration for existing deployments.
alter table if exists public.messages
add column if not exists reactions jsonb not null default '{}'::jsonb;
