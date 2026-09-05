const fs = require('node:fs/promises');
const path = require('node:path');

const origin = 'https://kalasthali.co';
const escape = (value) => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

function render(template, product, storageUrl) {
  if (!/^[A-Za-z0-9_-]+$/.test(product.code)) throw new Error('Unsupported product code');
  const url = `${origin}/product?code=${encodeURIComponent(product.code)}`;
  const image = `${storageUrl}/storage/v1/object/public/product_images/${product.code}/thumbnail.webp`;
  const title = `${product.name} | Kalasthali By Nisha`;
  const description = String(product.description || '').replace(/\s+/g, ' ').slice(0, 155);
  let html = template.replace(/<title>[\s\S]*?<\/title>/i, `<title>${escape(title)}</title>`)
    .replace(/<base\s+href="[^"]*"\s*>/i, '<base href="/">')
    .replace(/<link\s+rel="canonical"[^>]*>/i, `<link rel="canonical" href="${escape(url)}">`);
  const values = {'description':description,'og:title':title,'og:description':description,'og:url':url,'og:type':'product','og:image':image,'og:image:secure_url':image,'og:image:type':'image/webp','twitter:title':title,'twitter:description':description,'twitter:image':image,'twitter:card':'summary_large_image'};
  html = html.replace(/<meta\b[^>]*>/gi, tag => {
    const key = /(?:name|property)="([^"]+)"/.exec(tag)?.[1];
    if (key === 'og:image:width' || key === 'og:image:height') return '';
    return Object.hasOwn(values, key) ? tag.replace(/content="[^"]*"/, `content="${escape(values[key])}"`) : tag;
  });
  const schema = {'@context':'https://schema.org','@type':'Product',name:product.name,description:product.description,sku:product.code,category:product.type,image,url,brand:{'@type':'Brand',name:'Kalasthali By Nisha'}};
  html = html.replace('</head>', `<script id="kalasthali-product-schema" type="application/ld+json">${JSON.stringify(schema).replace(/</g, '\\u003c')}</script>
    <style>#app-skeleton{display:none}#product-preview{max-width:1100px;margin:auto;padding:32px;color:#5b351a;font:18px Georgia,serif}#product-preview img{width:min(100%,420px);height:auto;border-radius:18px}#product-preview p{white-space:pre-line;line-height:1.5}</style></head>`);
  return html.replace('<body>', `<body><main id="product-preview"><nav><a href="/">Kalasthali By Nisha</a> / <a href="/collections">Collection</a></nav><h1>${escape(product.name)}</h1><img src="${escape(image)}" alt="${escape(product.name)}"><p>${escape(product.description)}</p><h2>Specifications</h2><p>${escape(product.specifications)}</p><p>Price: ${escape(product.price)}</p><a href="/checkout?code=${escape(product.code)}">Buy now</a></main><script>window.addEventListener('flutter-first-frame',function(){document.getElementById('product-preview')?.remove();});</script>`);
}

async function main() {
  const storageUrl = (process.env.SUPABASE_URL || 'https://dddriininznavwrsrgww.supabase.co').replace(/\/$/, '');
  const key = process.env.SUPABASE_PUBLISHABLE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!key) throw new Error('Set SUPABASE_PUBLISHABLE_KEY or SUPABASE_SERVICE_ROLE_KEY for product prerendering.');
  const products = [];
  for (let offset = 0; ; ) {
    const response = await fetch(`${storageUrl}/rest/v1/products?select=code,name,description,specifications,price,type&order=code.asc&limit=500&offset=${offset}`, {
      headers:{apikey:key}, signal:AbortSignal.timeout(30000),
    });
    if (!response.ok) throw new Error(`Product fetch failed (${response.status})`);
    const rows = await response.json();
    if (!Array.isArray(rows)) throw new Error('Invalid products response');
    if (!rows.length) break;
    products.push(...rows);
    offset += rows.length;
  }
  const output = path.resolve('build/web');
  const template = await fs.readFile(path.join(output, 'index.html'), 'utf8');
  await fs.mkdir(path.join(output, 'prerendered'), {recursive:true});
  for (const product of products) {
    await fs.writeFile(path.join(output, 'prerendered', `${product.code}.html`), render(template, product, storageUrl));
  }
  const urls = [origin + '/', origin + '/collections', ...products.map(p => `${origin}/product?code=${encodeURIComponent(p.code)}`)];
  await fs.writeFile(path.join(output, 'sitemap.xml'), `<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${urls.map(url=>`<url><loc>${escape(url)}</loc></url>`).join('')}</urlset>`);
  console.log(`Prerendered ${products.length} product pages and sitemap.xml`);
}
module.exports = {render};
if (require.main === module) main().catch(error => { console.error(error.message); process.exitCode = 1; });
