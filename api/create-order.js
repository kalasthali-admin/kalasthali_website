const Razorpay = require('razorpay');

const supabaseUrl =
  process.env.SUPABASE_URL || 'https://dddriininznavwrsrgww.supabase.co';

function json(res, status, value) {
  res.status(status).json(value);
}

function readBody(req) {
  if (req.body && typeof req.body === 'object') return req.body;
  if (typeof req.body !== 'string' || req.body.length === 0) return {};
  try {
    return JSON.parse(req.body);
  } catch (_) {
    return {};
  }
}

function razorpayClient() {
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;
  if (!keyId || !keySecret) return null;
  return new Razorpay({ key_id: keyId, key_secret: keySecret });
}

async function authenticatedUser(req) {
  const token = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  const supabaseKey =
    process.env.SUPABASE_PUBLISHABLE_KEY ||
    process.env.SUPABASE_API_KEY ||
    process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!token || !supabaseKey) return null;

  const response = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      apikey: supabaseKey,
      Authorization: `Bearer ${token}`,
    },
  });
  if (!response.ok) return null;
  return response.json();
}

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return json(res, 405, { error: 'Method not allowed.' });
  }

  const user = await authenticatedUser(req);
  if (!user) return json(res, 401, { error: 'Log in before creating an order.' });

  const body = readBody(req);
  const amount = Number(body.amount);
  const currency = typeof body.currency === 'string' ? body.currency : 'INR';
  const receipt = typeof body.receipt === 'string' ? body.receipt : `order_${Date.now()}`;

  if (!Number.isInteger(amount) || amount < 100) {
    return json(res, 400, { error: 'Amount must be at least 100 paise.' });
  }

  const client = razorpayClient();
  if (!client) {
    return json(res, 500, { error: 'Razorpay is not configured.' });
  }

  try {
    const order = await client.orders.create({
      amount,
      currency,
      receipt,
      notes: {
        user_id: user.id,
        ...(body.notes && typeof body.notes === 'object' ? body.notes : {}),
      },
    });
    return json(res, 200, {
      key_id: process.env.RAZORPAY_KEY_ID,
      order_id: order.id,
      amount: order.amount,
      currency: order.currency,
    });
  } catch (error) {
    console.error('Razorpay order creation failed:', error);
    return json(res, 500, { error: 'Could not create Razorpay order.' });
  }
};
