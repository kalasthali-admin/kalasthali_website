const siteUrl = 'https://kalasthali.co';
const supabaseUrl =
  process.env.SUPABASE_URL || 'https://dddriininznavwrsrgww.supabase.co';

function escapeXml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

function sitemap(urls) {
  return `<?xml version="1.0" encoding="UTF-8"?>\n` +
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
    urls.map(({ loc, priority }) =>
      `  <url><loc>${escapeXml(loc)}</loc><priority>${priority}</priority></url>`,
    ).join('\n') +
    '\n</urlset>';
}

module.exports = async (req, res) => {
  const urls = [
    { loc: `${siteUrl}/`, priority: '1.0' },
    { loc: `${siteUrl}/collections`, priority: '0.9' },
    { loc: `${siteUrl}/about`, priority: '0.7' },
    { loc: `${siteUrl}/contact`, priority: '0.7' },
  ];

  // A service-role key is server-only. If it is unavailable locally, still
  // return a valid sitemap for the public static pages.
  if (process.env.SUPABASE_SERVICE_ROLE_KEY) {
    try {
      const response = await fetch(`${supabaseUrl}/rest/v1/products?select=code`, {
        headers: {
          apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
        },
      });
      if (response.ok) {
        const products = await response.json();
        for (const product of products) {
          if (product.code) {
            urls.push({
              loc: `${siteUrl}/product?code=${encodeURIComponent(product.code)}`,
              priority: '0.8',
            });
          }
        }
      }
    } catch (_) {
      // A valid base sitemap is preferable to making bots retry on failure.
    }
  }

  res.setHeader('Content-Type', 'application/xml; charset=utf-8');
  res.setHeader('Cache-Control', 'public, s-maxage=3600, stale-while-revalidate=86400');
  return res.status(200).send(sitemap(urls));
};
