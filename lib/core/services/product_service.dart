import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();

  factory ProductService() {
    return _instance;
  }

  ProductService._internal();

  final _supabase = Supabase.instance.client;

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

  String getProductImageUrl(String productCode) {
    try {
      // Images are stored in folders: product_code/1.png
      final fileName = '$productCode/1.png';
      final url = _supabase.storage
          .from('product_images')
          .getPublicUrl(fileName);
      return url;
    } catch (e) {
      print('Error getting image URL for $productCode: $e');
      return '';
    }
  }

  Future<String> getProductImageUrlAsync(String productCode) async {
    try {
      // Images are stored in folders: product_code/1.png
      final fileName = '$productCode/1.png';
      final url = _supabase.storage
          .from('product_images')
          .getPublicUrl(fileName);
      return url;
    } catch (e) {
      print('Error getting image URL for $productCode: $e');
      return '';
    }
  }
}
