const crypto = require('crypto');

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

  const expected = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');

  if (!safeEqual(expected, signature)) {
    return json(res, 400, { error: 'Payment signature mismatch.' });
  }

  return json(res, 200, { success: true, payment_id: paymentId, order_id: orderId });
};
