import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();
  static const _storageKey = 'guest_cart';
  final Map<String, int> _items = {};
  final Map<String, String> _sizes = {};

  Map<String, int> get items => Map.unmodifiable(_items);
  int get itemCount =>
      _items.values.fold(0, (total, quantity) => total + quantity);
  String? sizeFor(String productCode) => _sizes[productCode];

  Future<void> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_storageKey);
    if (raw == null) return;
    final stored = jsonDecode(raw) as Map<String, dynamic>;
    _items
      ..clear()
      ..addEntries(
        stored.entries.map((entry) {
          final value = entry.value;
          if (value is Map<String, dynamic>) {
            final size = value['size'] as String?;
            if (size != null) _sizes[entry.key] = size;
            return MapEntry(entry.key, value['quantity'] as int);
          }
          return MapEntry(entry.key, value as int);
        }),
      );
    notifyListeners();
  }

  Future<void> add(String productCode) async {
    _items.update(productCode, (quantity) => quantity + 1, ifAbsent: () => 1);
    await _save();
    notifyListeners();
  }

  Future<void> remove(String productCode) async {
    _items.remove(productCode);
    _sizes.remove(productCode);
    await _save();
    notifyListeners();
  }

  Future<void> decrement(String productCode) async {
    final quantity = _items[productCode] ?? 0;
    if (quantity <= 1) return remove(productCode);
    _items[productCode] = quantity - 1;
    await _save();
    notifyListeners();
  }

  Future<void> setSize(String productCode, String size) async {
    _sizes[productCode] = size;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await (await SharedPreferences.getInstance()).setString(
      _storageKey,
      jsonEncode({
        for (final entry in _items.entries)
          entry.key: {'quantity': entry.value, 'size': _sizes[entry.key]},
      }),
    );
  }
}
