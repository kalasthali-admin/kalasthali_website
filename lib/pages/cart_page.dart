import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/product.dart';
import '../core/services/cart_service.dart';
import '../core/services/product_service.dart';
import '../widgets/app_scaffold.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late final products = ProductService().getProducts();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cart',
      currentRoute: '/cart',
      centerBody: false,
      body: FutureBuilder<List<Product>>(
        future: products,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final allProducts = snapshot.data!;
          return AnimatedBuilder(
            animation: CartService.instance,
            builder: (context, _) {
              final items = CartService.instance.items;
              final cartProducts = allProducts
                  .where((product) => items.containsKey(product.code))
                  .toList();
              if (cartProducts.isEmpty)
                return const Center(child: Text('Your cart is empty.'));
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Your Cart',
                    style: GoogleFonts.dmSerifDisplay(fontSize: 36),
                  ),
                  const SizedBox(height: 20),
                  for (final product in cartProducts)
                    Card(
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text('Quantity: ${items[product.code]}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_shopping_cart_outlined),
                          onPressed: () =>
                              CartService.instance.remove(product.code),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
