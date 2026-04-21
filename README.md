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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
