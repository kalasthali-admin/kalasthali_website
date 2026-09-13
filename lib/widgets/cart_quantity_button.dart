import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/product.dart';
import '../core/services/cart_service.dart';

class CartQuantityButton extends StatefulWidget {
  const CartQuantityButton({
    required this.product,
    this.height = 40,
    this.compact = false,
    this.filled = true,
    this.fontSize,
    this.iconSize,
    super.key,
  });

  final Product product;
  final double height;
  final bool compact;
  final bool filled;
  final double? fontSize;
  final double? iconSize;

  @override
  State<CartQuantityButton> createState() => _CartQuantityButtonState();
}

class _CartQuantityButtonState extends State<CartQuantityButton> {
  late Future<int> _quantity;
  StreamSubscription<int>? _subscription;
  var _showAddedTick = false;

  @override
  void initState() {
    super.initState();
    _quantity = CartService.instance.quantityFor(widget.product.code);
    _subscription = CartService.instance.cartVersion.stream.listen((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void didUpdateWidget(covariant CartQuantityButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.code != widget.product.code) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _quantity = CartService.instance.quantityFor(widget.product.code);
    });
  }

  Future<void> _add() async {
    final added = await CartService.instance.add(widget.product);
    if (!mounted) return;
    if (!added) {
      Navigator.pushNamed(context, '/account');
      return;
    }
    setState(() {
      _showAddedTick = true;
      _quantity = Future.value(1);
    });
    Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _showAddedTick = false;
          _quantity = CartService.instance.quantityFor(widget.product.code);
        });
      }
    });
  }

  Future<void> _change(int current, int delta) async {
    await CartService.instance.setQuantity(
      widget.product.code,
      current + delta,
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_showAddedTick) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: widget.filled
            ? FilledButton(
                onPressed: null,
                style: _buttonStyle(),
                child: const Icon(Icons.check, color: Colors.white, size: 22),
              )
            : OutlinedButton(
                onPressed: null,
                style: _buttonStyle(),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFFA35710),
                  size: 22,
                ),
              ),
      );
    }

    return FutureBuilder<int>(
      future: _quantity,
      builder: (context, snapshot) {
        final quantity = snapshot.data ?? 0;
        if (quantity <= 0) {
          return SizedBox(
            height: widget.height,
            width: double.infinity,
            child: widget.filled
                ? FilledButton.icon(
                    onPressed:
                        snapshot.connectionState == ConnectionState.waiting
                        ? null
                        : _add,
                    icon: Icon(
                      Icons.add_shopping_cart_outlined,
                      size: widget.iconSize ?? (widget.compact ? 15 : 17),
                    ),
                    label: const Text('Add to Cart'),
                    style: _buttonStyle(),
                  )
                : OutlinedButton.icon(
                    onPressed:
                        snapshot.connectionState == ConnectionState.waiting
                        ? null
                        : _add,
                    icon: Icon(
                      Icons.add_shopping_cart_outlined,
                      size: widget.iconSize ?? (widget.compact ? 15 : 17),
                    ),
                    label: const Text('Add to Cart'),
                    style: _buttonStyle(),
                  ),
          );
        }
        return SizedBox(
          height: widget.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE7D0AE),
              border: Border.all(color: const Color(0xFFA35710), width: 1.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CounterButton(
                  icon: Icons.remove,
                  onPressed: () => _change(quantity, -1),
                ),
                Container(
                  width: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC38A55),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '$quantity',
                    style: GoogleFonts.ibmPlexSans(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F1E25),
                    ),
                  ),
                ),
                _CounterButton(
                  icon: Icons.add,
                  onPressed: () => _change(quantity, 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ButtonStyle _buttonStyle() {
    final textStyle = GoogleFonts.ibmPlexSans(
      fontSize: widget.fontSize ?? (widget.compact ? 14 : 16),
      fontWeight: FontWeight.w700,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    final padding = EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 12);
    return widget.filled
        ? FilledButton.styleFrom(
            backgroundColor: const Color(0xFFA35710),
            disabledBackgroundColor: const Color(0xFFA35710),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            padding: padding,
            shape: shape,
            textStyle: textStyle,
          )
        : OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFA35710),
            disabledForegroundColor: const Color(0xFFA35710),
            side: const BorderSide(color: Color(0xFFA35710), width: 1.3),
            padding: padding,
            shape: shape,
            textStyle: textStyle,
          );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: Icon(icon, size: 17),
    color: const Color(0xFF1F1E25),
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
  );
}
