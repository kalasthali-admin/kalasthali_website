import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const admins = new Set(['admin.kalasthali@gmail.com', 'nisharohilla651@gmail.com']);
const allowedOrigins = new Set(['https://kalasthali.co', 'https://www.kalasthali.co']);
const responseOrigin = (origin: string | null) =>
  allowedOrigins.has(origin ?? '') || /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin ?? '')
    ? origin!
    : 'https://kalasthali.co';
const headers = (origin: string | null) => ({
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': responseOrigin(origin),
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
});
const reply = (status: number, body: Record<string, unknown>, origin: string | null) => new Response(JSON.stringify(body), { status, headers: headers(origin) });

Deno.serve(async (request) => {
  const origin = request.headers.get('origin');
  if (request.method === 'OPTIONS') return new Response('ok', { headers: headers(origin) });
  if (request.method !== 'POST') return reply(405, { error: 'Method not allowed.' }, origin);

  try {
    const token = (request.headers.get('authorization') ?? '').replace(/^Bearer\s+/i, '');
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );
    const { data: { user }, error: userError } = await admin.auth.getUser(token);
    if (userError || !user || !admins.has((user.email ?? '').toLowerCase())) {
      return reply(403, { error: 'Unauthorized.' }, origin);
    }

    const body = await request.json().catch(() => null);
    const subscription = body?.subscription;
    const endpoint = subscription?.endpoint;
    const p256dh = subscription?.keys?.p256dh;
    const authKey = subscription?.keys?.auth;
    if (typeof endpoint !== 'string' || !endpoint.startsWith('https://') ||
        typeof p256dh !== 'string' || typeof authKey !== 'string') {
      return reply(400, { error: 'Invalid push subscription.' }, origin);
    }

    const { error } = await admin.from('admin_push_subscriptions').upsert({
      user_id: user.id,
      endpoint,
      p256dh,
      auth: authKey,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'endpoint' });
    if (error) {
      console.error('Could not save admin push subscription.', error);
      return reply(500, { error: 'Could not save subscription.' }, origin);
    }
    return reply(200, { success: true }, origin);
  } catch (error) {
    console.error('Push subscription registration failed.', error);
    return reply(500, { error: 'Could not register notifications.' }, origin);
  }
});
