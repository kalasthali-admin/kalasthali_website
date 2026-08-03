import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Product',
      currentRoute: '/product',
      body: Text('View product details here.'),
    );
  }
}
