import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/responsive.dart';
import '../core/services/cart_service.dart';
import '../core/services/payment_service.dart';
import '../core/services/product_service.dart';
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
    await CartService.instance.setQuantity(code, quantity);
    if (mounted) setState(_reload);
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

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Cart',
    currentRoute: '/cart',
    centerBody: false,
    body: FutureBuilder<List<UserCartItem>>(
      future: _items,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final items = snapshot.data ?? const <UserCartItem>[];
        return LayoutBuilder(
          builder: (context, constraints) {
            final mobile = useCompactLayout(context, breakpoint: 900);
            return Column(
              children: [
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : items.isEmpty
                      ? _EmptyCart()
                      : SingleChildScrollView(
                          primary: true,
                          padding: EdgeInsets.fromLTRB(
                            mobile ? 22 : 32,
                            mobile ? 58 : 72,
                            mobile ? 22 : 32,
                            mobile ? 78 : 96,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1180),
                              child: _CartContent(
                                items: items,
                                addresses: _addresses,
                                loadingAddresses: _addressesLoading,
                                updatingAddress: _addressUpdating,
                                mobile: mobile,
                                onQuantityChanged: _setQuantity,
                                onAddressSelected: _selectAddress,
                              ),
                            ),
                          ),
                        ),
                ),
                const AppFooter(),
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
    required this.mobile,
    required this.onQuantityChanged,
    required this.onAddressSelected,
  });

  final List<UserCartItem> items;
  final List<Map<String, dynamic>> addresses;
  final bool loadingAddresses;
  final bool updatingAddress;
  final bool mobile;
  final void Function(String code, int quantity) onQuantityChanged;
  final ValueChanged<String> onAddressSelected;

  @override
  Widget build(BuildContext context) {
    final summary = _CartSummary(
      items: items,
      addresses: addresses,
      loadingAddress: loadingAddresses,
      updatingAddress: updatingAddress,
      onAddressSelected: onAddressSelected,
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
        const SizedBox(height: 24),
        if (mobile)
          Column(children: [list, const SizedBox(height: 24), summary])
        else
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
    final sizes = (product?.sizes ?? item.size ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFECE7DD),
        border: Border.all(color: const Color(0xFFD5B48A), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2D1E12),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CartItemLead(item: item),
                const SizedBox(height: 18),
                _CartItemMetrics(
                  item: item,
                  price: price,
                  total: total,
                  onQuantityChanged: onQuantityChanged,
                ),
                if (sizes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _SizeChips(sizes: sizes),
                ],
              ],
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
                style: GoogleFonts.blinker(
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
                  style: GoogleFonts.blinker(
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
        style: GoogleFonts.blinker(
          fontSize: 15,
          color: const Color(0xFF746D64),
        ),
      ),
      const SizedBox(height: 4),
      valueWidget ??
          Text(
            value ?? '-',
            style: GoogleFonts.blinker(
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
            style: GoogleFonts.blinker(fontWeight: FontWeight.w800),
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
  const _SizeChips({required this.sizes});

  final List<String> sizes;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    children: [
      for (final size in sizes.take(4))
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: size == sizes.first
                ? const Color(0xFFC38A55)
                : const Color(0xFFD8C5AD),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            size.toUpperCase(),
            style: GoogleFonts.blinker(
              fontSize: 11,
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
  });

  final List<UserCartItem> items;
  final List<Map<String, dynamic>> addresses;
  final bool loadingAddress;
  final bool updatingAddress;
  final ValueChanged<String> onAddressSelected;

  @override
  State<_CartSummary> createState() => _CartSummaryState();
}

class _CartSummaryState extends State<_CartSummary> {
  var _paying = false;

  int get subtotal => widget.items.fold(
    0,
    (total, item) =>
        total + ((_priceNumber(item.product?.price) ?? 0) * item.quantity),
  );

  Map<String, dynamic>? get selectedAddress {
    if (widget.addresses.isEmpty) return null;
    return widget.addresses.firstWhere(
      (address) => address['is_selected'] == true,
      orElse: () => widget.addresses.first,
    );
  }

  Future<void> _pay() async {
    final address = selectedAddress;
    if (address == null) {
      _showMessage('Add or select a delivery address before ordering.');
      return;
    }
    if (subtotal <= 0 || _paying) return;

    setState(() => _paying = true);
    try {
      final result = await PaymentService.pay(
        amountPaise: subtotal * 100,
        receipt: 'cart_${DateTime.now().millisecondsSinceEpoch}',
        description: 'Kalasthali cart order',
        customerName: address['receiver_name'] as String?,
        customerContact: address['phone_number'] as String?,
        notes: {
          'source': 'cart',
          'address_id': address['id'],
          'items': widget.items.map((item) => item.code).join(','),
        },
      );
      _showMessage('Payment verified: ${result.paymentId}');
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
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFFD6BFA6),
      border: Border.all(color: const Color(0xFF5B351A), width: 2),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtotal',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 34,
                color: const Color(0xFF5B351A),
              ),
            ),
            Text(
              _money(subtotal),
              style: GoogleFonts.blinker(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        Text(
          '(Inclusive of all taxes)',
          style: GoogleFonts.blinker(fontSize: 12, color: Colors.black),
        ),
        const SizedBox(height: 10),
        widget.updatingAddress
            ? const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFFA35710),
                backgroundColor: Color(0xFFB79B80),
              )
            : const Divider(color: Color(0xFF8C684D)),
        const SizedBox(height: 20),
        Text(
          'Deliver to',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 28,
            color: const Color(0xFF5B351A),
          ),
        ),
        const SizedBox(height: 8),
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
            onSelected: widget.onAddressSelected,
          ),
        const SizedBox(height: 28),
        Center(
          child: SizedBox(
            width: 240,
            height: 56,
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
                  : Text('Order Now', style: GoogleFonts.blinker(fontSize: 24)),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AddressSelector extends StatelessWidget {
  const _AddressSelector({
    required this.addresses,
    required this.updating,
    required this.onSelected,
  });

  final List<Map<String, dynamic>> addresses;
  final bool updating;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (addresses.isEmpty) {
      return Text(
        'No saved addresses yet.',
        style: GoogleFonts.blinker(fontSize: 14, color: Colors.black),
      );
    }
    final selected = addresses.firstWhere(
      (address) => address['is_selected'] == true,
      orElse: () => addresses.first,
    );
    final selectedId = selected['id'] as String?;
    return Column(
      children: [
        for (final address in addresses)
          _AddressRadioTile(
            address: address,
            selectedId: selectedId,
            enabled: !updating,
            onSelected: onSelected,
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
  });

  final Map<String, dynamic> address;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String> onSelected;

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
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: !enabled || id == null ? null : () => onSelected(id),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE7D0AE) : const Color(0xFFE2D2C0),
            border: Border.all(
              color: selected
                  ? const Color(0xFFA35710)
                  : const Color(0xFF8C684D),
              width: selected ? 1.7 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
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
                size: 25,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lines,
                  style: GoogleFonts.blinker(
                    fontSize: 13,
                    height: 1.05,
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
