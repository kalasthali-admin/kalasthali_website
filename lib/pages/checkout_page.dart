import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/product.dart';
import '../core/models/user_account.dart';
import '../core/services/auth_service.dart';
import '../core/services/product_service.dart';
import '../core/services/user_account_service.dart';
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
  Future<UserAccount?>? _account;

  @override
  void initState() {
    super.initState();
    _product = ProductService().getProductByCode(widget.productCode);
    final user = AuthService.currentUser;
    if (user != null) _account = UserAccountService.instance.get(user.id);
  }

  Future<void> _setDeliveryAddress(UserAccount? account) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final updated = await showDialog<UserAccount>(
      context: context,
      builder: (_) => _DeliveryAddressDialog(account: account, userId: user.id),
    );
    if (updated != null && mounted)
      setState(() => _account = Future.value(updated));
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
        final user = AuthService.currentUser;
        return LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 800;
            return SingleChildScrollView(
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
                          userId: user?.id,
                          account: _account,
                          mobile: mobile,
                          onSetDeliveryAddress: _setDeliveryAddress,
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

class _CheckoutContent extends StatelessWidget {
  const _CheckoutContent({
    required this.product,
    required this.userId,
    required this.account,
    required this.mobile,
    required this.onSetDeliveryAddress,
  });

  final Product product;
  final String? userId;
  final Future<UserAccount?>? account;
  final bool mobile;
  final ValueChanged<UserAccount?> onSetDeliveryAddress;

  @override
  Widget build(BuildContext context) {
    final order = _OrderSummary(product: product);
    final detailPanel = userId == null
        ? const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SignInForCheckout(),
              SizedBox(height: 20),
              _PaymentPanel(canContinue: false),
            ],
          )
        : FutureBuilder<UserAccount?>(
            future: account,
            builder: (context, snapshot) {
              final deliveryAddressReady =
                  snapshot.data?.hasDeliveryAddress == true;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DeliveryPanel(
                    account: snapshot.data,
                    loading: snapshot.connectionState != ConnectionState.done,
                    onSetAddress: () => onSetDeliveryAddress(snapshot.data),
                  ),
                  const SizedBox(height: 20),
                  _PaymentPanel(canContinue: deliveryAddressReady),
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
    required this.account,
    required this.loading,
    required this.onSetAddress,
  });
  final UserAccount? account;
  final bool loading;
  final VoidCallback onSetAddress;

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
        else if (account?.hasDeliveryAddress == true) ...[
          Text(
            account!.receiverName!,
            style: GoogleFonts.blinker(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            account!.addressLine1!,
            style: GoogleFonts.blinker(fontSize: 18),
          ),
          if (account!.addressLine2?.isNotEmpty == true)
            Text(
              account!.addressLine2!,
              style: GoogleFonts.blinker(fontSize: 18),
            ),
          Text(
            account!.statePincode!,
            style: GoogleFonts.blinker(fontSize: 18),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onSetAddress,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit delivery address'),
          ),
        ] else
          OutlinedButton.icon(
            onPressed: onSetAddress,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Set delivery address'),
          ),
      ],
    ),
  );
}

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({required this.canContinue});
  final bool canContinue;

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
          'Secure Razorpay payment will be available here shortly.',
          style: GoogleFonts.blinker(fontSize: 18, height: 1.3),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: !canContinue
                ? null
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment setup is coming soon.'),
                    ),
                  ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA35710),
            ),
            child: const Text('Continue to payment'),
          ),
        ),
      ],
    ),
  );
}

class _DeliveryAddressDialog extends StatefulWidget {
  const _DeliveryAddressDialog({required this.account, required this.userId});
  final UserAccount? account;
  final String userId;

  @override
  State<_DeliveryAddressDialog> createState() => _DeliveryAddressDialogState();
}

class _DeliveryAddressDialogState extends State<_DeliveryAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _statePincode;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.account?.receiverName ?? '');
    _line1 = TextEditingController(text: widget.account?.addressLine1 ?? '');
    _line2 = TextEditingController(text: widget.account?.addressLine2 ?? '');
    _statePincode = TextEditingController(
      text: widget.account?.statePincode ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _line1.dispose();
    _line2.dispose();
    _statePincode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final account = await UserAccountService.instance.saveDeliveryAddress(
        userId: widget.userId,
        receiverName: _name.text,
        addressLine1: _line1.text,
        addressLine2: _line2.text,
        statePincode: _statePincode.text,
      );
      if (mounted) Navigator.pop(context, account);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the delivery address.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      'Delivery address',
      style: GoogleFonts.dmSerifDisplay(
        fontSize: 32,
        color: const Color(0xFF5B351A),
      ),
    ),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AddressField(
                controller: _name,
                label: 'Receiver name',
                required: true,
              ),
              _AddressField(
                controller: _line1,
                label: 'Address line 1',
                required: true,
              ),
              _AddressField(controller: _line2, label: 'Address line 2'),
              _AddressField(
                controller: _statePincode,
                label: 'State with pincode',
                required: true,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Save address'),
      ),
    ],
  );
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    this.required = false,
  });
  final TextEditingController controller;
  final String label;
  final bool required;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? '$label is required.'
                : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
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
