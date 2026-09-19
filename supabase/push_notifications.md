# Admin Web Push Setup

1. Generate VAPID keys locally: `npx web-push generate-vapid-keys --json`.
2. Set `VAPID_PUBLIC_KEY` (Flutter `--dart-define`) and set `VAPID_PRIVATE_KEY` only as a Supabase Edge Function secret.
3. Deploy `register-admin-push-subscription` and `unregister-admin-push-subscription` with `supabase functions deploy <name>`.
4. Run `supabase/admin_push_subscriptions.sql` in Supabase SQL Editor.

The send function must be deployed separately after selecting a standards-compliant Web Push library for Supabase Edge Runtime. Configure a Database Webhook on `public.sales` INSERT to call it with a server-only webhook secret. It must fetch the order row itself and check each subscription's user email against the fixed Edge Function allowlist before delivery.
