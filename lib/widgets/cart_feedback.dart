import 'package:flutter/material.dart';

typedef CartButtonBuilder =
    Widget Function(
      BuildContext context,
      bool confirmed,
      VoidCallback onPressed,
    );

class CartButtonFeedback extends StatefulWidget {
  const CartButtonFeedback({
    required this.onAdd,
    required this.builder,
    super.key,
  });

  final Future<void> Function() onAdd;
  final CartButtonBuilder builder;

  @override
  State<CartButtonFeedback> createState() => _CartButtonFeedbackState();
}

class _CartButtonFeedbackState extends State<CartButtonFeedback> {
  bool _confirmed = false;

  Future<void> _handlePress() async {
    if (_confirmed) return;

    await widget.onAdd();
    if (!mounted) return;

    setState(() => _confirmed = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _confirmed = false);
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _confirmed, _handlePress);
}

void showAddedToCartSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Added to cart'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
}
