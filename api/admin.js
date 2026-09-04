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
const imageNamePattern = /^(thumbnail|pimage\d+|\d+)\.webp$/i;
// Image bytes upload directly to Supabase through a short-lived signed URL,
// rather than through Vercel's much smaller request-body limit.
const maxImageBytes = 10 * 1024 * 1024;
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

function imageSort(left, right) {
  if (left.name.toLowerCase() === 'thumbnail.webp') return -1;
  if (right.name.toLowerCase() === 'thumbnail.webp') return 1;
  const leftNumber = Number(/(?:pimage)?(\d+)/i.exec(left.name)?.[1] || 0);
  const rightNumber = Number(/(?:pimage)?(\d+)/i.exec(right.name)?.[1] || 0);
  return leftNumber - rightNumber;
}

async function listImages(code) {
  const files = await supabaseFetch('/storage/v1/object/list/product_images', {
    method: 'POST',
    body: JSON.stringify({
      prefix: code,
      limit: 100,
      offset: 0,
      sortBy: { column: 'name', order: 'asc' },
    }),
  });
  return files.filter((file) => imageNamePattern.test(file.name)).sort(imageSort);
}

function imageGallery(code, files) {
  return {
    code,
    images: files.map((file) => ({
      name: file.name,
      // Some WebP encodings render black through Supabase's transformation
      // endpoint. The image manager loads on demand, so use the reliable
      // source URL and let Flutter downscale the decoded preview instead.
      url: publicImageUrl(code, file.name),
      sourceUrl: publicImageUrl(code, file.name),
      isThumbnail: file.name.toLowerCase() === 'thumbnail.webp',
    })),
  };
}

async function gallery() {
  const products = await supabaseFetch('/rest/v1/products?select=code&order=code.asc');
  return Promise.all(
    products.map(async ({ code }) => imageGallery(code, await listImages(code))),
  );
}

function validImageName(name) {
  return typeof name === 'string' && imageNamePattern.test(name);
}

function validProductCode(code) {
  return /^[A-Za-z0-9_-]+$/.test(code);
}

async function moveImage(sourceKey, destinationKey) {
  await supabaseFetch('/storage/v1/object/move', {
    method: 'POST',
    body: JSON.stringify({
      bucketId: 'product_images',
      sourceKey,
      destinationKey,
    }),
  });
}

async function normalizeImageNames(code, thumbnailName) {
  const images = await listImages(code);
  const thumbnail = images.find((image) => image.name === thumbnailName);
  if (!thumbnail) throw new Error('Image not found. Refresh the gallery and try again.');

  const ordered = [thumbnail, ...images.filter((image) => image.name !== thumbnailName)];
  const nonce = crypto.randomBytes(8).toString('hex');
  for (var index = 0; index < ordered.length; index += 1) {
    await moveImage(
      `${code}/${ordered[index].name}`,
      `${code}/.admin-${nonce}-${index}.webp`,
    );
  }
  for (var index = 0; index < ordered.length; index += 1) {
    const destination = index === 0 ? 'thumbnail.webp' : `pimage${index}.webp`;
    await moveImage(
      `${code}/.admin-${nonce}-${index}.webp`,
      `${code}/${destination}`,
    );
  }
}

async function uploadImage(code, imageBase64) {
  if (typeof imageBase64 !== 'string' || !imageBase64) {
    throw new Error('Choose a WebP image to upload.');
  }
  const bytes = Buffer.from(imageBase64, 'base64');
  const isWebp =
    bytes.length >= 12 &&
    bytes.toString('ascii', 0, 4) === 'RIFF' &&
    bytes.toString('ascii', 8, 12) === 'WEBP';
  if (!isWebp || bytes.length > maxImageBytes) {
    throw new Error('Images must be valid WebP files smaller than 3 MB.');
  }
  const images = await listImages(code);
  const nextNumber = images
    .map((image) => Number(/^pimage(\d+)\.webp$/i.exec(image.name)?.[1] || 0))
    .reduce((largest, value) => Math.max(largest, value), 0) + 1;
  const name = `pimage${nextNumber}.webp`;
  await supabaseFetch(`/storage/v1/object/product_images/${encodeURIComponent(code)}/${name}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'image/webp',
      'x-upsert': 'false',
    },
    body: bytes,
  });
}

async function createImageUploadTicket(code, byteLength) {
  if (!Number.isInteger(byteLength) || byteLength < 1 || byteLength > maxImageBytes) {
    throw new Error('Converted WebP images must be smaller than 10 MB.');
  }
  const images = await listImages(code);
  const nextNumber = images
    .map((image) => Number(/^pimage(\d+)\.webp$/i.exec(image.name)?.[1] || 0))
    .reduce((largest, value) => Math.max(largest, value), 0) + 1;
  const name = `pimage${nextNumber}.webp`;
  const path = `${code}/${name}`;
  const signed = await supabaseFetch(
    `/storage/v1/object/upload/sign/product_images/${encodeURIComponent(code)}/${name}`,
    { method: 'POST', body: JSON.stringify({}) },
  );
  if (!signed?.url || typeof signed.url !== 'string') {
    throw new Error('Supabase could not prepare an image upload.');
  }
  return {
    path,
    uploadUrl: signed.url.startsWith('http')
      ? signed.url
      : `${supabaseUrl}/storage/v1${signed.url}`,
  };
}

async function deleteImage(code, name) {
  if (!validImageName(name)) throw new Error('Invalid image name.');
  await supabaseFetch('/storage/v1/object/product_images', {
    method: 'DELETE',
    body: JSON.stringify({ bucketId: 'product_images', prefixes: [`${code}/${name}`] }),
  });
  const remaining = await listImages(code);
  if (remaining.some((image) => image.name === name)) {
    throw new Error('Supabase did not remove the selected image.');
  }
  if (remaining.isNotEmpty) {
    const thumbnail = remaining.find(
      (image) => image.name.toLowerCase() === 'thumbnail.webp',
    );
    await normalizeImageNames(code, thumbnail?.name || remaining.first.name);
  }
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

    if (action === 'image_upload' && req.method === 'POST') {
      const code = String(body.code || '');
      if (!validProductCode(code)) {
        return json(res, 400, { error: 'A valid product code is required.' });
      }
      await uploadImage(code, body.imageBase64);
      return json(res, 201, imageGallery(code, await listImages(code)));
    }

    if (action === 'image_upload_ticket' && req.method === 'POST') {
      const code = String(body.code || '');
      if (!validProductCode(code)) {
        return json(res, 400, { error: 'A valid product code is required.' });
      }
      return json(
        res,
        201,
        await createImageUploadTicket(code, Number(body.byteLength)),
      );
    }

    if (action === 'image_thumbnail' && req.method === 'POST') {
      const code = String(body.code || '');
      const name = String(body.name || '');
      if (!validProductCode(code) || !imageNamePattern.test(name)) {
        return json(res, 400, { error: 'A valid product image is required.' });
      }
      await normalizeImageNames(code, name);
      return json(res, 200, imageGallery(code, await listImages(code)));
    }

    if (action === 'image_delete' && req.method === 'DELETE') {
      const code = String(body.code || '');
      const name = String(body.name || '');
      if (!validProductCode(code) || !name) {
        return json(res, 400, { error: 'A valid product code and image name are required.' });
      }
      await deleteImage(code, name);
      return json(res, 200, imageGallery(code, await listImages(code)));
    }

    if (action === 'create' && req.method === 'POST') {
      const product = productPayload(body.product || {}, { allowCode: true });
      if (!/^[A-Za-z0-9_-]+$/.test(product.code || '')) {
        return json(res, 400, {
          error: 'code is required and can only use letters, numbers, _ and -.',
        });
      }
      const existing = await supabaseFetch(
        `/rest/v1/products?select=code&code=eq.${encodeURIComponent(product.code)}&limit=1`,
      );
      if (existing.length > 0) {
        return json(res, 409, {
          error: 'A product with this code already exists. Choose a unique code.',
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
