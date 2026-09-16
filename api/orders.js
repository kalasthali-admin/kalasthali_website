const crypto = require('crypto');

const supabaseUrl =
  process.env.SUPABASE_URL || 'https://dddriininznavwrsrgww.supabase.co';
const maxEvidenceBytes = 5 * 1024 * 1024;
const allowedContentTypes = new Set(['image/jpeg', 'image/png', 'image/webp']);

function json(res, status, value) {
  res.status(status).json(value);
}

function readBody(req) {
  if (req.body && typeof req.body === 'object') return req.body;
  try {
    return typeof req.body === 'string' ? JSON.parse(req.body) : {};
  } catch (_) {
    return {};
  }
}

async function supabaseFetch(path, options = {}) {
  const response = await fetch(`${supabaseUrl}${path}`, {
    ...options,
    headers: {
      apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  });
  const text = await response.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch (_) {
    data = text;
  }
  if (!response.ok) {
    throw new Error(typeof data === 'object' && data?.message ? data.message : 'Supabase request failed.');
  }
  return data;
}

async function authenticatedUser(req) {
  const authorization = req.headers.authorization || '';
  const token = authorization.startsWith('Bearer ') ? authorization.slice(7) : '';
  const key =
    process.env.SUPABASE_PUBLISHABLE_KEY ||
    process.env.SUPABASE_API_KEY ||
    process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!token || !key) return null;
  const response = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { apikey: key, Authorization: `Bearer ${token}` },
  });
  return response.ok ? response.json() : null;
}

function orderStatus(order) {
  return order.order_status || (order.shipping_confirmation_sent_at ? 'out_for_delivery' : 'order_placed');
}

function isWithin(date, hours) {
  const start = Date.parse(date || '');
  return Number.isFinite(start) && Date.now() <= start + hours * 60 * 60 * 1000;
}

async function ownedOrder(userId, orderId) {
  if (!orderId) return null;
  const rows = await supabaseFetch(
    `/rest/v1/sales?select=*&order_id=eq.${encodeURIComponent(orderId)}&user=eq.${encodeURIComponent(userId)}&limit=1`,
  );
  return rows[0] || null;
}

function returnEligible(order) {
  return orderStatus(order) === 'delivered' && !order.return_status && isWithin(order.delivered_at, 24);
}

function evidencePath(orderId, extension) {
  return `${orderId}/${crypto.randomBytes(16).toString('hex')}.${extension}`;
}

module.exports = async function handler(req, res) {
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return json(res, 503, { error: 'Order service is not configured.' });
  }
  const user = await authenticatedUser(req);
  if (!user) return json(res, 401, { error: 'Please log in to manage this order.' });

  const body = readBody(req);
  const action = req.query.action || body.action;
  const orderId = String(body.orderId || '').trim();
  try {
    const order = await ownedOrder(user.id, orderId);
    if (!order) return json(res, 404, { error: 'Order not found.' });

    if (action === 'cancel' && req.method === 'POST') {
      const cancellationMessage = String(body.cancellationMessage || '').trim();
      if (orderStatus(order) !== 'order_placed' || !isWithin(order.paid_at, 24)) {
        return json(res, 409, { error: 'This order can no longer be cancelled.' });
      }
      if (cancellationMessage.length < 3 || cancellationMessage.length > 500) {
        return json(res, 400, { error: 'A cancellation message between 3 and 500 characters is required.' });
      }
      const updated = await supabaseFetch(`/rest/v1/sales?order_id=eq.${encodeURIComponent(orderId)}`, {
        method: 'PATCH', headers: { Prefer: 'return=representation' },
        body: JSON.stringify({
          order_status: 'cancelled',
          cancelled_at: new Date().toISOString(),
          cancellation_message: cancellationMessage,
        }),
      });
      return json(res, 200, updated[0]);
    }

    if (action === 'return_upload_ticket' && req.method === 'POST') {
      const byteLength = Number(body.byteLength);
      const contentType = String(body.contentType || '').toLowerCase();
      if (!returnEligible(order)) return json(res, 409, { error: 'This order is not eligible for a return request.' });
      if (!Number.isInteger(byteLength) || byteLength < 1 || byteLength > maxEvidenceBytes || !allowedContentTypes.has(contentType)) {
        return json(res, 400, { error: 'Upload a JPEG, PNG, or WebP image smaller than 5 MB.' });
      }
      const extension = contentType === 'image/png' ? 'png' : contentType === 'image/webp' ? 'webp' : 'jpg';
      const path = evidencePath(orderId, extension);
      const signed = await supabaseFetch(`/storage/v1/object/upload/sign/return_evidence/${encodeURIComponent(path)}`, {
        method: 'POST', body: JSON.stringify({}),
      });
      return json(res, 200, {
        path,
        uploadUrl: signed.url.startsWith('http') ? signed.url : `${supabaseUrl}/storage/v1${signed.url}`,
      });
    }

    if (action === 'request_return' && req.method === 'POST') {
      const evidence = Array.isArray(body.evidence) ? body.evidence.map((path) => String(path)) : [];
      if (!returnEligible(order)) return json(res, 409, { error: 'This order is not eligible for a return request.' });
      if (evidence.length < 1 || evidence.length > 5 || evidence.some((path) => !path.startsWith(`${orderId}/`) || path.includes('..'))) {
        return json(res, 400, { error: 'Add between one and five valid product images.' });
      }
      const updated = await supabaseFetch(`/rest/v1/sales?order_id=eq.${encodeURIComponent(orderId)}`, {
        method: 'PATCH', headers: { Prefer: 'return=representation' },
        body: JSON.stringify({
          return_status: 'requested',
          return_requested_at: new Date().toISOString(),
          return_evidence: evidence,
        }),
      });
      return json(res, 200, updated[0]);
    }
    return json(res, 405, { error: 'Unsupported order action.' });
  } catch (error) {
    return json(res, 500, { error: error.message || 'Could not update this order.' });
  }
};
