import 'package:flutter/material.dart';

import '../models/product.dart';
import '../../pages/checkout_page.dart';

class CheckoutNavigation {
  CheckoutNavigation._();

  static Future<void> buyNow(BuildContext context, Product product) async {
    await showProductCheckoutSheet(context, product);
  }
}
