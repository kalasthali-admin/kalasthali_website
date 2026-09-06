import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models/order_success_details.dart';
import '../core/models/product.dart';
import '../core/responsive.dart';
import '../core/services/auth_service.dart';
import '../core/services/payment_service.dart';
import '../core/services/product_service.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_scaffold.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({this.productCode = '', super.key});

  final String productCode;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late Future<Product?> _product;
  Future<List<Map<String, dynamic>>>? _addresses;
  String? _addressesUserId;
  var _addressUpdating = false;

  @override
  void initState() {
    super.initState();
    _product = ProductService().getProductByCode(widget.productCode);
  }

  Future<List<Map<String, dynamic>>> _loadAddresses(String userId) async =>
      (await Supabase.instance.client
                  .from('user_addresses')
                  .select()
                  .eq('user_id', userId)
                  .order('created_at')
              as List)
          .cast<Map<String, dynamic>>();

  Future<List<Map<String, dynamic>>>? _addressesFor(User? user) {
    if (user == null) return null;
    if (_addressesUserId != user.id || _addresses == null) {
      _addressesUserId = user.id;
      _addresses = _loadAddresses(user.id);
    }
    return _addresses;
  }

  Future<void> _selectAddress(String id) async {
    setState(() => _addressUpdating = true);
    try {
      await Supabase.instance.client
          .from('user_addresses')
          .update({'is_selected': true})
          .eq('id', id);
      if (!mounted || _addressesUserId == null) return;
      setState(() {
        _addresses = _loadAddresses(_addressesUserId!);
      });
    } finally {
      if (mounted) setState(() => _addressUpdating = false);
    }
  }

  void _goToAccountAddresses() {
    Navigator.pushNamed(context, '/account');
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Checkout',
    currentRoute: '/checkout',
    centerBody: false,
    body: FutureBuilder<Product?>(
      future: _product,
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final product = productSnapshot.data;
        if (product == null) {
          return const Center(
            child: Text('This product is no longer available.'),
          );
        }
        return StreamBuilder<User?>(
          stream: AuthService.userChanges,
          initialData: AuthService.currentUser,
          builder: (context, userSnapshot) {
            final user = userSnapshot.data ?? AuthService.currentUser;
            return LayoutBuilder(
              builder: (context, constraints) {
                final mobile = useCompactLayout(context, breakpoint: 800);
                return SingleChildScrollView(
                  primary: true,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          mobile ? 22 : 54,
                          mobile ? 62 : 88,
                          mobile ? 22 : 54,
                          mobile ? 76 : 110,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1160),
                            child: _CheckoutContent(
                              product: product,
                              user: user,
                              addresses: _addressesFor(user),
                              addressUpdating: _addressUpdating,
                              mobile: mobile,
                              onAddressSelected: _selectAddress,
                              onAddAddress: _goToAccountAddresses,
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
        );
      },
    ),
  );
}

class _CheckoutContent extends StatelessWidget {
  const _CheckoutContent({
    required this.product,
    required this.user,
    required this.addresses,
    required this.addressUpdating,
    required this.mobile,
    required this.onAddressSelected,
    required this.onAddAddress,
  });

  final Product product;
  final User? user;
  final Future<List<Map<String, dynamic>>>? addresses;
  final bool addressUpdating;
  final bool mobile;
  final ValueChanged<String> onAddressSelected;
  final VoidCallback onAddAddress;

  @override
  Widget build(BuildContext context) {
    final order = _OrderSummary(product: product);
    final detailPanel = user == null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SignInForCheckout(),
              const SizedBox(height: 20),
              _PaymentPanel(
                product: product,
                address: null,
                canContinue: false,
              ),
            ],
          )
        : FutureBuilder<List<Map<String, dynamic>>>(
            future: addresses,
            builder: (context, snapshot) {
              final addressList = snapshot.data ?? const [];
              final selectedAddress = _selectedAddress(addressList);
              final deliveryAddressReady = selectedAddress != null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DeliveryPanel(
                    addresses: addressList,
                    loading: snapshot.connectionState != ConnectionState.done,
                    updating: addressUpdating,
                    onAddressSelected: onAddressSelected,
                    onAddAddress: onAddAddress,
                  ),
                  const SizedBox(height: 20),
                  _PaymentPanel(
                    product: product,
                    address: selectedAddress,
                    canContinue: deliveryAddressReady,
                  ),
                ],
              );
            },
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Checkout',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: mobile ? 38 : 52,
            color: const Color(0xFF5B351A),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Review your selection before payment.',
          style: GoogleFonts.blinker(fontSize: mobile ? 17 : 19),
        ),
        const SizedBox(height: 30),
        if (mobile)
          Column(children: [order, const SizedBox(height: 22), detailPanel])
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: order),
              const SizedBox(width: 30),
              Expanded(flex: 5, child: detailPanel),
            ],
          ),
      ],
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.product});
  final Product product;

  String get _price => product.price?.startsWith('₹') == true
      ? product.price!
      : '₹${product.price ?? '-'}';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _panelDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your item',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 30,
            color: const Color(0xFF5B351A),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              height: 116,
              child: FutureBuilder<String>(
                future: ProductService().getProductImageUrlAsync(product.code),
                builder: (_, snapshot) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: !snapshot.hasData
                      ? const ColoredBox(color: Color(0xFFD8D0C3))
                      : Image.network(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.type,
                    style: GoogleFonts.blinker(
                      fontSize: 15,
                      color: const Color(0xFF746D64),
                    ),
                  ),
                  Text(
                    product.name,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 26,
                      color: const Color(0xFF5B351A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Code: ${product.code}',
                    style: GoogleFonts.blinker(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFD5B48A)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtotal',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 27,
                color: const Color(0xFF5B351A),
              ),
            ),
            Text(
              _price,
              style: GoogleFonts.blinker(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SignInForCheckout extends StatelessWidget {
  const _SignInForCheckout();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: _panelDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery information',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 30,
            color: const Color(0xFF5B351A),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Log in to save your delivery details and continue to payment.',
          style: GoogleFonts.blinker(fontSize: 18, height: 1.3),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => Navigator.pushNamed(context, '/account'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFA35710),
          ),
          child: const Text('Log in or sign up'),
        ),
      ],
    ),
  );
}

class _DeliveryPanel extends StatelessWidget {
  const _DeliveryPanel({
    required this.addresses,
    required this.loading,
    required this.updating,
    required this.onAddressSelected,
    required this.onAddAddress,
  });

  final List<Map<String, dynamic>> addresses;
  final bool loading;
  final bool updating;
  final ValueChanged<String> onAddressSelected;
  final VoidCallback onAddAddress;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: _panelDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery information',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 30,
            color: const Color(0xFF5B351A),
          ),
        ),
        const SizedBox(height: 12),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else if (addresses.isNotEmpty) ...[
          if (updating)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFFA35710),
              backgroundColor: Color(0xFFE2D2C0),
            ),
          if (updating) const SizedBox(height: 12),
          for (final address in addresses)
            _CheckoutAddressTile(
              address: address,
              selectedAddress: _selectedAddress(addresses),
              enabled: !updating,
              onSelected: onAddressSelected,
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddAddress,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Manage saved addresses'),
            ),
          ),
        ] else
          OutlinedButton.icon(
            onPressed: onAddAddress,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Set delivery address'),
          ),
      ],
    ),
  );
}

class _CheckoutAddressTile extends StatelessWidget {
  const _CheckoutAddressTile({
    required this.address,
    required this.selectedAddress,
    required this.enabled,
    required this.onSelected,
  });

  final Map<String, dynamic> address;
  final Map<String, dynamic>? selectedAddress;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final id = address['id'] as String?;
    final selected = id != null && id == selectedAddress?['id'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: !enabled || id == null ? null : () => onSelected(id),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 11, 14, 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE7D0AE) : const Color(0xFFE2D2C0),
            border: Border.all(
              color: selected
                  ? const Color(0xFFA35710)
                  : const Color(0xFF8C684D),
              width: selected ? 1.7 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
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
                  _addressLines(address),
                  style: GoogleFonts.blinker(
                    fontSize: 14,
                    height: 1.08,
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

class _PaymentPanel extends StatefulWidget {
  const _PaymentPanel({
    required this.product,
    required this.address,
    required this.canContinue,
  });

  final Product product;
  final Map<String, dynamic>? address;
  final bool canContinue;

  @override
  State<_PaymentPanel> createState() => _PaymentPanelState();
}

class _PaymentPanelState extends State<_PaymentPanel> {
  var _paying = false;

  Future<void> _pay() async {
    final amount = _priceNumber(widget.product.price);
    if (amount == null || amount <= 0) {
      _showMessage('This product does not have a valid price yet.');
      return;
    }
    if (!widget.canContinue || _paying) return;

    setState(() => _paying = true);
    try {
      final result = await PaymentService.pay(
        amountPaise: amount * 100,
        receipt:
            '${widget.product.code}_${DateTime.now().millisecondsSinceEpoch}',
        description: widget.product.name,
        customerName: widget.address?['receiver_name'] as String?,
        customerEmail: AuthService.currentUser?.email,
        customerContact: widget.address?['phone_number'] as String?,
        notes: {
          'source': 'buy_now',
          'product_code': widget.product.code,
          'product_name': widget.product.name,
          'address_id': widget.address?['id'],
        },
        sale: {
          'product': widget.product.name,
          'amount': amount,
          'product_code': widget.product.code,
          'user_address': _addressLines(widget.address!),
          'customer_email': AuthService.currentUser?.email,
          'customer_phone': widget.address?['phone_number'],
          'items': [
            {
              'product_name': widget.product.name,
              'product_code': widget.product.code,
              'product_type': widget.product.type,
              'quantity': 1,
              'unit_price': amount,
              'line_total': amount,
            },
          ],
        },
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/order-success',
        arguments: OrderSuccessDetails(
          orderId: result.orderId,
          paymentId: result.paymentId,
          address: _addressLines(widget.address!),
          contactTarget:
              (widget.address?['phone_number'] as String?) ??
              AuthService.currentUser?.email ??
              'your registered contact',
          items: [
            OrderSuccessItem(
              name: widget.product.name,
              code: widget.product.code,
              quantity: 1,
              amount: amount,
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
    padding: const EdgeInsets.all(22),
    decoration: _panelDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 30,
            color: const Color(0xFF5B351A),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Pay securely with Razorpay Standard Checkout.',
          style: GoogleFonts.blinker(fontSize: 18, height: 1.3),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: !widget.canContinue || _paying ? null : _pay,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA35710),
            ),
            child: _paying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Continue to payment'),
          ),
        ),
      ],
    ),
  );
}

BoxDecoration _panelDecoration() => BoxDecoration(
  color: const Color(0xFFFEF5E6),
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: const Color(0xFFD5B48A), width: 1.5),
  boxShadow: const [
    BoxShadow(color: Color(0x1F2D1E12), blurRadius: 14, offset: Offset(0, 6)),
  ],
);

int? _priceNumber(String? price) {
  if (price == null) return null;
  return int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), ''));
}

Map<String, dynamic>? _selectedAddress(List<Map<String, dynamic>> addresses) {
  if (addresses.isEmpty) return null;
  return addresses.firstWhere(
    (address) => address['is_selected'] == true,
    orElse: () => addresses.first,
  );
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
