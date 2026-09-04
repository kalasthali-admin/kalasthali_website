import '../models/product.dart';
import 'seo_service_stub.dart'
    if (dart.library.html) 'seo_service_web.dart'
    as platform;

/// Keeps browser metadata in sync with the route rendered by the Flutter app.
class SeoService {
  SeoService._();

  static const siteName = 'Kalasthali By Nisha';
  static const siteUrl = 'https://kalasthali.co';

  static void setPage({
    required String title,
    required String description,
    required String path,
  }) => platform.setPageMetadata(
    title: title,
    description: description,
    canonicalUrl: '$siteUrl$path',
  );

  static void setProduct(Product product) {
    final canonicalUrl = Uri(
      scheme: 'https',
      host: 'kalasthali.co',
      path: '/product',
      queryParameters: {'code': product.code},
    ).toString();
    final price = product.price?.replaceAll(RegExp(r'[^0-9.]'), '');

    platform.setProductMetadata(
      title: '${product.name} | $siteName',
      description: _description(product),
      canonicalUrl: canonicalUrl,
      imageUrl:
          'https://dddriininznavwrsrgww.supabase.co/storage/v1/object/public/'
          'product_images/${Uri.encodeComponent(product.code)}/thumbnail.webp',
      product: <String, Object?>{
        'name': product.name,
        'description': _description(product),
        'sku': product.code,
        'category': product.type,
        if (price?.isNotEmpty == true) 'price': price,
      },
    );
  }

  static String _description(Product product) {
    final text = product.description.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.length <= 155) return text;
    return '${text.substring(0, 152).trimRight()}...';
  }
}
