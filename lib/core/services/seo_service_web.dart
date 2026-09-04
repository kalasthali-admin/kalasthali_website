// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html';

void setPageMetadata({
  required String title,
  required String description,
  required String canonicalUrl,
}) {
  _setMetadata(
    title: title,
    description: description,
    canonicalUrl: canonicalUrl,
  );
  _removeProductSchema();
}

void setProductMetadata({
  required String title,
  required String description,
  required String canonicalUrl,
  required String imageUrl,
  required Map<String, Object?> product,
}) {
  _setMetadata(
    title: title,
    description: description,
    canonicalUrl: canonicalUrl,
    imageUrl: imageUrl,
    isProduct: true,
  );
  _setProductSchema(canonicalUrl, imageUrl, product);
}

void _setMetadata({
  required String title,
  required String description,
  required String canonicalUrl,
  String? imageUrl,
  bool isProduct = false,
}) {
  document.title = title;
  _meta('description', description);
  _meta('og:title', title, property: true);
  _meta('og:description', description, property: true);
  _meta('og:url', canonicalUrl, property: true);
  _meta('og:type', isProduct ? 'product' : 'website', property: true);
  _meta('twitter:title', title);
  _meta('twitter:description', description);
  if (imageUrl != null) {
    _meta('og:image', imageUrl, property: true);
    _meta('og:image:secure_url', imageUrl, property: true);
    _meta('twitter:image', imageUrl);
  }

  final canonical =
      document.head?.querySelector('link[rel="canonical"]') as LinkElement?;
  if (canonical != null) canonical.href = canonicalUrl;
}

void _meta(String key, String value, {bool property = false}) {
  final selector = property ? 'meta[property="$key"]' : 'meta[name="$key"]';
  final meta = document.head?.querySelector(selector) as MetaElement?;
  if (meta == null) return;
  meta.content = value;
}

void _setProductSchema(
  String canonicalUrl,
  String imageUrl,
  Map<String, Object?> product,
) {
  _removeProductSchema();
  final schema = <String, Object?>{
    '@context': 'https://schema.org',
    '@type': 'Product',
    'name': product['name'],
    'description': product['description'],
    'sku': product['sku'],
    'category': product['category'],
    'url': canonicalUrl,
    'image': imageUrl,
    if (product['price'] != null)
      'offers': <String, Object>{
        '@type': 'Offer',
        'priceCurrency': 'INR',
        'price': product['price']!,
        'availability': 'https://schema.org/InStock',
        'url': canonicalUrl,
      },
  };
  final script = ScriptElement()
    ..id = 'kalasthali-product-schema'
    ..type = 'application/ld+json'
    ..text = jsonEncode(schema);
  document.head?.append(script);
}

void _removeProductSchema() =>
    document.querySelector('#kalasthali-product-schema')?.remove();
