const crypto = require('crypto');

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

function safeEqual(left, right) {
  const leftBuffer = Buffer.from(left);
  const rightBuffer = Buffer.from(right);
  return (
    leftBuffer.length === rightBuffer.length &&
    crypto.timingSafeEqual(leftBuffer, rightBuffer)
  );
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

function compactText(value, fallback = '') {
  return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

async function insertSale({ userId, orderId, paymentId, sale }) {
  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error('Supabase service role key is not configured.');
  }

  const product = compactText(sale.product);
  const productCode = compactText(sale.product_code);
  const userAddress = compactText(sale.user_address);
  const customerEmail = compactText(sale.customer_email, null);
  const customerPhone = compactText(sale.customer_phone, null);
  const items = Array.isArray(sale.items) ? sale.items : null;
  const amount = Number(sale.amount);

  if (!product || !productCode || !userAddress || !Number.isInteger(amount)) {
    const error = new Error('Missing sale fields.');
    error.status = 400;
    throw error;
  }

  const response = await fetch(`${supabaseUrl}/rest/v1/sales`, {
    method: 'POST',
    headers: {
      apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
    },
    body: JSON.stringify({
      user: userId,
      product,
      amount,
      product_code: productCode,
      order_id: orderId,
      user_address: userAddress,
      razorpay_payment_id: paymentId,
      customer_email: customerEmail,
      customer_phone: customerPhone,
      items,
    }),
  });

  const text = await response.text();
  if (!response.ok && response.status !== 409) {
    let message = 'Could not record the sale.';
    try {
      message = JSON.parse(text).message || message;
    } catch (_) {}
    throw new Error(message);
  }
}

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return json(res, 405, { error: 'Method not allowed.' });
  }

  const {
    razorpay_payment_id: paymentId,
    razorpay_order_id: orderId,
    razorpay_signature: signature,
  } = readBody(req);

  if (!paymentId || !orderId || !signature) {
    return json(res, 400, { error: 'Missing Razorpay payment fields.' });
  }
  if (!process.env.RAZORPAY_KEY_SECRET) {
    return json(res, 500, { error: 'Razorpay is not configured.' });
  }
  const user = await authenticatedUser(req);
  if (!user) return json(res, 401, { error: 'Log in before verifying payment.' });

  const expected = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');

  if (!safeEqual(expected, signature)) {
    return json(res, 400, { error: 'Payment signature mismatch.' });
  }

  try {
    await insertSale({
      userId: user.id,
      orderId,
      paymentId,
      sale: readBody(req).sale || {},
    });
  } catch (error) {
    return json(res, error.status || 500, {
      error: error.message || 'Could not record the sale.',
    });
  }

  return json(res, 200, {
    success: true,
    payment_id: paymentId,
    order_id: orderId,
  });
};
