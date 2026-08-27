import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();
  static const _storageKey = 'guest_cart';
  final Map<String, int> _items = {};

  Map<String, int> get items => Map.unmodifiable(_items);
  int get itemCount =>
      _items.values.fold(0, (total, quantity) => total + quantity);

  Future<void> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_storageKey);
    if (raw == null) return;
    final stored = jsonDecode(raw) as Map<String, dynamic>;
    _items
      ..clear()
      ..addEntries(
        stored.entries.map((entry) => MapEntry(entry.key, entry.value as int)),
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
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await (await SharedPreferences.getInstance()).setString(
      _storageKey,
      jsonEncode(_items),
    );
  }
}
