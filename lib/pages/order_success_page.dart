import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/order_success_details.dart';
import '../core/services/product_service.dart';
import '../widgets/app_footer.dart';

class OrderSuccessView extends StatelessWidget {
  const OrderSuccessView({required this.details, super.key});

  final OrderSuccessDetails details;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    primary: true,
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 76, 24, 96),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF5E6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFD5B48A),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F2D1E12),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: _OrderSuccessContent(details: details),
              ),
            ),
          ),
        ),
      ),
      const AppFooterSliver(),
    ],
  );
}

class _OrderSuccessContent extends StatelessWidget {
  const _OrderSuccessContent({required this.details});

  final OrderSuccessDetails details;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFFA35710),
            size: 42,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Order placed successfully!',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 40,
                color: const Color(0xFF5B351A),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'An invoice will be sent to your phone number or email: ${details.contactTarget}.',
        style: GoogleFonts.blinker(fontSize: 18, height: 1.35),
      ),
      const SizedBox(height: 24),
      const Divider(color: Color(0xFFD5B48A)),
      const SizedBox(height: 20),
      _SectionTitle('Delivery address'),
      const SizedBox(height: 8),
      Text(
        details.address,
        style: GoogleFonts.blinker(fontSize: 17, height: 1.2),
      ),
      const SizedBox(height: 24),
      _SectionTitle('Ordered items'),
      const SizedBox(height: 10),
      _PurchasedItems(items: details.items),
      const SizedBox(height: 14),
      Text(
        'Order ID: ${details.orderId}',
        style: GoogleFonts.blinker(
          fontSize: 14,
          color: const Color(0xFF746D64),
        ),
      ),
      const SizedBox(height: 22),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/collections',
            (route) => false,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFA35710),
          ),
          child: const Text('Continue shopping'),
        ),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.dmSerifDisplay(
      fontSize: 28,
      color: const Color(0xFF5B351A),
    ),
  );
}

class _PurchasedItems extends StatelessWidget {
  const _PurchasedItems({required this.items});

  final List<OrderSuccessItem> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 640;
      if (compact) {
        return Column(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PurchasedItemCard(item: item, compact: true),
              ),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 12),
                child: _PurchasedItemCard(item: items[index]),
              ),
            ),
        ],
      );
    },
  );
}

class _PurchasedItemCard extends StatelessWidget {
  const _PurchasedItemCard({required this.item, this.compact = false});

  final OrderSuccessItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final image = FutureBuilder<String>(
      future: ProductService().getProductImageUrlAsync(item.code),
      builder: (context, snapshot) => Container(
        width: compact ? 88 : double.infinity,
        height: compact ? 88 : 142,
        decoration: BoxDecoration(
          color: const Color(0xFFE4D9C7),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: snapshot.hasData
            ? Image.network(snapshot.data!, fit: BoxFit.cover)
            : const Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: Color(0xFF5B351A),
                ),
              ),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 21,
            color: const Color(0xFF5B351A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Code: ${item.code} • Qty ${item.quantity}',
          style: GoogleFonts.blinker(fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          '₹${item.amount}',
          style: GoogleFonts.blinker(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECE7DD),
        border: Border.all(color: const Color(0xFFD5B48A)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: compact
          ? Row(
              children: [
                image,
                const SizedBox(width: 14),
                Expanded(child: details),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [image, const SizedBox(height: 12), details],
            ),
    );
  }
}
