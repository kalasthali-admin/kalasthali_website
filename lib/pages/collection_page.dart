import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/models/product.dart';
import '../core/services/product_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_footer.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({this.initialCategory, this.initialSearch, super.key});
  final String? initialCategory;
  final String? initialSearch;
  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  late final Future<List<Product>> products = ProductService().getProducts();
  late final TextEditingController search;
  String? category;
  @override
  void initState() {
    super.initState();
    category = widget.initialCategory;
    search = TextEditingController(text: widget.initialSearch ?? '');
    search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void select(String value) => Navigator.pushReplacementNamed(
    context,
    Uri(
      path: '/collections',
      queryParameters: {
        if (category != value) 'category': value,
        if (search.text.trim().isNotEmpty) 'search': search.text.trim(),
      },
    ).toString(),
  );
  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Collection',
    currentRoute: '/collections',
    centerBody: false,
    body: FutureBuilder<List<Product>>(
      future: products,
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        return LayoutBuilder(
          builder: (context, box) {
            final mobile = box.maxWidth < 700;
            final query = search.text.toLowerCase();
            final categories =
                snap.data!
                    .map((product) => product.type.trim())
                    .where((type) => type.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort(
                    (left, right) =>
                        left.toLowerCase().compareTo(right.toLowerCase()),
                  );
            final selectedCategory =
                categories.any((value) => _key(value) == _key(category ?? ''))
                ? category
                : null;
            final filtered = snap.data!
                .where(
                  (p) =>
                      (selectedCategory == null ||
                          _matchesCategory(p.type, selectedCategory)) &&
                      (query.isEmpty ||
                          '${p.name} ${p.description} ${p.specifications ?? ''}'
                              .toLowerCase()
                              .contains(query)),
                )
                .toList();
            return SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      mobile ? 20 : 44,
                      mobile ? 66 : 88,
                      mobile ? 20 : 44,
                      100,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'SHOP COLLECTION',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: mobile ? 34 : 42,
                                letterSpacing: mobile ? 2 : 8,
                                color: const Color(0xFF513019),
                              ),
                            ),
                            const SizedBox(height: 42),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 575),
                              child: TextField(
                                controller: search,
                                style: GoogleFonts.blinker(
                                  fontSize: mobile ? 14 : 17,
                                  color: const Color(0xFF1F1E25),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search for a product',
                                  hintStyle: GoogleFonts.blinker(
                                    fontSize: mobile ? 14 : 17,
                                    color: const Color(0xFF746D64),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    size: mobile ? 25 : 31,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: mobile ? 12 : 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF694425),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: mobile ? 12 : 16,
                              runSpacing: mobile ? 14 : 12,
                              children: categories
                                  .map(
                                    (c) => ChoiceChip(
                                      label: Text(
                                        c.replaceAll('-', ' ').toUpperCase(),
                                        style: GoogleFonts.blinker(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: mobile ? 1.4 : 2,
                                        ),
                                      ),
                                      selected:
                                          _key(selectedCategory ?? '') ==
                                          _key(c),
                                      onSelected: (_) => select(c),
                                      selectedColor: const Color(0xFFE2C7A0),
                                      backgroundColor: const Color(0xFFE9E2D6),
                                      side: const BorderSide(
                                        color: Color(0xFFA85C18),
                                        width: 1.5,
                                      ),
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            SizedBox(height: mobile ? 120 : 110),
                            if (filtered.isEmpty)
                              const Text('No products found.')
                            else
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 900,
                                ),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: mobile ? 2 : 3,
                                        crossAxisSpacing: mobile ? 28 : 10,
                                        mainAxisSpacing: mobile ? 28 : 10,
                                        childAspectRatio: mobile ? .58 : .64,
                                      ),
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) =>
                                      _Card(product: filtered[i]),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const AppFooter(),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

String _key(String v) => v.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

bool _matchesCategory(String productType, String category) {
  return _key(productType) == _key(category);
}

class _Card extends StatefulWidget {
  const _Card({required this.product});
  final Product product;

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal = constraints.maxWidth >= 360;
      final isDesktop = MediaQuery.sizeOf(context).width >= 700;
      final image = ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: FutureBuilder<String>(
          future: ProductService().getProductImageUrlAsync(widget.product.code),
          builder: (_, s) => !s.hasData || s.data!.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Image.network(
                  s.data!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
                ),
        ),
      );

      final details = _CardDetails(
        product: widget.product,
        compact: !isDesktop,
      );
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            '/product?${Uri.encodeComponent(widget.product.code)}',
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFECE7DD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD7CBB9), width: 2),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? const Color(0x592D1E12)
                      : const Color(0x332D1E12),
                  blurRadius: _isHovered ? 22 : 12,
                  offset: Offset(0, _isHovered ? 10 : 5),
                ),
              ],
            ),
            child: horizontal
                ? Row(
                    children: [
                      SizedBox(width: 155, child: image),
                      const SizedBox(width: 14),
                      Expanded(child: details),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(child: image),
                      const SizedBox(height: 10),
                      details,
                    ],
                  ),
          ),
        ),
      );
    },
  );
}

class _CardDetails extends StatelessWidget {
  const _CardDetails({required this.product, required this.compact});
  final Product product;
  final bool compact;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        product.name,
        maxLines: 2,
        overflow: TextOverflow.clip,
        softWrap: true,
        style: GoogleFonts.dmSerifDisplay(
          fontSize: compact ? 14 : 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF5B351A),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        product.price?.startsWith('₹') == true
            ? product.price!
            : '₹${product.price ?? '-'}',
        style: GoogleFonts.blinker(fontSize: 24),
      ),
    ],
  );
}
