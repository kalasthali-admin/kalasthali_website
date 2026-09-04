import 'package:flutter/material.dart';

import '../models/product.dart';

class CheckoutNavigation {
  CheckoutNavigation._();

  static Future<void> buyNow(BuildContext context, Product product) async {
    Navigator.pushNamed(
      context,
      Uri(
        path: '/checkout',
        queryParameters: {'code': product.code},
      ).toString(),
    );
  }
}
