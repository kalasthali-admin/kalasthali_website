# Order Receipt Email Webhook

The Flutter application does not invoke this function. A successful Razorpay
signature verification creates a complete `public.sales` row, and this database
webhook invokes the function after that insert.

## Deploy and configure secrets

Deploy the function without JWT verification because Supabase Database Webhooks
authenticate with the custom header below:

```sh
supabase functions deploy send-order-receipt --no-verify-jwt
supabase secrets set \
  RESEND_API_KEY=your_resend_sending_key \
  RESEND_FROM_EMAIL='Kalasthali By Nisha <orders@your-verified-domain.com>' \
  ORDER_RECEIPT_WEBHOOK_SECRET=generate-a-long-random-value
```

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are available to deployed Edge
Functions by default. Never place any of these values in Flutter or web files.

## Database trigger with pg_net

Enable the `pg_net` extension in **Database > Extensions**, then create a Vault
secret with the same value used by `ORDER_RECEIPT_WEBHOOK_SECRET`:

```sql
select vault.create_secret(
  'replace-with-your-private-webhook-secret',
  'order_receipt_webhook_secret'
);
```

Run this trigger setup in the SQL Editor:

```sql
create or replace function public.invoke_order_receipt()
returns trigger
language plpgsql
security definer
set search_path = public, net, vault
as $$
declare
  webhook_secret text;
begin
  select decrypted_secret into webhook_secret
  from vault.decrypted_secrets
  where name = 'order_receipt_webhook_secret';

  if webhook_secret is null then
    raise exception 'Missing order receipt webhook secret.';
  end if;

  perform net.http_post(
    url := 'https://dddriininznavwrsrgww.supabase.co/functions/v1/send-order-receipt',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-order-receipt-secret', webhook_secret
    ),
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', TG_TABLE_NAME,
      'schema', TG_TABLE_SCHEMA,
      'record', to_jsonb(NEW),
      'old_record', null
    ),
    timeout_milliseconds := 10000
  );
  return NEW;
end;
$$;

drop trigger if exists send_order_receipt_on_sale on public.sales;
create trigger send_order_receipt_on_sale
after insert on public.sales
for each row
execute function public.invoke_order_receipt();
```

The function only accepts the `INSERT` payload for `public.sales`. It records
`invoice_sent_at` only after Resend accepts the email. The Resend request also
uses the order ID as an idempotency key, so retries do not deliver a duplicate
email.

If an earlier version of `send-order-receipt` is already deployed, update that
function before enabling the trigger so it validates the webhook secret and
reads `unit_price` / `line_total` item fields. The checked-in function is the
receipt-function reference implementation for that deployment.
