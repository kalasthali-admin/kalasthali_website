# kalasthali

Source code for Kalasthali Website (kalasthali.co)
# Product prerendering

Vercel runs `node scripts/prerender-products.cjs` after the Flutter build.
Set `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` in the Vercel build environment
(the existing server-only `SUPABASE_SERVICE_ROLE_KEY` is also supported).
The key is used only to fetch products and is never written into generated HTML.

Each `/product?code=CODE` request is rewritten to a static product document with
its own title, canonical, social image, Product JSON-LD, and visible product copy.
Flutter loads using the root bootstrap assets, then replaces the preview on its
first frame. Older `/product?CODE` links still work through Flutter, but only the
named `code` URLs receive prerendered HTML. New storefront links use this format.

Product HTML and `/sitemap.xml` are deployment snapshots. Redeploy after adding,
editing, or deleting products to refresh them; admin edits alone do not rebuild
these files. The build fails on a failed database request to avoid publishing a
partial catalog. `/api/sitemap` is rewritten to the same static sitemap.

After deployment, inspect View Source on a product URL: its product title, image,
description, canonical and JSON-LD should appear without running JavaScript.
Check the interactive page loads too, and submit `/sitemap.xml` to Search Console.
Prerendering does not guarantee indexing or search rankings.
