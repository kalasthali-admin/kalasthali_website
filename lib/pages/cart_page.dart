import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Cart',
      currentRoute: '/cart',
      body: Text('Review items in your cart.'),
    );
  }
}
