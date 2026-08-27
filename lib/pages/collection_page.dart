import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/models/product.dart';
import '../core/services/product_service.dart';
import '../widgets/app_scaffold.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({this.initialCategory, super.key});
  final String? initialCategory;
  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  static const categories = ['home-decor', 'sarees', 'dresses'];
  late final Future<List<Product>> products = ProductService().getProducts();
  final search = TextEditingController();
  String? category;
  @override
  void initState() {
    super.initState();
    category = categories.contains(widget.initialCategory)
        ? widget.initialCategory
        : null;
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
      queryParameters: category == value ? null : {'category': value},
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
            final filtered = snap.data!
                .where(
                  (p) =>
                      (category == null || _key(p.type) == _key(category!)) &&
                      (query.isEmpty ||
                          '${p.name} ${p.description} ${p.type}'
                              .toLowerCase()
                              .contains(query)),
                )
                .toList();
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                mobile ? 20 : 44,
                mobile ? 66 : 88,
                mobile ? 20 : 44,
                100,
              ),
              child: Column(
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
                      decoration: InputDecoration(
                        hintText: 'Search for a product',
                        prefixIcon: const Icon(Icons.search, size: 31),
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
                    spacing: 12,
                    children: categories
                        .map(
                          (c) => ChoiceChip(
                            label: Text(
                              c.replaceAll('-', ' ').toUpperCase(),
                              style: const TextStyle(letterSpacing: 2),
                            ),
                            selected: category == c,
                            onSelected: (_) => select(c),
                            selectedColor: const Color(0xFFE2C7A0),
                            backgroundColor: const Color(0xFFE9E2D6),
                            side: const BorderSide(
                              color: Color(0xFFA85C18),
                              width: 1.5,
                            ),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 9,
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
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: mobile ? 2 : 3,
                          crossAxisSpacing: mobile ? 26 : 30,
                          mainAxisSpacing: mobile ? 28 : 30,
                          childAspectRatio: mobile ? .57 : .64,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _Card(product: filtered[i]),
                      ),
                    ),
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

class _Card extends StatelessWidget {
  const _Card({required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFECE7DD),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFD7CBB9), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x332D1E12),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: FutureBuilder<String>(
              future: ProductService().getProductImageUrlAsync(product.code),
              builder: (_, s) => !s.hasData || s.data!.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Image.network(
                      s.data!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5B351A),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                product.price?.startsWith('₹') == true
                    ? product.price!
                    : '₹${product.price ?? '-'}',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                minimumSize: const Size(42, 42),
                padding: EdgeInsets.zero,
                backgroundColor: const Color(0xFFA35710),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Icon(Icons.add_shopping_cart_outlined),
            ),
          ],
        ),
      ],
    ),
  );
}
