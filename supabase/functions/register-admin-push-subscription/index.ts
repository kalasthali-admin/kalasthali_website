import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const admins = new Set(['admin.kalasthali@gmail.com', 'nisharohilla651@gmail.com']);
const allowedOrigins = new Set(['https://kalasthali.co', 'https://www.kalasthali.co']);
const headers = (origin: string | null) => ({
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': allowedOrigins.has(origin ?? '') ? origin! : 'https://kalasthali.co',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
});
const reply = (status: number, body: Record<string, unknown>, origin: string | null) => new Response(JSON.stringify(body), { status, headers: headers(origin) });

Deno.serve(async (request) => {
  const origin = request.headers.get('origin');
  if (request.method === 'OPTIONS') return new Response('ok', { headers: headers(origin) });
  const authorization = request.headers.get('authorization') ?? '';
  const url = Deno.env.get('SUPABASE_URL')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const auth = createClient(url, serviceKey, { global: { headers: { Authorization: authorization } } });
  const { data: { user } } = await auth.auth.getUser();
  if (!user || !admins.has((user.email ?? '').toLowerCase())) return reply(403, { error: 'Unauthorized.' }, origin);
  const body = await request.json().catch(() => null);
  const subscription = body?.subscription;
  const endpoint = subscription?.endpoint;
  const p256dh = subscription?.keys?.p256dh;
  const authKey = subscription?.keys?.auth;
  if (typeof endpoint !== 'string' || !endpoint.startsWith('https://') || typeof p256dh !== 'string' || typeof authKey !== 'string') return reply(400, { error: 'Invalid push subscription.' }, origin);
  const { error } = await auth.from('admin_push_subscriptions').upsert({ user_id: user.id, endpoint, p256dh, auth: authKey, updated_at: new Date().toISOString() }, { onConflict: 'endpoint' });
  return error ? reply(500, { error: 'Could not save subscription.' }, origin) : reply(200, { success: true }, origin);
});
