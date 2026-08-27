import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();

  factory ProductService() {
    return _instance;
  }

  ProductService._internal();

  final _supabase = Supabase.instance.client;
  final Map<String, Future<String>> _imageUrlRequests = {};
  final Map<String, Future<List<String>>> _imageGalleryRequests = {};

  Future<List<Product>> getProducts() async {
    try {
      final response = await _supabase.from('products').select() as List;
      return response
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<Product?> getProductByCode(String code) async {
    try {
      final response =
          await _supabase.from('products').select().eq('code', code) as List;
      if (response.isEmpty) return null;
      return Product.fromJson(response.first as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching product $code: $e');
      return null;
    }
  }

  Future<List<Product>> getPopularProducts() async {
    try {
      final response =
          await _supabase.from('products').select().eq('is_popular', true)
              as List;

      return response
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching popular products: $e');
      return [];
    }
  }

  Future<String> getProductImageUrlAsync(String productCode) {
    return _imageUrlRequests.putIfAbsent(
      productCode,
      () => _resolveProductImageUrl(productCode),
    );
  }

  Future<List<String>> getProductImageUrlsAsync(String productCode) =>
      _imageGalleryRequests.putIfAbsent(productCode, () async {
        try {
          final storage = _supabase.storage.from('product_images');
          final files =
              (await storage.list(path: productCode))
                  .where(
                    (file) => RegExp(
                      r'^\d+\.(png|jpg)$',
                      caseSensitive: false,
                    ).hasMatch(file.name),
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      int.parse(
                        RegExp(r'^\d+').firstMatch(a.name)!.group(0)!,
                      ).compareTo(
                        int.parse(
                          RegExp(r'^\d+').firstMatch(b.name)!.group(0)!,
                        ),
                      ),
                );
          return files
              .map((file) => storage.getPublicUrl('$productCode/${file.name}'))
              .toList();
        } catch (e) {
          return <String>[];
        }
      });

  Future<String> _resolveProductImageUrl(String productCode) async {
    try {
      final storage = _supabase.storage.from('product_images');
      final files = await storage.list(path: productCode);
      final fileNames = files.map((file) => file.name).toSet();
      final imageName = fileNames.contains('1.png')
          ? '1.png'
          : fileNames.contains('1.jpg')
          ? '1.jpg'
          : null;

      return imageName == null
          ? ''
          : storage.getPublicUrl('$productCode/$imageName');
    } catch (e) {
      print('Error resolving image URL for $productCode: $e');
      return '';
    }
  }
}
