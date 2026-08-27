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
  late final Future<List<Product>> products = ProductService().getProducts();
  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Cart',
    currentRoute: '/cart',
    centerBody: false,
    useCartDesktopHeader: true,
    body: FutureBuilder<List<Product>>(
      future: products,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return AnimatedBuilder(
          animation: CartService.instance,
          builder: (context, _) {
            final quantities = CartService.instance.items;
            final cartProducts = snapshot.data!
                .where((product) => quantities.containsKey(product.code))
                .toList();
            if (cartProducts.isEmpty)
              return Center(
                child: Text(
                  'Your cart is empty.',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 32),
                ),
              );
            final isDesktop =
                MediaQuery.sizeOf(context).width >= 850 &&
                MediaQuery.sizeOf(context).height >= 600;
            return isDesktop
                ? _DesktopCart(products: cartProducts, quantities: quantities)
                : _MobileCart(products: cartProducts, quantities: quantities);
          },
        );
      },
    ),
  );
}

class _DesktopCart extends StatelessWidget {
  const _DesktopCart({required this.products, required this.quantities});

  final List<Product> products;
  final Map<String, int> quantities;

  @override
  Widget build(BuildContext context) {
    final subtotal = products.fold<int>(
      0,
      (sum, product) =>
          sum + _priceFor(product) * (quantities[product.code] ?? 0),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 96),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Cart',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 44,
                  color: const Color(0xFF5B351A),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: Color(0xFF9E8B74), thickness: 1),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final summaryWidth = constraints.maxWidth >= 900
                      ? 344.0
                      : 310.0;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            for (final product in products) ...[
                              _DesktopCartCard(
                                product: product,
                                quantity: quantities[product.code] ?? 0,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 36),
                      SizedBox(
                        width: summaryWidth,
                        child: _OrderSummary(subtotal: subtotal),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileCart extends StatelessWidget {
  const _MobileCart({required this.products, required this.quantities});

  final List<Product> products;
  final Map<String, int> quantities;

  @override
  Widget build(BuildContext context) {
    final subtotal = products.fold<int>(
      0,
      (sum, product) =>
          sum + _priceFor(product) * (quantities[product.code] ?? 0),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 76),
      children: [
        Text(
          'Your Cart',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 36,
            color: const Color(0xFF5B351A),
          ),
        ),
        const SizedBox(height: 20),
        for (final product in products) ...[
          _CartCard(product: product, quantity: quantities[product.code]!),
          const SizedBox(height: 18),
        ],
        Center(
          child: SizedBox(
            width: 145,
            height: 44,
            child: FilledButton(
              onPressed: () => _showMobileCheckoutSheet(context, subtotal),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA35710),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: Text('Checkout', style: GoogleFonts.blinker(fontSize: 17)),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showMobileCheckoutSheet(BuildContext context, int subtotal) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MobileCheckoutSheet(subtotal: subtotal),
    );

class _MobileCheckoutSheet extends StatefulWidget {
  const _MobileCheckoutSheet({required this.subtotal});

  final int subtotal;

  @override
  State<_MobileCheckoutSheet> createState() => _MobileCheckoutSheetState();
}

class _MobileCheckoutSheetState extends State<_MobileCheckoutSheet> {
  String _paymentMode = 'UPI (QR Code)';

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      20,
      16,
      20,
      MediaQuery.paddingOf(context).bottom + 14,
    ),
    decoration: const BoxDecoration(
      color: Color(0xFFD8C7B0),
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      border: Border(
        top: BorderSide(color: Color(0xFF5B351A), width: 1.5),
        left: BorderSide(color: Color(0xFF5B351A), width: 1.5),
        right: BorderSide(color: Color(0xFF5B351A), width: 1.5),
      ),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Subtotal',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 26,
                  color: const Color(0xFF5B351A),
                ),
              ),
              const Spacer(),
              Text(
                '₹${widget.subtotal}',
                style: GoogleFonts.blinker(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            'Inclusive of all taxes',
            style: GoogleFonts.blinker(fontSize: 9),
          ),
          const Divider(color: Color(0xFF8C7154), thickness: 2),
          const SizedBox(height: 16),
          _MobileSummaryCopy(
            title: 'Deliver to',
            body:
                'Jhun Doe\nXYZ Street, Some Random Landmark\nCity Name, State Name of Area\nCountry name',
          ),
          const SizedBox(height: 14),
          _MobileSummaryCopy(
            title: 'Contact',
            body: 'Jhun Doe\n+91 1234567895',
          ),
          const SizedBox(height: 16),
          Text(
            'Mode of Payment',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              color: const Color(0xFF5B351A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MobilePaymentOption(
                  label: 'UPI (QR Code)',
                  selected: _paymentMode == 'UPI (QR Code)',
                  onTap: () => setState(() => _paymentMode = 'UPI (QR Code)'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MobilePaymentOption(
                  label: 'Pay On Delivery',
                  selected: _paymentMode == 'Pay On Delivery',
                  onTap: () => setState(() => _paymentMode = 'Pay On Delivery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checkout is coming soon.')),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA35710),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: Text(
                'Order Now',
                style: GoogleFonts.blinker(fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MobileSummaryCopy extends StatelessWidget {
  const _MobileSummaryCopy({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.dmSerifDisplay(
          fontSize: 18,
          color: const Color(0xFF5B351A),
        ),
      ),
      Text(body, style: GoogleFonts.blinker(fontSize: 10, height: 1.05)),
    ],
  );
}

class _MobilePaymentOption extends StatelessWidget {
  const _MobilePaymentOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA35710), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.blinker(fontSize: 10),
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 17,
          ),
        ],
      ),
    ),
  );
}

class _DesktopCartCard extends StatelessWidget {
  const _DesktopCartCard({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final cart = CartService.instance;
    final sizes = _sizesFor(product);
    final price = _priceFor(product);

    return Container(
      height: 158,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E3D8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0D2BE), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332D1E12),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 88,
              height: double.infinity,
              child: _ProductImage(product: product),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.type,
                  style: GoogleFonts.blinker(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 20,
                    height: 1,
                    color: const Color(0xFF5B351A),
                  ),
                ),
                if (sizes.isNotEmpty) ...[
                  const Spacer(),
                  Text(
                    'Size',
                    style: GoogleFonts.blinker(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: sizes
                        .map(
                          (size) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: ChoiceChip(
                              label: Text(
                                size,
                                style: GoogleFonts.blinker(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: cart.sizeFor(product.code) == size,
                              onSelected: (_) =>
                                  cart.setSize(product.code, size),
                              showCheckmark: false,
                              selectedColor: const Color(0xFFB98855),
                              backgroundColor: const Color(0xFFD8C7B0),
                              shape: const CircleBorder(),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _DesktopInfo(label: 'Price', value: '₹$price'),
          const SizedBox(width: 16),
          _DesktopQuantity(productCode: product.code, quantity: quantity),
          const SizedBox(width: 16),
          _DesktopInfo(
            label: 'Total',
            value: '₹${price * quantity}',
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: ProductService().getProductImageUrlAsync(product.code),
    builder: (_, snapshot) => !snapshot.hasData || snapshot.data!.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Image.network(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
          ),
  );
}

class _DesktopInfo extends StatelessWidget {
  const _DesktopInfo({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 62,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.blinker(fontSize: 14, color: Colors.grey),
        ),
        Text(
          value,
          style: GoogleFonts.blinker(
            fontSize: 21,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _DesktopQuantity extends StatelessWidget {
  const _DesktopQuantity({required this.productCode, required this.quantity});

  final String productCode;
  final int quantity;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 84,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Quantity',
          style: GoogleFonts.blinker(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Container(
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFD8C7B0),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              _QuantityButton(
                icon: Icons.remove,
                onTap: () => CartService.instance.decrement(productCode),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB98855),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '$quantity',
                    style: GoogleFonts.blinker(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _QuantityButton(
                icon: Icons.add,
                onTap: () => CartService.instance.add(productCode),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Icon(icon, size: 16),
    ),
  );
}

class _OrderSummary extends StatefulWidget {
  const _OrderSummary({required this.subtotal});

  final int subtotal;

  @override
  State<_OrderSummary> createState() => _OrderSummaryState();
}

class _OrderSummaryState extends State<_OrderSummary> {
  String _paymentMode = 'UPI (QR Code)';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFD8C7B0),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFF5B351A), width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Subtotal',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 28,
                color: const Color(0xFF5B351A),
              ),
            ),
            const Spacer(),
            Text(
              '₹${widget.subtotal}',
              style: GoogleFonts.blinker(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          'Inclusive of all taxes',
          style: GoogleFonts.blinker(fontSize: 11),
        ),
        const Divider(color: Color(0xFF8C7154), thickness: 1),
        const SizedBox(height: 14),
        _SummaryCopy(
          title: 'Deliver to',
          body:
              'Jhun Doe\nXYZ Street, Some Random Landmark\nCity Name, State Name of Area\nCountry name',
        ),
        const SizedBox(height: 12),
        _SummaryCopy(title: 'Contact', body: 'Jhun Doe\n+91 1234567895'),
        const SizedBox(height: 16),
        Text(
          'Mode of Payment',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 22,
            color: const Color(0xFF5B351A),
          ),
        ),
        const SizedBox(height: 8),
        _PaymentOption(
          label: 'UPI (QR Code)',
          selected: _paymentMode == 'UPI (QR Code)',
          onTap: () => setState(() => _paymentMode = 'UPI (QR Code)'),
        ),
        const SizedBox(height: 8),
        _PaymentOption(
          label: 'Pay On Delivery',
          selected: _paymentMode == 'Pay On Delivery',
          onTap: () => setState(() => _paymentMode = 'Pay On Delivery'),
        ),
        const SizedBox(height: 28),
        Center(
          child: SizedBox(
            width: 210,
            height: 46,
            child: FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checkout is coming soon.')),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA35710),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Order Now',
                style: GoogleFonts.blinker(fontSize: 22),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SummaryCopy extends StatelessWidget {
  const _SummaryCopy({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.dmSerifDisplay(
          fontSize: 22,
          color: const Color(0xFF5B351A),
        ),
      ),
      Text(body, style: GoogleFonts.blinker(fontSize: 12, height: 1.1)),
    ],
  );
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: onTap,
    child: Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA35710), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.blinker(fontSize: 12)),
          const Spacer(),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
          ),
        ],
      ),
    ),
  );
}

class _CartCard extends StatelessWidget {
  const _CartCard({required this.product, required this.quantity});
  final Product product;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final sizes = _sizesFor(product);
    final cart = CartService.instance;
    final price = _priceFor(product);

    return Container(
      height: 158,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E3D8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332D1E12),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 88,
              height: double.infinity,
              child: _ProductImage(product: product),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.type,
                  style: GoogleFonts.blinker(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 20,
                    height: 1,
                    color: const Color(0xFF5B351A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (sizes.isNotEmpty) ...[
                            Text(
                              'Size',
                              style: GoogleFonts.blinker(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: sizes
                                  .take(4)
                                  .map(
                                    (size) => Padding(
                                      padding: const EdgeInsets.only(right: 3),
                                      child: ChoiceChip(
                                        label: Text(
                                          size,
                                          style: GoogleFonts.blinker(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        selected:
                                            cart.sizeFor(product.code) == size,
                                        onSelected: (_) =>
                                            cart.setSize(product.code, size),
                                        showCheckmark: false,
                                        selectedColor: const Color(0xFFB98855),
                                        backgroundColor: const Color(
                                          0xFFD8C7B0,
                                        ),
                                        shape: const CircleBorder(),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ] else
                            const SizedBox(height: 35),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 66,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantity',
                            style: GoogleFonts.blinker(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 24,
                            child: _MobileQuantity(
                              productCode: product.code,
                              quantity: quantity,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _MobileInfo(label: 'Price', value: '₹$price'),
                    ),
                    _MobileInfo(
                      label: 'Total',
                      value: '₹${price * quantity}',
                      bold: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileQuantity extends StatelessWidget {
  const _MobileQuantity({required this.productCode, required this.quantity});

  final String productCode;
  final int quantity;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFD8C7B0),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      children: [
        _QuantityButton(
          icon: Icons.remove,
          onTap: () => CartService.instance.decrement(productCode),
        ),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFB98855),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '$quantity',
              style: GoogleFonts.blinker(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _QuantityButton(
          icon: Icons.add,
          onTap: () => CartService.instance.add(productCode),
        ),
      ],
    ),
  );
}

class _MobileInfo extends StatelessWidget {
  const _MobileInfo({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.blinker(fontSize: 12, color: Colors.grey)),
      Text(
        value,
        style: GoogleFonts.blinker(
          fontSize: 17,
          height: 1,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    ],
  );
}

List<String> _sizesFor(Product product) =>
    product.sizes
        ?.split(',')
        .map((size) => size.trim())
        .where((size) => size.isNotEmpty)
        .toList() ??
    [];

int _priceFor(Product product) =>
    int.tryParse((product.price ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
