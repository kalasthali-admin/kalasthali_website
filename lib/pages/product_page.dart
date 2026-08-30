import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/product.dart';
import '../core/services/product_service.dart';
import '../core/services/whatsapp_order_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_footer.dart';

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
        final screenSize = MediaQuery.sizeOf(context);
        final tabletPortrait =
            screenSize.height > screenSize.width && screenSize.width < 1100;
        // Portrait tablets need the stacked composition too; the two-column
        // layout leaves both the gallery and product copy too narrow there.
        final mobile = constraints.maxWidth < 800 || tabletPortrait;
        return SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  mobile ? 22 : 54,
                  mobile ? 70 : 72,
                  mobile ? 22 : 54,
                  100,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: mobile
                        ? _MobileProductLayout(product: product)
                        : _DesktopProductLayout(product: product),
                  ),
                ),
              ),
              const AppFooter(),
            ],
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
      Center(child: _ShareButton(productCode: product.code)),
      const SizedBox(height: 20),
      _ProductCopy(product: product, centeredTitle: true),
      const SizedBox(height: 44),
      _PurchasePanel(product: product),
      const SizedBox(height: 28),
      const _ProductDisclaimer(),
    ],
  );
}

class _DesktopProductLayout extends StatefulWidget {
  const _DesktopProductLayout({required this.product});
  final Product product;

  @override
  State<_DesktopProductLayout> createState() => _DesktopProductLayoutState();
}

class _DesktopProductLayoutState extends State<_DesktopProductLayout> {
  final _detailsKey = GlobalKey();
  double? _detailsHeight;

  void _measureDetails() {
    final height = _detailsKey.currentContext?.size?.height;
    if (height == null ||
        !mounted ||
        (_detailsHeight != null && (_detailsHeight! - height).abs() < .5)) {
      return;
    }
    setState(() => _detailsHeight = height);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final panelWidth = (constraints.maxWidth - 50) / 2;
      final naturalGalleryHeight = (panelWidth - 24) / .78 + 54;
      final panelHeight = _detailsHeight ?? naturalGalleryHeight;

      WidgetsBinding.instance.addPostFrameCallback((_) => _measureDetails());

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: panelHeight,
                  child: _ProductImagePanel(
                    product: widget.product,
                    expandToParent: true,
                  ),
                ),
              ),
              const SizedBox(width: 56),
              Expanded(
                child: Column(
                  key: _detailsKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _ShareButton(productCode: widget.product.code),
                    ),
                    const SizedBox(height: 20),
                    _ProductCopy(product: widget.product),
                    const SizedBox(height: 44),
                    _PurchasePanel(product: widget.product),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          const _ProductDisclaimer(),
        ],
      );
    },
  );
}

class _ProductImagePanel extends StatefulWidget {
  const _ProductImagePanel({
    required this.product,
    this.expandToParent = false,
  });

  final Product product;
  final bool expandToParent;
  @override
  State<_ProductImagePanel> createState() => _ProductImagePanelState();
}

class _ProductImagePanelState extends State<_ProductImagePanel> {
  int currentImage = 0;
  final PageController _pageController = PageController();
  final Set<String> _prefetchedImages = {};

  void _prefetchAdjacentImages(List<String> imageUrls) {
    if (!mounted || imageUrls.length < 2) return;

    for (final index in {
      (currentImage + 1) % imageUrls.length,
      (currentImage - 1 + imageUrls.length) % imageUrls.length,
    }) {
      final imageUrl = imageUrls[index];
      if (_prefetchedImages.add(imageUrl)) {
        precacheImage(NetworkImage(imageUrl), context);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = FutureBuilder<List<String>>(
      future: ProductService().getProductImageUrlsAsync(widget.product.code),
      builder: (_, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final imageUrls = snapshot.data!;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _prefetchAdjacentImages(imageUrls),
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: PageView.builder(
            controller: _pageController,
            allowImplicitScrolling: true,
            itemCount: imageUrls.length,
            onPageChanged: (index) => setState(() => currentImage = index),
            itemBuilder: (_, index) => Image.network(
              imageUrls[index],
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
            ),
          ),
        );
      },
    );

    return Container(
      height: widget.expandToParent ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E3D8),
        border: Border.all(color: const Color(0xFFE0D2BE), width: 2),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332D1E12),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.expandToParent)
            Expanded(child: gallery)
          else
            AspectRatio(aspectRatio: .78, child: gallery),
          const SizedBox(height: 12),
          FutureBuilder<List<String>>(
            future: ProductService().getProductImageUrlsAsync(
              widget.product.code,
            ),
            builder: (_, snapshot) {
              final imageCount = snapshot.data?.length ?? 0;
              return Row(
                children: [
                  _GalleryArrow(
                    icon: Icons.chevron_left,
                    onPressed: imageCount < 2 || currentImage == 0
                        ? null
                        : () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        imageCount,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index == currentImage
                                ? Icons.circle
                                : Icons.circle_outlined,
                            size: index == currentImage ? 15 : 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _GalleryArrow(
                    icon: Icons.chevron_right,
                    onPressed: imageCount < 2 || currentImage == imageCount - 1
                        ? null
                        : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GalleryArrow extends StatelessWidget {
  const _GalleryArrow({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: Icon(icon, size: 34),
    color: const Color(0xFF1F1E25),
    disabledColor: const Color(0xFF1F1E25).withValues(alpha: .28),
    tooltip: icon == Icons.chevron_left ? 'Previous image' : 'Next image',
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
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFA35710), width: 1.5),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.price?.startsWith('₹') == true
                  ? product.price!
                  : '₹${product.price ?? '-'}',
              style: GoogleFonts.blinker(fontSize: 35),
            ),
            // Text(
            //   'Price',
            //   style: GoogleFonts.blinker(
            //     fontSize: 18,
            //     color: Colors.grey.shade700,
            //   ),
            // ),
          ],
        ),
        Spacer(),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 5, horizontal: 10),
          child: Center(
            child: _PurchaseButton(
              label: 'Buy Now',
              icon: Icons.chat_outlined,
              onPressed: () =>
                  WhatsAppOrderService.requestOrder(context, product),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PurchaseButton extends StatelessWidget {
  const _PurchaseButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final Future<void> Function() onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200,
    height: 60,
    child: _button(onPressed: () => onPressed()),
  );

  Widget _button({required VoidCallback onPressed}) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFA35710),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Text(label, style: GoogleFonts.blinker(fontSize: 20)),
      ],
    ),
  );
}

class _ProductDisclaimer extends StatelessWidget {
  const _ProductDisclaimer();

  @override
  Widget build(BuildContext context) => Text(
    'Disclaimer: The model images are for illustrative purposes only and are intended to help you understand the placement and overall look of the hand-painted design on the saree. The actual colours, detailing, brushwork, and design may vary slightly from the images shown.\n\nFor an accurate view of the artwork and its finer details, please refer to the close-up product image.',
    style: GoogleFonts.blinker(
      fontSize: 16,
      height: 1.35,
      color: const Color(0xFF4E463E),
    ),
  );
}

class _ShareButton extends StatefulWidget {
  const _ShareButton({required this.productCode});

  final String productCode;

  @override
  State<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<_ShareButton> {
  bool _copied = false;

  Future<void> _copyProductUrl() async {
    if (_copied) return;

    final productUrl = Uri.base
        .replace(
          path: '/product',
          query: Uri.encodeComponent(widget.productCode),
        )
        .toString();
    await Clipboard.setData(ClipboardData(text: productUrl));
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Product Link Copied!')));
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFE2C7A0),
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: _copyProductUrl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: _copied
            ? const Text(
                'Link Coped!',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              )
            : const Row(
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
    ),
  );
}
