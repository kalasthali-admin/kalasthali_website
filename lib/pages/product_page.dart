import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/product.dart';
import '../core/services/cart_service.dart';
import '../core/services/product_service.dart';
import '../widgets/app_scaffold.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({this.productCode = '', super.key});

  final String productCode;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Product',
      currentRoute: '/product',
      centerBody: false,
      body: FutureBuilder<Product?>(
        future: ProductService().getProductByCode(productCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = snapshot.data;
          if (product == null)
            return const Center(child: Text('Product not found.'));
          return _ProductDetails(product: product);
        },
      ),
    );
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 800;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            mobile ? 22 : 54,
            mobile ? 70 : 72,
            mobile ? 22 : 54,
            100,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: mobile
                  ? _MobileProductLayout(product: product)
                  : _DesktopProductLayout(product: product),
            ),
          ),
        );
      },
    );
  }
}

class _MobileProductLayout extends StatelessWidget {
  const _MobileProductLayout({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _ProductImagePanel(product: product),
      const SizedBox(height: 54),
      Center(child: _ShareButton()),
      const SizedBox(height: 20),
      _ProductCopy(product: product, centeredTitle: true),
      const SizedBox(height: 44),
      _PurchasePanel(product: product),
    ],
  );
}

class _DesktopProductLayout extends StatelessWidget {
  const _DesktopProductLayout({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _ProductImagePanel(product: product)),
      const SizedBox(width: 56),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(alignment: Alignment.centerLeft, child: _ShareButton()),
            const SizedBox(height: 20),
            _ProductCopy(product: product),
            const SizedBox(height: 44),
            _PurchasePanel(product: product),
          ],
        ),
      ),
    ],
  );
}

class _ProductImagePanel extends StatefulWidget {
  const _ProductImagePanel({required this.product});
  final Product product;
  @override
  State<_ProductImagePanel> createState() => _ProductImagePanelState();
}

class _ProductImagePanelState extends State<_ProductImagePanel> {
  int currentImage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFA35710), width: 1.5),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Column(
      children: [
        AspectRatio(
          aspectRatio: .78,
          child: FutureBuilder<List<String>>(
            future: ProductService().getProductImageUrlsAsync(
              widget.product.code,
            ),
            builder: (_, snapshot) =>
                !snapshot.hasData || snapshot.data!.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: snapshot.data!.length,
                          onPageChanged: (index) =>
                              setState(() => currentImage = index),
                          itemBuilder: (_, index) => Image.network(
                            snapshot.data![index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      if (MediaQuery.sizeOf(context).width >= 800) ...[
                        Positioned(
                          left: 12,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: _GalleryArrow(
                              icon: Icons.chevron_left,
                              onPressed: currentImage == 0
                                  ? null
                                  : () => _pageController.previousPage(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOut,
                                    ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: _GalleryArrow(
                              icon: Icons.chevron_right,
                              onPressed:
                                  currentImage == snapshot.data!.length - 1
                                  ? null
                                  : () => _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOut,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<String>>(
          future: ProductService().getProductImageUrlsAsync(
            widget.product.code,
          ),
          builder: (_, snapshot) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              snapshot.data?.length ?? 0,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  index == currentImage ? Icons.circle : Icons.circle_outlined,
                  size: index == currentImage ? 16 : 18,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _GalleryArrow extends StatelessWidget {
  const _GalleryArrow({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .88),
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: const Color(0xFF5B351A)),
    ),
  );
}

class _ProductCopy extends StatelessWidget {
  const _ProductCopy({required this.product, this.centeredTitle = false});
  final Product product;
  final bool centeredTitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        product.name,
        textAlign: centeredTitle ? TextAlign.center : TextAlign.left,
        style: GoogleFonts.dmSerifDisplay(
          fontSize: 48,
          height: 1,
          color: const Color(0xFF5B351A),
        ),
      ),
      const SizedBox(height: 18),
      const Divider(color: Color(0xFF65421F), thickness: 1),
      const SizedBox(height: 20),
      _CopyBlock(label: 'Description', text: product.description),
      const SizedBox(height: 30),
      _CopyBlock(
        label: 'Specifications',
        text: product.specifications?.isNotEmpty == true
            ? product.specifications!
            : 'Details will be available soon.',
      ),
    ],
  );
}

class _CopyBlock extends StatelessWidget {
  const _CopyBlock({required this.label, required this.text});
  final String label;
  final String text;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.blinker(
          fontSize: 26,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 6),
      Text(text, style: GoogleFonts.blinker(fontSize: 18, height: 1.35)),
    ],
  );
}

class _PurchasePanel extends StatelessWidget {
  const _PurchasePanel({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFA35710), width: 1.5),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price',
                style: GoogleFonts.blinker(
                  fontSize: 24,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                product.price?.startsWith('₹') == true
                    ? product.price!
                    : '₹${product.price ?? '-'}',
                style: GoogleFonts.blinker(fontSize: 48),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _PurchaseButton(
                label: 'Add To Cart',
                icon: Icons.add_shopping_cart_outlined,
                onPressed: () => _addToCart(context, product.code),
              ),
              const SizedBox(height: 10),
              _PurchaseButton(
                label: 'Buy Now',
                onPressed: () {
                  _addToCart(context, product.code);
                  Navigator.pushNamed(context, '/cart');
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<void> _addToCart(BuildContext context, String productCode) async {
  await CartService.instance.add(productCode);
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Added to cart')));
}

class _PurchaseButton extends StatelessWidget {
  const _PurchaseButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 38,
    child: FilledButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label, style: GoogleFonts.blinker(fontSize: 15)),
        ],
      ),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFA35710),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class _ShareButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFE2C7A0),
      borderRadius: BorderRadius.circular(999),
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SHARE',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 6),
          Icon(Icons.share, size: 18),
        ],
      ),
    ),
  );
}
