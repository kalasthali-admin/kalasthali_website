import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models/order_success_details.dart';
import '../core/responsive.dart';
import '../core/services/auth_service.dart';
import '../core/services/cart_service.dart';
import '../core/services/payment_service.dart';
import '../core/services/product_service.dart';
import 'order_success_page.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_scaffold.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<UserCartItem>> _items;
  List<Map<String, dynamic>> _addresses = const [];
  var _addressesLoading = true;
  var _addressUpdating = false;
  var _cartUpdating = false;
  OrderSuccessDetails? _orderSuccess;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _items = CartService.instance.loadItems();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _addressesLoading = false);
      return;
    }
    final rows =
        await Supabase.instance.client
                .from('user_addresses')
                .select()
                .eq('user_id', user.id)
                .order('created_at')
            as List;
    if (!mounted) return;
    setState(() {
      _addresses = rows.cast<Map<String, dynamic>>();
      _addressesLoading = false;
    });
  }

  Future<void> _setQuantity(String code, int quantity) async {
    if (_cartUpdating) return;
    setState(() => _cartUpdating = true);
    try {
      await CartService.instance.setQuantity(code, quantity);
      final refreshedItems = await CartService.instance.loadItems();
      if (mounted) {
        setState(() {
          _items = Future.value(refreshedItems);
        });
      }
    } finally {
      if (mounted) setState(() => _cartUpdating = false);
    }
  }

  Future<void> _selectAddress(String id) async {
    setState(() {
      _addressUpdating = true;
      _addresses = _addresses
          .map((address) => {...address, 'is_selected': address['id'] == id})
          .toList(growable: false);
    });
    try {
      await Supabase.instance.client
          .from('user_addresses')
          .update({'is_selected': true})
          .eq('id', id);
      await _loadAddresses();
    } finally {
      if (mounted) setState(() => _addressUpdating = false);
    }
  }

  void _showOrderSuccess(OrderSuccessDetails details) {
    setState(() => _orderSuccess = details);
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Cart',
    currentRoute: '/cart',
    centerBody: false,
    body: _orderSuccess != null
        ? OrderSuccessView(details: _orderSuccess!)
        : FutureBuilder<List<UserCartItem>>(
            future: _items,
            builder: (context, snapshot) {
              final loading =
                  snapshot.connectionState != ConnectionState.done &&
                  snapshot.data == null;
              final items = snapshot.data ?? const <UserCartItem>[];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final mobile = useCompactLayout(context, breakpoint: 900);
                  return CustomScrollView(
                    primary: true,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            mobile ? 22 : 32,
                            mobile ? 78 : 72,
                            mobile ? 22 : 32,
                            mobile ? 78 : 80,
                          ),
                          child: loading
                              ? SizedBox(
                                  height: constraints.maxHeight * .55,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : items.isEmpty
                              ? SizedBox(
                                  height: constraints.maxHeight * .55,
                                  child: _EmptyCart(),
                                )
                              : Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 1180,
                                    ),
                                    child: _CartContent(
                                      items: items,
                                      addresses: _addresses,
                                      loadingAddresses: _addressesLoading,
                                      updatingAddress: _addressUpdating,
                                      updatingCart: _cartUpdating,
                                      mobile: mobile,
                                      onQuantityChanged: _setQuantity,
                                      onAddressSelected: _selectAddress,
                                      onOrderCompleted: _showOrderSuccess,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const AppFooterSliver(),
                    ],
                  );
                },
              );
            },
          ),
  );
}

class _CartContent extends StatelessWidget {
  const _CartContent({
    required this.items,
    required this.addresses,
    required this.loadingAddresses,
    required this.updatingAddress,
    required this.updatingCart,
    required this.mobile,
    required this.onQuantityChanged,
    required this.onAddressSelected,
    required this.onOrderCompleted,
  });

  final List<UserCartItem> items;
  final List<Map<String, dynamic>> addresses;
  final bool loadingAddresses;
  final bool updatingAddress;
  final bool updatingCart;
  final bool mobile;
  final void Function(String code, int quantity) onQuantityChanged;
  final ValueChanged<String> onAddressSelected;
  final ValueChanged<OrderSuccessDetails> onOrderCompleted;

  @override
  Widget build(BuildContext context) {
    final summary = _CartSummary(
      items: items,
      addresses: addresses,
      loadingAddress: loadingAddresses,
      updatingAddress: updatingAddress,
      onAddressSelected: onAddressSelected,
      onOrderCompleted: onOrderCompleted,
    );

    final list = Column(
      children: [
        for (final item in items)
          _CartProductCard(item: item, onQuantityChanged: onQuantityChanged),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Cart',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: mobile ? 40 : 48,
            color: const Color(0xFF5B351A),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(color: Color(0xFF9A8267), thickness: 1),
        if (updatingCart) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            minHeight: 3,
            color: Color(0xFFA35710),
            backgroundColor: Color(0xFFD8C5AD),
          ),
        ],
        const SizedBox(height: 24),
        if (mobile) ...[
          list,
          const SizedBox(height: 34),
          Center(
            child: SizedBox(
              width: 240,
              height: 62,
              child: FilledButton(
                onPressed: () => _openCheckoutSheet(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFA35710),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0x66382212),
                ),
                child: Text(
                  'Checkout',
                  style: GoogleFonts.ibmPlexSans(fontSize: 28),
                ),
              ),
            ),
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: list),
              const SizedBox(width: 44),
              Expanded(flex: 4, child: summary),
            ],
          ),
      ],
    );
  }

  Future<void> _openCheckoutSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => DraggableScrollableSheet(
          initialChildSize: .54,
          minChildSize: .48,
          maxChildSize: .94,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFFD6BFA6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              child: _CartSummary(
                items: items,
                addresses: addresses,
                loadingAddress: loadingAddresses,
                updatingAddress: updatingAddress,
                onAddressSelected: onAddressSelected,
                onOrderCompleted: (details) {
                  Navigator.of(sheetContext).pop();
                  onOrderCompleted(details);
                },
                sheetStyle: true,
              ),
            ),
          ),
        ),
      );
}

class _CartProductCard extends StatelessWidget {
  const _CartProductCard({required this.item, required this.onQuantityChanged});

  final UserCartItem item;
  final void Function(String code, int quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final price = _priceNumber(product?.price);
    final total = price == null ? null : price * item.quantity;
    final mobile = MediaQuery.sizeOf(context).width < 650;

    return Container(
      margin: EdgeInsets.only(bottom: mobile ? 32 : 22),
      padding: EdgeInsets.all(mobile ? 8 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFECE7DD),
        border: Border.all(
          color: mobile ? Colors.white : const Color(0xFFD5B48A),
          width: mobile ? 1.4 : 1.5,
        ),
        borderRadius: BorderRadius.circular(mobile ? 22 : 16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2D1E12),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: mobile
            ? () => Navigator.pushNamed(
                context,
                '/product?code=${Uri.encodeComponent(item.code)}',
              )
            : null,
        borderRadius: BorderRadius.circular(mobile ? 22 : 16),
        splashColor: const Color(0x33A35710),
        highlightColor: const Color(0x1AA35710),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 650;
            if (compact) {
              return _CompactCartProductContent(
                item: item,
                price: price,
                total: total,
                onQuantityChanged: onQuantityChanged,
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 340, child: _CartItemLead(item: item)),
                const SizedBox(width: 24),
                Expanded(
                  child: _CartItemMetrics(
                    item: item,
                    price: price,
                    total: total,
                    onQuantityChanged: onQuantityChanged,
                  ),
                ),
                const SizedBox(width: 14),
                IconButton(
                  onPressed: () => onQuantityChanged(item.code, 0),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove from cart',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CompactCartProductContent extends StatelessWidget {
  const _CompactCartProductContent({
    required this.item,
    required this.price,
    required this.total,
    required this.onQuantityChanged,
  });

  final UserCartItem item;
  final int? price;
  final int? total;
  final void Function(String code, int quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final sizes = (product?.sizes ?? item.size ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          height: 190,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: FutureBuilder<String>(
              future: ProductService().getProductImageUrlAsync(item.code),
              builder: (context, snapshot) {
                final url = snapshot.data;
                if (url == null || url.isEmpty) {
                  return const ColoredBox(color: Color(0xFFD8D0C3));
                }
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: Color(0xFFD8D0C3)),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product?.type ?? 'Product',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 14,
                  color: const Color(0xFF746D64),
                ),
              ),
              Text(
                product?.name ?? item.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 24,
                  height: .92,
                  color: const Color(0xFF5B351A),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Size',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            color: const Color(0xFF746D64),
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (sizes.isNotEmpty)
                          _SizeChips(sizes: sizes, compact: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Quantity',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          color: const Color(0xFF746D64),
                        ),
                      ),
                      const SizedBox(height: 3),
                      _CartCounter(
                        quantity: item.quantity,
                        onChanged: (quantity) =>
                            onQuantityChanged(item.code, quantity),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MetricBlock(label: 'Price', value: _money(price)),
                  _MetricBlock(
                    label: 'Total',
                    value: _money(total),
                    emphasis: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemLead extends StatelessWidget {
  const _CartItemLead({required this.item});

  final UserCartItem item;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          height: 170,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FutureBuilder<String>(
              future: ProductService().getProductImageUrlAsync(item.code),
              builder: (context, snapshot) {
                final url = snapshot.data;
                if (url == null || url.isEmpty) {
                  return const ColoredBox(color: Color(0xFFD8D0C3));
                }
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product?.type ?? 'Product',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 15,
                  color: const Color(0xFF746D64),
                ),
              ),
              Text(
                product?.name ?? item.productName,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 23,
                  height: 1,
                  color: const Color(0xFF5B351A),
                ),
              ),
              const SizedBox(height: 18),
              if ((product?.sizes ?? item.size ?? '').trim().isNotEmpty) ...[
                Text(
                  'Size',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    color: const Color(0xFF746D64),
                  ),
                ),
                const SizedBox(height: 6),
                _SizeChips(
                  sizes: (product?.sizes ?? item.size ?? '')
                      .split(',')
                      .map((value) => value.trim())
                      .where((value) => value.isNotEmpty)
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemMetrics extends StatelessWidget {
  const _CartItemMetrics({
    required this.item,
    required this.price,
    required this.total,
    required this.onQuantityChanged,
  });

  final UserCartItem item;
  final int? price;
  final int? total;
  final void Function(String code, int quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _MetricBlock(label: 'Price', value: _money(price)),
      _MetricBlock(
        label: 'Quantity',
        valueWidget: _CartCounter(
          quantity: item.quantity,
          onChanged: (quantity) => onQuantityChanged(item.code, quantity),
        ),
      ),
      _MetricBlock(label: 'Total', value: _money(total), emphasis: true),
    ],
  );
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    this.value,
    this.valueWidget,
    this.emphasis = false,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool emphasis;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 15,
          color: const Color(0xFF746D64),
        ),
      ),
      const SizedBox(height: 4),
      valueWidget ??
          Text(
            value ?? '-',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 24,
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.w600,
              color: const Color(0xFF111111),
            ),
          ),
    ],
  );
}

class _CartCounter extends StatelessWidget {
  const _CartCounter({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFE7D0AE),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MiniCounterButton(
          icon: Icons.remove,
          onPressed: () => onChanged(quantity - 1),
        ),
        Container(
          width: 32,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFC38A55),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '$quantity',
            style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w800),
          ),
        ),
        _MiniCounterButton(
          icon: Icons.add,
          onPressed: () => onChanged(quantity + 1),
        ),
      ],
    ),
  );
}

class _MiniCounterButton extends StatelessWidget {
  const _MiniCounterButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: Icon(icon, size: 16),
    padding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints.tightFor(width: 28, height: 28),
  );
}

class _SizeChips extends StatelessWidget {
  const _SizeChips({required this.sizes, this.compact = false});

  final List<String> sizes;
  final bool compact;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: compact ? 4 : 7,
    children: [
      for (final size in sizes.take(4))
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 11,
            vertical: compact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            color: size == sizes.first
                ? const Color(0xFFC38A55)
                : const Color(0xFFD8C5AD),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            size.toUpperCase(),
            style: GoogleFonts.ibmPlexSans(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
    ],
  );
}

class _CartSummary extends StatefulWidget {
  const _CartSummary({
    required this.items,
    required this.addresses,
    required this.loadingAddress,
    required this.updatingAddress,
    required this.onAddressSelected,
    required this.onOrderCompleted,
    this.sheetStyle = false,
  });

  final List<UserCartItem> items;
  final List<Map<String, dynamic>> addresses;
  final bool loadingAddress;
  final bool updatingAddress;
  final ValueChanged<String> onAddressSelected;
  final ValueChanged<OrderSuccessDetails> onOrderCompleted;
  final bool sheetStyle;

  @override
  State<_CartSummary> createState() => _CartSummaryState();
}

class _CartSummaryState extends State<_CartSummary> {
  var _paying = false;
  String? _selectedAddressId;

  int get subtotal => widget.items.fold(
    0,
    (total, item) =>
        total + ((_priceNumber(item.product?.price) ?? 0) * item.quantity),
  );

  String? get _storedSelectedAddressId {
    if (widget.addresses.isEmpty) return null;
    return widget.addresses.firstWhere(
          (address) => address['is_selected'] == true,
          orElse: () => widget.addresses.first,
        )['id']
        as String?;
  }

  String? get _effectiveSelectedAddressId =>
      _selectedAddressId ?? _storedSelectedAddressId;

  Map<String, dynamic>? get selectedAddress {
    final id = _effectiveSelectedAddressId;
    if (id == null) return null;
    for (final address in widget.addresses) {
      if (address['id'] == id) return address;
    }
    return null;
  }

  void _selectAddressLocally(String id) =>
      setState(() => _selectedAddressId = id);

  Future<void> _pay() async {
    final address = selectedAddress;
    if (address == null) {
      _showMessage('Add or select a delivery address before ordering.');
      return;
    }
    if (subtotal <= 0 || _paying) return;

    setState(() => _paying = true);
    try {
      if (_selectedAddressId != null &&
          _selectedAddressId != _storedSelectedAddressId) {
        await Supabase.instance.client
            .from('user_addresses')
            .update({'is_selected': true})
            .eq('id', _selectedAddressId!);
      }
      final result = await PaymentService.pay(
        amountPaise: subtotal * 100,
        receipt: 'cart_${DateTime.now().millisecondsSinceEpoch}',
        description: 'Kalasthali cart order',
        customerName: address['receiver_name'] as String?,
        customerEmail: AuthService.currentUser?.email,
        customerContact: address['phone_number'] as String?,
        notes: {
          'source': 'cart',
          'address_id': address['id'],
          'items': widget.items.map((item) => item.code).join(','),
        },
        sale: {
          'product': widget.items.map(_cartItemLine).join('\n'),
          'amount': subtotal,
          'product_code': widget.items.first.code,
          'user_address': _addressLines(address),
          'customer_email': AuthService.currentUser?.email,
          'customer_phone': address['phone_number'],
          'items': widget.items.map(_cartItemJson).toList(),
        },
      );
      if (!mounted) return;
      widget.onOrderCompleted(
        OrderSuccessDetails(
          orderId: result.orderId,
          paymentId: result.paymentId,
          address: _addressLines(address),
          contactTarget:
              (address['phone_number'] as String?) ??
              AuthService.currentUser?.email ??
              'your registered contact',
          items: [
            for (final item in widget.items)
              OrderSuccessItem(
                name: item.product?.name ?? item.productName,
                code: item.code,
                quantity: item.quantity,
                amount:
                    (_priceNumber(item.product?.price) ?? 0) * item.quantity,
              ),
          ],
        ),
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      widget.sheetStyle ? 30 : 24,
      widget.sheetStyle ? 16 : 24,
      widget.sheetStyle ? 30 : 24,
      widget.sheetStyle ? 22 : 24,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFD6BFA6),
      border: widget.sheetStyle
          ? const Border(
              top: BorderSide(color: Color(0xFF5B351A), width: 2),
              left: BorderSide(color: Color(0xFF5B351A), width: 2),
              right: BorderSide(color: Color(0xFF5B351A), width: 2),
            )
          : Border.all(color: const Color(0xFF5B351A), width: 2),
      borderRadius: widget.sheetStyle
          ? const BorderRadius.vertical(top: Radius.circular(32))
          : BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.sheetStyle)
          Center(
            child: Container(
              width: 46,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF8C684D),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtotal',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: widget.sheetStyle ? 36 : 34,
                color: const Color(0xFF5B351A),
              ),
            ),
            Text(
              _money(subtotal),
              style: GoogleFonts.ibmPlexSans(
                fontSize: widget.sheetStyle ? 38 : 30,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        Text(
          '(Inclusive of all taxes)',
          style: GoogleFonts.ibmPlexSans(
            fontSize: widget.sheetStyle ? 13 : 12,
            color: Colors.black,
          ),
        ),
        SizedBox(height: widget.sheetStyle ? 12 : 10),
        widget.updatingAddress
            ? const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFFA35710),
                backgroundColor: Color(0xFFB79B80),
              )
            : Divider(
                color: const Color(0xFF8C684D),
                thickness: widget.sheetStyle ? 2 : 1,
              ),
        SizedBox(height: widget.sheetStyle ? 24 : 20),
        Text(
          'Deliver to',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: widget.sheetStyle ? 34 : 28,
            color: const Color(0xFF5B351A),
          ),
        ),
        SizedBox(height: widget.sheetStyle ? 16 : 8),
        if (widget.loadingAddress)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          _AddressSelector(
            addresses: widget.addresses,
            updating: widget.updatingAddress,
            selectedId: _effectiveSelectedAddressId,
            onSelected: _selectAddressLocally,
            sheetStyle: widget.sheetStyle,
          ),
        if (widget.sheetStyle && selectedAddress != null) ...[
          const SizedBox(height: 24),
          _SummaryContact(address: selectedAddress!),
        ],
        SizedBox(height: widget.sheetStyle ? 30 : 28),
        Center(
          child: SizedBox(
            width: widget.sheetStyle ? double.infinity : 240,
            height: widget.sheetStyle ? 64 : 56,
            child: FilledButton(
              onPressed: _paying || widget.updatingAddress ? null : _pay,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA35710),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _paying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Order Now',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: widget.sheetStyle ? 24 : 24,
                      ),
                    ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SummaryContact extends StatelessWidget {
  const _SummaryContact({required this.address});

  final Map<String, dynamic> address;

  @override
  Widget build(BuildContext context) {
    final name = (address['receiver_name'] ?? '').toString().trim();
    final phone = (address['phone_number'] ?? '').toString().trim();
    if (name.isEmpty && phone.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 34,
            color: const Color(0xFF5B351A),
          ),
        ),
        const SizedBox(height: 6),
        if (name.isNotEmpty)
          Text(
            name,
            style: GoogleFonts.ibmPlexSans(fontSize: 18, height: 1.08),
          ),
        if (phone.isNotEmpty)
          Text(
            phone,
            style: GoogleFonts.ibmPlexSans(fontSize: 18, height: 1.08),
          ),
      ],
    );
  }
}

class _AddressSelector extends StatelessWidget {
  const _AddressSelector({
    required this.addresses,
    required this.updating,
    required this.selectedId,
    required this.onSelected,
    this.sheetStyle = false,
  });

  final List<Map<String, dynamic>> addresses;
  final bool updating;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final bool sheetStyle;

  @override
  Widget build(BuildContext context) {
    if (addresses.isEmpty) {
      return Text(
        'No saved addresses yet.',
        style: GoogleFonts.ibmPlexSans(fontSize: 14, color: Colors.black),
      );
    }
    final effectiveSelectedId =
        selectedId ??
        addresses.firstWhere(
              (address) => address['is_selected'] == true,
              orElse: () => addresses.first,
            )['id']
            as String?;
    return Column(
      children: [
        for (final address in addresses)
          _AddressRadioTile(
            address: address,
            selectedId: effectiveSelectedId,
            enabled: !updating,
            onSelected: onSelected,
            sheetStyle: sheetStyle,
          ),
      ],
    );
  }
}

class _AddressRadioTile extends StatelessWidget {
  const _AddressRadioTile({
    required this.address,
    required this.selectedId,
    required this.enabled,
    required this.onSelected,
    this.sheetStyle = false,
  });

  final Map<String, dynamic> address;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String> onSelected;
  final bool sheetStyle;

  @override
  Widget build(BuildContext context) {
    final id = address['id'] as String?;
    final selected = id != null && id == selectedId;
    final lines = [
      address['receiver_name'],
      address['address_line1'],
      address['address_line2'],
      [
        address['city'],
        address['state_pincode'],
      ].whereType<String>().where((line) => line.trim().isNotEmpty).join(', '),
      address['country'] ?? 'India',
      address['phone_number'],
    ].whereType<String>().where((line) => line.trim().isNotEmpty).join('\n');

    return Padding(
      padding: EdgeInsets.only(bottom: sheetStyle ? 16 : 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(sheetStyle ? 16 : 10),
        onTap: !enabled || id == null ? null : () => onSelected(id),
        child: Container(
          constraints: sheetStyle ? const BoxConstraints(minHeight: 132) : null,
          padding: EdgeInsets.fromLTRB(
            sheetStyle ? 18 : 8,
            sheetStyle ? 18 : 10,
            sheetStyle ? 18 : 12,
            sheetStyle ? 18 : 10,
          ),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE7D0AE) : const Color(0xFFE2D2C0),
            border: Border.all(
              color: selected
                  ? const Color(0xFFA35710)
                  : const Color(0xFF8C684D),
              width: selected ? 1.7 : 1,
            ),
            borderRadius: BorderRadius.circular(sheetStyle ? 16 : 10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? const Color(0xFFA35710)
                    : const Color(0xFF1F1E25),
                size: sheetStyle ? 34 : 25,
              ),
              SizedBox(width: sheetStyle ? 16 : 10),
              Expanded(
                child: Text(
                  lines,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: sheetStyle ? 18 : 13,
                    height: sheetStyle ? 1.08 : 1.05,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'Your cart is empty.',
      style: GoogleFonts.dmSerifDisplay(
        fontSize: 38,
        color: const Color(0xFF5B351A),
      ),
    ),
  );
}

int? _priceNumber(String? price) {
  if (price == null) return null;
  return int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), ''));
}

String _money(int? value) => value == null ? '-' : '₹$value';

String _cartItemLine(UserCartItem item) {
  final price = _priceNumber(item.product?.price) ?? 0;
  final total = price * item.quantity;
  return '${item.product?.name ?? item.productName} (${item.code}) x ${item.quantity} - ₹$total';
}

Map<String, Object?> _cartItemJson(UserCartItem item) {
  final price = _priceNumber(item.product?.price) ?? 0;
  return {
    'product_name': item.product?.name ?? item.productName,
    'product_code': item.code,
    'product_type': item.product?.type,
    'size': item.size,
    'quantity': item.quantity,
    'unit_price': price,
    'line_total': price * item.quantity,
  };
}

String _addressLines(Map<String, dynamic> address) {
  final cityState = [
    address['city'],
    address['state_pincode'],
  ].whereType<String>().where((line) => line.trim().isNotEmpty).join(', ');
  return [
    address['receiver_name'],
    address['address_line1'],
    address['address_line2'],
    cityState,
    address['country'] ?? 'India',
    address['phone_number'],
  ].whereType<String>().where((line) => line.trim().isNotEmpty).join('\n');
}
