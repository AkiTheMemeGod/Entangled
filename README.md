# entangled

A new Flutter project.

## Supabase Setup

Run the SQL schema before signing up users:

1. Open Supabase Dashboard -> SQL Editor.
2. Run [supabase/schema.sql](supabase/schema.sql).
3. Confirm tables exist under public schema: `users`, `chats`, `messages`, `friend_requests`.

If signup fails with `over_email_send_rate_limit`:

1. Wait a few minutes and try again.
2. For development, optionally disable email confirmation in Supabase Auth settings to avoid repeated email sends while testing.

## Notifications (Pure Supabase)

This project is configured for pure Supabase in-app notifications (no Firebase dependency).

Backend notification delivery is done with a Supabase Edge Function + DB trigger:

1. Deploy edge function from `supabase/functions/push-notify/index.ts`.
2. Run `supabase/push_notifications.sql` in Supabase SQL Editor.
3. Set these database settings in SQL Editor:
	- `alter database postgres set app.settings.push_edge_url = 'https://<project-ref>.functions.supabase.co/push-notify';`
	- `alter database postgres set app.settings.push_webhook_secret = '<same-secret-you-set-on-edge-function>';`
4. Set edge function secrets:
	- `SUPABASE_URL`
	- `SUPABASE_SERVICE_ROLE_KEY`
	- `PUSH_WEBHOOK_SECRET`

### Console Checklist

- In Supabase, verify function deployment and logs in Edge Functions.
- In Supabase SQL editor, run the push SQL file and database setting commands.
- Confirm rows are created in `public.notifications` when new chat messages are inserted.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
