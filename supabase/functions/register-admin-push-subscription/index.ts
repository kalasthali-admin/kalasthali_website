import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const admins = new Set(['admin.kalasthali@gmail.com', 'nisharohilla651@gmail.com']);
const headers = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': 'https://kalasthali.co', 'Access-Control-Allow-Headers': 'authorization, apikey, content-type' };
const reply = (status: number, body: Record<string, unknown>) => new Response(JSON.stringify(body), { status, headers });

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers });
  const authorization = request.headers.get('authorization') ?? '';
  const url = Deno.env.get('SUPABASE_URL')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const auth = createClient(url, serviceKey, { global: { headers: { Authorization: authorization } } });
  const { data: { user } } = await auth.auth.getUser();
  if (!user || !admins.has((user.email ?? '').toLowerCase())) return reply(403, { error: 'Unauthorized.' });
  const body = await request.json().catch(() => null);
  const subscription = body?.subscription;
  const endpoint = subscription?.endpoint;
  const p256dh = subscription?.keys?.p256dh;
  const authKey = subscription?.keys?.auth;
  if (typeof endpoint !== 'string' || !endpoint.startsWith('https://') || typeof p256dh !== 'string' || typeof authKey !== 'string') return reply(400, { error: 'Invalid push subscription.' });
  const { error } = await auth.from('admin_push_subscriptions').upsert({ user_id: user.id, endpoint, p256dh, auth: authKey, updated_at: new Date().toISOString() }, { onConflict: 'endpoint' });
  return error ? reply(500, { error: 'Could not save subscription.' }) : reply(200, { success: true });
});
