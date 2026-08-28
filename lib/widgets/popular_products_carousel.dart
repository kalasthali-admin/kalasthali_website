import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/models/product.dart';
import '../core/services/product_service.dart';
import '../core/services/whatsapp_order_service.dart';

class PopularProductsCarousel extends StatefulWidget {
  const PopularProductsCarousel({super.key});

  @override
  State<PopularProductsCarousel> createState() =>
      _PopularProductsCarouselState();
}

class _PopularProductsCarouselState extends State<PopularProductsCarousel> {
  late PageController _pageController;
  double _viewportFraction = 1;
  int _currentPage = 0;
  List<Product> _products = [];
  bool _isLoading = true;
  late ProductService _productService;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _viewportFraction);
    _productService = ProductService();
    _loadProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final viewportFraction = MediaQuery.sizeOf(context).width >= 700
        ? 0.5
        : 0.86;
    if (_viewportFraction == viewportFraction) {
      return;
    }

    final initialPage = _pageController.hasClients
        ? _pageController.page?.round() ?? _currentPage
        : _currentPage;
    _pageController.dispose();
    _viewportFraction = viewportFraction;
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: _viewportFraction,
    );
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getPopularProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading products: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_products.isNotEmpty) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_products.isNotEmpty) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final showsTwoCards = screenWidth >= 700;
    final carouselWidth = isDesktop
        ? (screenWidth > 1656 ? 1600.0 : screenWidth - 56)
        : (screenWidth > 0 ? screenWidth : 360.0);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return const Center(child: Text('No popular products available'));
    }

    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: carouselWidth),
            child: Row(
              children: [
                // Previous button (Desktop only)
                if (isDesktop)
                  SizedBox(
                    width: 70,
                    child: Center(
                      child: GestureDetector(
                        onTap: _previousPage,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8),
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Color(0xFF914B0D),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Carousel
                Expanded(
                  child: SizedBox(
                    height: isDesktop ? 500 : 590,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index % _products.length;
                            });
                          },
                          itemBuilder: (context, index) {
                            final product = _products[index % _products.length];
                            final card = isDesktop
                                ? _DesktopProductCard(product: product)
                                : _MobileProductCard(product: product);

                            return Padding(
                              padding: showsTwoCards
                                  ? const EdgeInsets.symmetric(horizontal: 15)
                                  : const EdgeInsets.symmetric(horizontal: 6),
                              child: card,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Next button (Desktop only)
                if (isDesktop)
                  SizedBox(
                    width: 70,
                    child: Center(
                      child: GestureDetector(
                        onTap: _nextPage,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8),
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF914B0D),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _products.length,
            (index) => GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? const Color(0xFF914B0D)
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopProductCard extends StatelessWidget {
  final Product product;

  const _DesktopProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x80914B0D), width: 2),
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          // Image section
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox.expand(
                  child: _ProductImage(productCode: product.code),
                ),
              ),
            ),
          ),
          // Content section
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F1E25),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.description,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 16,
                      height: 1.5,
                      color: const Color(0xFF4B463E),
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => _openProduct(context, product.code),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF914B0D),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'More Info',
                            style: TextStyle(
                              color: Color(0xFF914B0D),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => WhatsAppOrderService.requestOrder(
                            context,
                            product,
                          ),
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('Buy Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF914B0D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileProductCard extends StatelessWidget {
  final Product product;

  const _MobileProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x80914B0D), width: 2),
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _ProductImage(productCode: product.code),
          ),
          // Content section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F1E25),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7D0AE),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFF914B0D),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          product.type.toUpperCase(),
                          style: GoogleFonts.blinker(
                            color: const Color(0xFF5B351A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 16,
                      height: 1.5,
                      color: const Color(0xFF4B463E),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () => _openProduct(context, product.code),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF914B0D),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'More Info',
                            style: TextStyle(
                              color: Color(0xFF914B0D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () => WhatsAppOrderService.requestOrder(
                            context,
                            product,
                          ),
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('Buy Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF914B0D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.productCode});

  final String productCode;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: ProductService().getProductImageUrlAsync(productCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final imageUrl = snapshot.data;
        if (imageUrl == null || imageUrl.isEmpty) {
          return const _ProductImageError();
        }

        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const _ProductImageError(),
        );
      },
    );
  }
}

void _openProduct(BuildContext context, String productCode) {
  Navigator.pushNamed(context, '/product?${Uri.encodeComponent(productCode)}');
}

class _ProductImageError extends StatelessWidget {
  const _ProductImageError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, color: Colors.red, size: 48),
          SizedBox(height: 8),
          Text(
            'Failed to load image',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
