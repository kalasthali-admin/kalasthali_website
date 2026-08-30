import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product.dart';

class WhatsAppOrderService {
  WhatsAppOrderService._();

  // Provide this during the web build, for example: --dart-define=WHATSAPP_BUSINESS_NUMBER=919876543210
  static const _businessNumber = String.fromEnvironment(
    'WHATSAPP_BUSINESS_NUMBER',
  );

  static Future<void> requestOrder(
    BuildContext context,
    Product product,
  ) async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Your Order'),
        content: const Text(
          'You will now be directed to our WhatsApp DM to request your order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
    if (shouldProceed != true || !context.mounted) return;

    if (_businessNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp ordering has not been configured yet.'),
        ),
      );
      return;
    }

    final price = product.price?.startsWith('₹') == true
        ? product.price!
        : '₹${product.price ?? '-'}';
    final message =
        '''Hello Kalasthali,

I would like to request this product:
**Product: ${product.name}

Code: ${product.code}

Price: $price**

Please let me know the next steps to place my order.''';
    final uri = Uri.parse(
      'https://wa.me/$_businessNumber?text=${Uri.encodeComponent(message)}',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
    }
  }
}
