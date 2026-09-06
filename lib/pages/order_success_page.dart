import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/order_success_details.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_scaffold.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({this.details, super.key});

  final OrderSuccessDetails? details;

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Order placed',
    currentRoute: '/order-success',
    centerBody: false,
    body: SingleChildScrollView(
      primary: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 76, 24, 96),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
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
                  child: details == null
                      ? const _MissingOrderDetails()
                      : _OrderSuccessContent(details: details!),
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    ),
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
      for (final item in details.items)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${item.name} x ${item.quantity}',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22,
                    color: const Color(0xFF5B351A),
                  ),
                ),
              ),
              Text(
                '₹${item.amount}',
                style: GoogleFonts.blinker(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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

class _MissingOrderDetails extends StatelessWidget {
  const _MissingOrderDetails();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Order placed successfully!',
        style: GoogleFonts.dmSerifDisplay(
          fontSize: 38,
          color: const Color(0xFF5B351A),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Your payment was completed. Please check your email or phone for the invoice.',
        style: GoogleFonts.blinker(fontSize: 18),
      ),
    ],
  );
}
