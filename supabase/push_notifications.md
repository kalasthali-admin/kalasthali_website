# Admin Web Push Setup

1. Generate VAPID keys locally: `npx web-push generate-vapid-keys --json`.
2. Set `VAPID_PUBLIC_KEY` (Flutter `--dart-define`) and set `VAPID_PRIVATE_KEY` only as a Supabase Edge Function secret. Also set the public key in Supabase because the sender needs both halves of the pair.
3. Create a random `NEW_ORDER_NOTIFICATION_WEBHOOK_SECRET`, then set these Supabase secrets: `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT` (for example `mailto:contact@kalasthali.co`), and `NEW_ORDER_NOTIFICATION_WEBHOOK_SECRET`.
4. Deploy `register-admin-push-subscription`, `unregister-admin-push-subscription`, and `send-new-order-notification` with `supabase functions deploy <name>`.
5. Run `supabase/admin_push_subscriptions.sql` in Supabase SQL Editor.

Create a Database Webhook for `public.sales` `INSERT` events pointing to `https://dddriininznavwrsrgww.supabase.co/functions/v1/send-new-order-notification`. Add header `x-new-order-notification-secret` with the matching secret. The function fetches the sale itself and checks subscription owners against the fixed server-side admin allowlist at send time.
