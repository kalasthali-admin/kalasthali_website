import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const admins = new Set(['admin.kalasthali@gmail.com', 'nisharohilla651@gmail.com']);
const headers = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': 'https://kalasthali.co', 'Access-Control-Allow-Headers': 'authorization, apikey, content-type' };
Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers });
  const authorization = request.headers.get('authorization') ?? '';
  const client = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { global: { headers: { Authorization: authorization } } });
  const { data: { user } } = await client.auth.getUser();
  if (!user || !admins.has((user.email ?? '').toLowerCase())) return new Response(JSON.stringify({ error: 'Unauthorized.' }), { status: 403, headers });
  const endpoint = (await request.json().catch(() => ({}))).endpoint;
  if (typeof endpoint !== 'string') return new Response(JSON.stringify({ error: 'Invalid subscription.' }), { status: 400, headers });
  const { error } = await client.from('admin_push_subscriptions').delete().eq('user_id', user.id).eq('endpoint', endpoint);
  return new Response(JSON.stringify(error ? { error: 'Could not remove subscription.' } : { success: true }), { status: error ? 500 : 200, headers });
});
