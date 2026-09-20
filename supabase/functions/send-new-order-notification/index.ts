import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import webpush from 'npm:web-push@3.6.7';

type OrderItem = { quantity?: number };
type WebhookPayload = {
  type?: string;
  schema?: string;
  table?: string;
  record?: { order_id?: string };
};

const adminEmails = new Set([
  'admin.kalasthali@gmail.com',
  'nisharohilla651@gmail.com',
]);
const jsonHeaders = { 'Content-Type': 'application/json' };
const reply = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), { status, headers: jsonHeaders });

function itemCount(items: unknown) {
  if (!Array.isArray(items)) return 1;
  return items.reduce((total, item: OrderItem) => {
    const quantity = Number(item?.quantity);
    return total + (Number.isSafeInteger(quantity) && quantity > 0 ? quantity : 1);
  }, 0);
}

Deno.serve(async (request) => {
  const secret = Deno.env.get('NEW_ORDER_NOTIFICATION_WEBHOOK_SECRET');
  if (!secret || request.headers.get('x-new-order-notification-secret') !== secret) {
    return reply(401, { error: 'Unauthorized.' });
  }

  const payload = await request.json().catch(() => null) as WebhookPayload | null;
  if (payload?.type !== 'INSERT' || payload.schema !== 'public' ||
      payload.table !== 'sales' || !payload.record?.order_id) {
    return reply(202, { skipped: true });
  }

  const url = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const vapidPublicKey = Deno.env.get('VAPID_PUBLIC_KEY');
  const vapidPrivateKey = Deno.env.get('VAPID_PRIVATE_KEY');
  const vapidSubject = Deno.env.get('VAPID_SUBJECT') ?? 'mailto:contact@kalasthali.co';
  if (!url || !serviceRoleKey || !vapidPublicKey || !vapidPrivateKey) {
    console.error('New-order push notification service is not configured.');
    return reply(500, { error: 'Push notification service is not configured.' });
  }

  const supabase = createClient(url, serviceRoleKey);
  const { data: sale, error: saleError } = await supabase
    .from('sales')
    .select('order_id,amount,items')
    .eq('order_id', payload.record.order_id)
    .maybeSingle();
  if (saleError || !sale || !Number.isSafeInteger(sale.amount) || sale.amount < 1) {
    console.error('Could not load authoritative sale for push notification.', {
      orderId: payload.record.order_id,
      error: saleError?.message,
    });
    return reply(400, { error: 'Sale record is unavailable.' });
  }

  const { data: subscriptions, error: subscriptionError } = await supabase
    .from('admin_push_subscriptions')
    .select('id,user_id,endpoint,p256dh,auth');
  if (subscriptionError) return reply(500, { error: 'Could not load subscriptions.' });

  webpush.setVapidDetails(vapidSubject, vapidPublicKey, vapidPrivateKey);
  const body = JSON.stringify({
    type: 'new_order',
    title: 'New Kalasthali Order 🛍️',
    body: `₹${sale.amount.toLocaleString('en-IN')} · ${itemCount(sale.items)} items\nOrder #${sale.order_id}`,
    order_id: sale.order_id,
    url: 'https://kalasthali.co/admin',
  });
  let authorized = 0;
  let sent = 0;
  let expired = 0;
  let failed = 0;

  await Promise.all((subscriptions ?? []).map(async (subscription) => {
    const { data } = await supabase.auth.admin.getUserById(subscription.user_id);
    if (!data.user || !adminEmails.has((data.user.email ?? '').toLowerCase())) return;
    authorized += 1;
    try {
      await webpush.sendNotification({
        endpoint: subscription.endpoint,
        keys: { p256dh: subscription.p256dh, auth: subscription.auth },
      }, body);
      sent += 1;
    } catch (error) {
      const statusCode = (error as { statusCode?: number }).statusCode;
      if (statusCode === 404 || statusCode === 410) {
        expired += 1;
        await supabase.from('admin_push_subscriptions').delete().eq('id', subscription.id);
      } else {
        failed += 1;
        console.error('Push delivery failed.', { subscriptionId: subscription.id, statusCode });
      }
    }
  }));

  const summary = { subscriptionsFound: subscriptions?.length ?? 0, authorized, sent, expired, failed };
  console.info('New-order push notification completed.', summary);
  return reply(200, summary);
});
