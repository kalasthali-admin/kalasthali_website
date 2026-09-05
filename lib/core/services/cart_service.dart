import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import 'auth_service.dart';

class UserCartItem {
  const UserCartItem({
    required this.code,
    required this.productName,
    required this.quantity,
    this.size,
    this.product,
  });

  final String code;
  final String productName;
  final int quantity;
  final String? size;
  final Product? product;

  factory UserCartItem.fromJson(Map<String, dynamic> json) {
    final productJson = json['products'];
    return UserCartItem(
      code: json['code'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      size: json['size'] as String?,
      product: productJson is Map<String, dynamic>
          ? Product.fromJson(productJson)
          : null,
    );
  }
}

class CartService {
  CartService._();

  static final CartService instance = CartService._();

  final _client = Supabase.instance.client;
  final cartVersion = StreamController<int>.broadcast();
  int _version = 0;

  bool get isSignedIn => AuthService.currentUser != null;

  Future<List<UserCartItem>> loadItems() async {
    final user = AuthService.currentUser;
    if (user == null) return const [];

    final rows =
        await _client
                .from('user_cart')
                .select('code, product_name, size, quantity, products(*)')
                .eq('user', user.id)
            as List;

    return rows
        .cast<Map<String, dynamic>>()
        .map(UserCartItem.fromJson)
        .toList(growable: false);
  }

  Future<int> quantityFor(String productCode) async {
    final user = AuthService.currentUser;
    if (user == null) return 0;

    final row = await _client
        .from('user_cart')
        .select('quantity')
        .eq('user', user.id)
        .eq('code', productCode)
        .maybeSingle();
    return (row?['quantity'] as num?)?.toInt() ?? 0;
  }

  Future<bool> add(Product product, {String? size}) async {
    final user = AuthService.currentUser;
    if (user == null) return false;

    final table = _client.from('user_cart');
    final existing = await table
        .select('quantity')
        .eq('user', user.id)
        .eq('code', product.code)
        .maybeSingle();
    final quantity = ((existing?['quantity'] as num?)?.toInt() ?? 0) + 1;

    if (existing == null) {
      await table.insert({
        'code': product.code,
        'user': user.id,
        'product_name': product.name,
        'size': size,
        'quantity': quantity,
      });
    } else {
      final values = {'quantity': quantity, 'product_name': product.name};
      if (size != null) values['size'] = size;
      await table.update(values).eq('user', user.id).eq('code', product.code);
    }

    _notify();
    return true;
  }

  Future<void> setQuantity(String productCode, int quantity) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    if (quantity <= 0) {
      await remove(productCode);
      return;
    }

    await _client
        .from('user_cart')
        .update({'quantity': quantity})
        .eq('user', user.id)
        .eq('code', productCode);
    _notify();
  }

  Future<void> remove(String productCode) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    await _client
        .from('user_cart')
        .delete()
        .eq('user', user.id)
        .eq('code', productCode);
    _notify();
  }

  void _notify() {
    _version += 1;
    cartVersion.add(_version);
  }
}
