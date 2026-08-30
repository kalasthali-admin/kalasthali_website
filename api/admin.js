const crypto = require('crypto');

const allowedFields = [
  'code',
  'type',
  'name',
  'description',
  'specifications',
  'sizes',
  'price',
  'is_popular',
];
const sessionLifetimeMs = 8 * 60 * 60 * 1000;
const supabaseUrl =
  process.env.SUPABASE_URL || 'https://dddriininznavwrsrgww.supabase.co';

// This intentionally cannot run on a Vercel production deployment. It is
// useful with `vercel dev` while building the dashboard locally.
function isLocalTestMode() {
  return (
    process.env.ADMIN_TEST_MODE === 'true' &&
    process.env.VERCEL_ENV !== 'production'
  );
}

function adminSecret() {
  return process.env.ADMIN_AUTH ||
    process.env.ADMIN_RECOVERY_AUTH ||
    (isLocalTestMode() ? 'local-development-admin-secret' : '');
}

function passwordMatches(password) {
  const candidates = [process.env.ADMIN_AUTH, process.env.ADMIN_RECOVERY_AUTH]
    .filter(Boolean);
  return candidates.some((candidate) => safeEqual(password, candidate));
}

function json(res, status, value) {
  res.status(status).json(value);
}

function readBody(req) {
  if (req.body && typeof req.body === 'object') return req.body;
  if (typeof req.body !== 'string' || req.body.isEmpty) return {};
  try {
    return JSON.parse(req.body);
  } catch (_) {
    return {};
  }
}

function configured() {
  return Boolean(
    adminSecret() &&
      process.env.SUPABASE_SERVICE_ROLE_KEY,
  );
}

function safeEqual(left, right) {
  const leftBuffer = Buffer.from(left);
  const rightBuffer = Buffer.from(right);
  return (
    leftBuffer.length === rightBuffer.length &&
    crypto.timingSafeEqual(leftBuffer, rightBuffer)
  );
}

function sign(payload) {
  return crypto
    .createHmac('sha256', adminSecret())
    .update(payload)
    .digest('base64url');
}

function createToken() {
  const payload = Buffer.from(
    JSON.stringify({
      issuedAt: Date.now(),
      nonce: crypto.randomBytes(16).toString('base64url'),
    }),
  ).toString('base64url');
  return `${payload}.${sign(payload)}`;
}

function isAuthenticated(req) {
  const authorization = req.headers.authorization || '';
  const token = authorization.startsWith('Bearer ')
    ? authorization.slice('Bearer '.length)
    : '';
  const [payload, signature] = token.split('.');
  if (!payload || !signature || !safeEqual(signature, sign(payload))) return false;

  try {
    const session = JSON.parse(Buffer.from(payload, 'base64url').toString());
    return Date.now() - session.issuedAt < sessionLifetimeMs;
  } catch (_) {
    return false;
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
    throw new Error(
      typeof data === 'object' && data?.message
        ? data.message
        : 'Supabase request failed.',
    );
  }
  return data;
}

function productPayload(source, { allowCode }) {
  const product = {};
  for (const field of allowedFields) {
    if (!allowCode && field === 'code') continue;
    if (Object.prototype.hasOwnProperty.call(source, field)) {
      product[field] = source[field];
    }
  }

  for (const field of ['type', 'name', 'description']) {
    if (typeof product[field] !== 'string' || !product[field].trim()) {
      throw new Error(`${field} is required.`);
    }
    product[field] = product[field].trim();
  }
  for (const field of ['specifications', 'sizes', 'price']) {
    if (product[field] != null && typeof product[field] !== 'string') {
      throw new Error(`${field} must be text.`);
    }
  }
  if (product.is_popular != null && typeof product.is_popular !== 'boolean') {
    throw new Error('is_popular must be true or false.');
  }
  return product;
}

function publicImageUrl(code, name) {
  return `${supabaseUrl}/storage/v1/object/public/product_images/${encodeURIComponent(code)}/${encodeURIComponent(name)}`;
}

async function gallery() {
  const products = await supabaseFetch('/rest/v1/products?select=code&order=code.asc');
  const galleries = await Promise.all(
    products.map(async ({ code }) => {
      const files = await supabaseFetch('/storage/v1/object/list/product_images', {
        method: 'POST',
        body: JSON.stringify({
          prefix: code,
          limit: 100,
          offset: 0,
          sortBy: { column: 'name', order: 'asc' },
        }),
      });
      const images = files
        .filter((file) => /^\d+\.(webp|png|jpe?g)$/i.test(file.name))
        .sort((left, right) => {
          const leftNumber = Number(/^\d+/.exec(left.name)?.[0] || 0);
          const rightNumber = Number(/^\d+/.exec(right.name)?.[0] || 0);
          return leftNumber - rightNumber;
        })
        .map((file) => publicImageUrl(code, file.name));
      return { code, images };
    }),
  );
  return galleries;
}

module.exports = async (req, res) => {
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (!configured()) {
    return json(res, 503, {
      error:
        'Admin server is not configured. Set ADMIN_AUTH or ADMIN_RECOVERY_AUTH, plus SUPABASE_SERVICE_ROLE_KEY, in Vercel.',
    });
  }

  const body = readBody(req);
  const action = req.query.action || body.action;

  if (action === 'login' && req.method === 'POST') {
    if (
      !isLocalTestMode() &&
      !passwordMatches(String(body.password || ''))
    ) {
      return json(res, 401, { error: 'Incorrect password.' });
    }
    return json(res, 200, { token: createToken() });
  }

  if (!isAuthenticated(req)) {
    return json(res, 401, { error: 'Your admin session has expired.' });
  }

  try {
    if (action === 'products' && req.method === 'GET') {
      return json(
        res,
        200,
        await supabaseFetch('/rest/v1/products?select=*&order=code.asc'),
      );
    }

    if (action === 'gallery' && req.method === 'GET') {
      return json(res, 200, await gallery());
    }

    if (action === 'create' && req.method === 'POST') {
      const product = productPayload(body.product || {}, { allowCode: true });
      if (!/^[A-Za-z0-9_-]+$/.test(product.code || '')) {
        return json(res, 400, {
          error: 'code is required and can only use letters, numbers, _ and -.',
        });
      }
      const created = await supabaseFetch('/rest/v1/products', {
        method: 'POST',
        headers: { Prefer: 'return=representation' },
        body: JSON.stringify(product),
      });
      return json(res, 201, created[0]);
    }

    if (action === 'update' && req.method === 'PATCH') {
      const code = String(body.code || '');
      if (!code) return json(res, 400, { error: 'Product code is required.' });
      const product = productPayload(body.product || {}, { allowCode: false });
      const updated = await supabaseFetch(
        `/rest/v1/products?code=eq.${encodeURIComponent(code)}`,
        {
          method: 'PATCH',
          headers: { Prefer: 'return=representation' },
          body: JSON.stringify(product),
        },
      );
      if (!updated[0]) return json(res, 404, { error: 'Product not found.' });
      return json(res, 200, updated[0]);
    }

    if (action === 'delete' && req.method === 'DELETE') {
      const code = String(req.query.code || body.code || '');
      if (!code) return json(res, 400, { error: 'Product code is required.' });
      await supabaseFetch(
        `/rest/v1/products?code=eq.${encodeURIComponent(code)}`,
        { method: 'DELETE' },
      );
      return res.status(204).end();
    }

    return json(res, 404, { error: 'Unknown admin action.' });
  } catch (error) {
    return json(res, 500, {
      error: error instanceof Error ? error.message : 'Admin request failed.',
    });
  }
};
