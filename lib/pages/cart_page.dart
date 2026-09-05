import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/app_footer.dart';
import '../widgets/app_scaffold.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Cart',
    currentRoute: '/cart',
    centerBody: false,
    body: Column(
      children: [
        Expanded(
          child: Center(
            child: Text(
              'Your cart is empty.',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 38,
                color: const Color(0xFF5B351A),
              ),
            ),
          ),
        ),
        const AppFooter(),
      ],
    ),
  );
}
