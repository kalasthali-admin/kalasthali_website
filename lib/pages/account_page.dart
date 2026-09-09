import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/responsive.dart';
import '../core/services/auth_service.dart';
import '../core/services/product_service.dart';
import '../core/services/seo_service.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_scaffold.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    SeoService.setPage(
      title: 'Account | Kalasthali By Nisha',
      description: 'Sign in to your account.',
      path: '/account',
    );
    return AppScaffold(
      title: 'Account',
      currentRoute: '/account',
      centerBody: false,
      body: StreamBuilder<User?>(
        stream: AuthService.userChanges,
        initialData: AuthService.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data ?? AuthService.currentUser;
          return LayoutBuilder(
            builder: (context, constraints) {
              final mobile = useCompactLayout(context, breakpoint: 700);
              return CustomScrollView(
                primary: true,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        mobile ? 22 : 54,
                        mobile ? 70 : 104,
                        mobile ? 22 : 54,
                        mobile ? 88 : 200,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: user == null ? 560 : 1100,
                          ),
                          child: user == null
                              ? const _AccountAuthForm()
                              : _AccountDetails(user: user),
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
}

class _AccountAuthForm extends StatefulWidget {
  const _AccountAuthForm();

  @override
  State<_AccountAuthForm> createState() => _AccountAuthFormState();
}

class _AccountAuthFormState extends State<_AccountAuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _signUp = false;
  var _loading = false;
  String? _message;

  @override
  void dispose() {
    _firstName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      if (_signUp) {
        final response = await Supabase.instance.client.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'first_name': _firstName.text.trim()},
        );
        if (!mounted) return;
        if (response.session == null) {
          setState(() {
            _message = 'Check your email to confirm your account, then log in.';
          });
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF5E6),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFD5B48A), width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x222D1E12),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _signUp ? 'Create your account' : 'Welcome back',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 38,
              color: const Color(0xFF5B351A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _signUp
                ? 'Save your details now for a smoother checkout later.'
                : 'Log in to access your account.',
            style: GoogleFonts.blinker(fontSize: 18, height: 1.3),
          ),
          const SizedBox(height: 26),
          if (_signUp) ...[
            _AuthField(
              controller: _firstName,
              label: 'First name',
              textCapitalization: TextCapitalization.words,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your first name.'
                  : null,
            ),
            const SizedBox(height: 16),
          ],
          _AuthField(
            controller: _email,
            label: 'Email address',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final email = value?.trim() ?? '';
              return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
                  ? null
                  : 'Enter a valid email address.';
            },
          ),
          const SizedBox(height: 16),
          _AuthField(
            controller: _password,
            label: 'Password',
            obscureText: true,
            validator: (value) =>
                (value?.length ?? 0) < 6 ? 'Use at least 6 characters.' : null,
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(
              _message!,
              style: GoogleFonts.blinker(
                fontSize: 16,
                color: const Color(0xFF914B0D),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA35710),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _signUp ? 'Create account' : 'Log in',
                      style: GoogleFonts.blinker(fontSize: 19),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _loading
                  ? null
                  : () => setState(() {
                      _signUp = !_signUp;
                      _message = null;
                    }),
              child: Text(
                _signUp
                    ? 'Already have an account? Log in'
                    : 'New to Kalasthali? Create an account',
                style: GoogleFonts.blinker(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    obscureText: obscureText,
    textCapitalization: textCapitalization,
    style: GoogleFonts.blinker(fontSize: 18),
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );
}

class _AccountDetails extends StatefulWidget {
  const _AccountDetails({required this.user});
  final User user;

  @override
  State<_AccountDetails> createState() => _AccountDetailsState();
}

class _AccountDetailsState extends State<_AccountDetails> {
  late Future<List<Map<String, dynamic>>> _addresses;
  late Future<List<Map<String, dynamic>>> _orders;

  @override
  void initState() {
    super.initState();
    _addresses = _loadAddresses();
    _orders = _loadOrders();
  }

  Future<List<Map<String, dynamic>>> _loadAddresses() async =>
      (await Supabase.instance.client
                  .from('user_addresses')
                  .select()
                  .eq('user_id', widget.user.id)
                  .order('created_at')
              as List)
          .cast<Map<String, dynamic>>();

  Future<List<Map<String, dynamic>>> _loadOrders() async =>
      (await Supabase.instance.client
                  .from('sales')
                  .select()
                  .eq('user', widget.user.id)
                  .order('paid_at', ascending: false)
              as List)
          .cast<Map<String, dynamic>>();

  void _refresh() {
    setState(() {
      _addresses = _loadAddresses();
      _orders = _loadOrders();
    });
  }

  Future<void> _select(String id) async {
    await Supabase.instance.client
        .from('user_addresses')
        .update({'is_selected': true})
        .eq('id', id);
    _refresh();
  }

  Future<void> _showAddressSheet([Map<String, dynamic>? address]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _AddressEditorSheet(userId: widget.user.id, address: address),
    );
    if (saved == true) _refresh();
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFEF5E6),
        title: Text(
          'Delete address?',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 30,
            color: const Color(0xFF5B351A),
          ),
        ),
        content: Text(
          'This saved address will be removed from your account.',
          style: GoogleFonts.blinker(fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA35710),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Supabase.instance.client.from('user_addresses').delete().eq('id', id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Hello, ${AuthService.firstName(widget.user)}',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 40,
                color: const Color(0xFF5B351A),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => Supabase.instance.client.auth.signOut(),
            child: const Text('LOG OUT'),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const Divider(color: Color(0xFF9A8267), thickness: 1),
      const SizedBox(height: 26),
      _ProfileInfoGrid(
        email: widget.user.email ?? 'No email address',
        phone: 'Not added',
      ),
      const SizedBox(height: 38),
      Row(
        children: [
          Expanded(
            child: Text(
              'SAVED ADDRESSES',
              style: GoogleFonts.blinker(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          _AddressActionButton(
            label: 'ADD ADDRESS',
            icon: Icons.add,
            onPressed: () => _showAddressSheet(),
          ),
        ],
      ),
      const SizedBox(height: 14),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _addresses,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          if (snapshot.data!.isEmpty) {
            return Text(
              'No saved addresses yet.',
              style: GoogleFonts.blinker(fontSize: 17),
            );
          }
          return Column(
            children: snapshot.data!
                .map(
                  (address) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _AddressCard(
                      address: address,
                      onSelect: _select,
                      onEdit: _showAddressSheet,
                      onDelete: _delete,
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
      const SizedBox(height: 34),
      Text(
        'ORDERS',
        style: GoogleFonts.blinker(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      const SizedBox(height: 14),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              'Could not load your orders. Please refresh and try again.',
              style: GoogleFonts.blinker(fontSize: 17),
            );
          }
          if (!snapshot.hasData) return const CircularProgressIndicator();
          if (snapshot.data!.isEmpty) {
            return Text(
              'No orders placed yet.',
              style: GoogleFonts.blinker(fontSize: 17),
            );
          }
          return Column(
            children: [
              for (final order in snapshot.data!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _OrderCard(order: order),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _ProfileValue extends StatelessWidget {
  const _ProfileValue({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.blinker(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.blinker(fontSize: 19)),
    ],
  );
}

class _ProfileInfoGrid extends StatelessWidget {
  const _ProfileInfoGrid({required this.email, required this.phone});

  final String email;
  final String phone;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 620) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileValue(label: 'EMAIL', value: email),
            const SizedBox(height: 22),
            _ProfileValue(label: 'PHONE NUMBER', value: phone),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _ProfileValue(label: 'EMAIL', value: email),
          ),
          Expanded(
            child: _ProfileValue(label: 'PHONE NUMBER', value: phone),
          ),
        ],
      );
    },
  );
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });
  final Map<String, dynamic> address;
  final ValueChanged<String> onSelect, onDelete;
  final ValueChanged<Map<String, dynamic>> onEdit;

  @override
  Widget build(BuildContext context) {
    final selected = address['is_selected'] == true;
    final id = address['id'] as String;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFECE7DD),
          border: Border.all(color: const Color(0xFFD5B48A)),
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
            final stackActions = constraints.maxWidth < 520;
            final details = _AddressDetails(address: address);
            final actions = _AddressCardActions(
              selected: selected,
              onSelect: () => onSelect(id),
              onEdit: () => onEdit(address),
              onDelete: () => onDelete(id),
            );
            if (stackActions) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [details, const SizedBox(height: 16), actions],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: details),
                const SizedBox(width: 22),
                SizedBox(width: 260, child: actions),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AddressDetails extends StatelessWidget {
  const _AddressDetails({required this.address});

  final Map<String, dynamic> address;

  @override
  Widget build(BuildContext context) {
    final line2 = (address['address_line2'] ?? '').toString().trim();
    final city = (address['city'] ?? '').toString().trim();
    final statePincode = (address['state_pincode'] ?? '').toString().trim();
    final locationLine = [
      if (city.isNotEmpty) city,
      if (statePincode.isNotEmpty) statePincode,
    ].join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          address['receiver_name'] ?? '',
          style: GoogleFonts.blinker(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(address['address_line1'] ?? '', style: _addressTextStyle()),
        if (line2.isNotEmpty) Text(line2, style: _addressTextStyle()),
        if (locationLine.isNotEmpty)
          Text(locationLine, style: _addressTextStyle()),
        Text(address['country'] ?? 'India', style: _addressTextStyle()),
        const SizedBox(height: 14),
        Text(address['phone_number'] ?? '', style: _addressTextStyle()),
      ],
    );
  }
}

class _AddressCardActions extends StatelessWidget {
  const _AddressCardActions({
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton(
        onPressed: selected ? null : onSelect,
        style: FilledButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFFC3A07D)
              : const Color(0xFFA35710),
          disabledBackgroundColor: const Color(0xFFA35710),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.blinker(
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
        ),
        child: Text(selected ? 'SELECTED' : 'SELECT THIS ADDRESS'),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('EDIT'),
              style: _smallActionStyle(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('DELETE'),
              style: _smallActionStyle(),
            ),
          ),
        ],
      ),
    ],
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final items = _orderItems(order);
    final paidAt = DateTime.tryParse((order['paid_at'] ?? '').toString());

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOrderSheet(context, order, items),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: _orderCardDecoration(),
            child: Row(
              children: [
                _OrderLead(items: items),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items.length == 1 ? items.first.name : 'Cart order',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 24,
                          color: const Color(0xFF5B351A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items.length == 1
                            ? 'Qty ${items.first.quantity}'
                            : '${items.length} items purchased',
                        style: GoogleFonts.blinker(fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        [
                          'Order ${order['order_id']}',
                          if (paidAt != null) _dateLabel(paidAt),
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.blinker(
                          fontSize: 13,
                          color: const Color(0xFF746D64),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${order['amount'] ?? '-'}',
                      style: GoogleFonts.blinker(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Icon(Icons.chevron_right, color: Color(0xFF5B351A)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _orderCardDecoration() => BoxDecoration(
  color: const Color(0xFFECE7DD),
  border: Border.all(color: const Color(0xFFD5B48A)),
  borderRadius: BorderRadius.circular(16),
  boxShadow: const [
    BoxShadow(color: Color(0x1A2D1E12), blurRadius: 12, offset: Offset(0, 5)),
  ],
);

class _OrderLead extends StatelessWidget {
  const _OrderLead({required this.items});
  final List<_InvoiceItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.length > 1) {
      return Container(
        width: 92,
        height: 104,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFD6BFA6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${items.length}',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 36,
                color: const Color(0xFF5B351A),
              ),
            ),
            Text('ITEMS', style: GoogleFonts.blinker(fontSize: 12)),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 92,
        height: 104,
        child: FutureBuilder<String>(
          future: ProductService().getProductImageUrlAsync(items.first.code),
          builder: (context, snapshot) {
            final url = snapshot.data;
            return url == null || url.isEmpty
                ? const ColoredBox(color: Color(0xFFD8D0C3))
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: Color(0xFFD8D0C3)),
                  );
          },
        ),
      ),
    );
  }
}

void _showOrderSheet(
  BuildContext context,
  Map<String, dynamic> order,
  List<_InvoiceItem> items,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _OrderDetailsSheet(order: order, items: items),
  );
}

class _OrderDetailsSheet extends StatelessWidget {
  const _OrderDetailsSheet({required this.order, required this.items});
  final Map<String, dynamic> order;
  final List<_InvoiceItem> items;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .78,
    minChildSize: .45,
    maxChildSize: .94,
    builder: (context, scrollController) => Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFEF5E6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF9A8267),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Order details',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 34,
              color: const Color(0xFF5B351A),
            ),
          ),
          const SizedBox(height: 16),
          for (final item in items) _OrderSheetItem(item: item),
          const SizedBox(height: 18),
          _InvoicePanel(order: order, items: items),
        ],
      ),
    ),
  );
}

class _OrderSheetItem extends StatelessWidget {
  const _OrderSheetItem({required this.item});
  final _InvoiceItem item;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFECE7DD),
      border: Border.all(color: const Color(0xFFD5B48A)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22,
                  color: const Color(0xFF5B351A),
                ),
              ),
              Text(
                [
                  item.code,
                  if (item.size?.isNotEmpty == true) 'Size ${item.size}',
                  'Qty ${item.quantity}',
                ].join(' • '),
                style: GoogleFonts.blinker(fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: item.code.isEmpty
                    ? null
                    : () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.pushNamed(
                          Uri(
                            path: '/product',
                            queryParameters: {'code': item.code},
                          ).toString(),
                        );
                      },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('VIEW PRODUCT'),
              ),
            ],
          ),
        ),
        Text(
          '₹${item.lineTotal}',
          style: GoogleFonts.blinker(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _InvoicePanel extends StatelessWidget {
  const _InvoicePanel({required this.order, required this.items});

  final Map<String, dynamic> order;
  final List<_InvoiceItem> items;

  @override
  Widget build(BuildContext context) {
    final paidAt = DateTime.tryParse((order['paid_at'] ?? '').toString());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF5E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8C684D), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Invoice',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 30,
                    color: const Color(0xFF5B351A),
                  ),
                ),
              ),
              Text(
                paidAt == null ? '' : _dateLabel(paidAt),
                style: GoogleFonts.blinker(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Bill from: Kalasthali By Nisha',
            style: GoogleFonts.blinker(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Bill to:',
            style: GoogleFonts.blinker(fontWeight: FontWeight.w700),
          ),
          Text(
            order['user_address']?.toString() ?? '',
            style: GoogleFonts.blinker(fontSize: 14, height: 1.12),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFD5B48A)),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} x ${item.quantity}',
                      style: GoogleFonts.blinker(fontSize: 15),
                    ),
                  ),
                  Text(
                    '₹${item.lineTotal}',
                    style: GoogleFonts.blinker(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          const Divider(color: Color(0xFFD5B48A)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount paid',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 24,
                  color: const Color(0xFF5B351A),
                ),
              ),
              Text(
                '₹${order['amount'] ?? '-'}',
                style: GoogleFonts.blinker(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Payment ID: ${order['razorpay_payment_id'] ?? 'Pending'}',
            style: GoogleFonts.blinker(
              fontSize: 13,
              color: const Color(0xFF746D64),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressActionButton extends StatelessWidget {
  const _AddressActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF5B351A),
      side: const BorderSide(color: Color(0xFF8C684D), width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      textStyle: GoogleFonts.blinker(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: .4,
      ),
    ),
  );
}

class _AddressEditorSheet extends StatefulWidget {
  const _AddressEditorSheet({required this.userId, this.address});

  final String userId;
  final Map<String, dynamic>? address;

  @override
  State<_AddressEditorSheet> createState() => _AddressEditorSheetState();
}

class _AddressEditorSheetState extends State<_AddressEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _statePincode;
  var _saving = false;

  bool get _editing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _name = TextEditingController(text: address?['receiver_name'] ?? '');
    _phone = TextEditingController(text: address?['phone_number'] ?? '');
    _line1 = TextEditingController(text: address?['address_line1'] ?? '');
    _line2 = TextEditingController(text: address?['address_line2'] ?? '');
    _city = TextEditingController(text: address?['city'] ?? '');
    _statePincode = TextEditingController(
      text: address?['state_pincode'] ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _statePincode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final values = {
      'user_id': widget.userId,
      'receiver_name': _name.text.trim(),
      'phone_number': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'address_line1': _line1.text.trim(),
      'address_line2': _line2.text.trim().isEmpty ? null : _line2.text.trim(),
      'city': _city.text.trim(),
      'state_pincode': _statePincode.text.trim(),
      'country': 'India',
    };
    try {
      final table = Supabase.instance.client.from('user_addresses');
      if (_editing) {
        await table.update(values).eq('id', widget.address!['id']);
      } else {
        await table.insert(values);
      }
      if (mounted) Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      if (mounted) _showSheetError(error.message);
    } catch (_) {
      if (mounted) _showSheetError('Could not save this address.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSheetError(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFFEF5E6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4B89C),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    _editing ? 'Edit address' : 'Add address',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 38,
                      color: const Color(0xFF5B351A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AddressFormField(
                    controller: _name,
                    label: 'Receiver name',
                    textCapitalization: TextCapitalization.words,
                    required: true,
                  ),
                  _AddressFormField(
                    controller: _phone,
                    label: 'Phone number',
                    keyboardType: TextInputType.phone,
                  ),
                  _AddressFormField(
                    controller: _line1,
                    label: 'Address line 1',
                    required: true,
                  ),
                  _AddressFormField(
                    controller: _line2,
                    label: 'Address line 2',
                  ),
                  _AddressFormField(
                    controller: _city,
                    label: 'City',
                    textCapitalization: TextCapitalization.words,
                    required: true,
                  ),
                  _AddressFormField(
                    controller: _statePincode,
                    label: 'State with pincode',
                    textCapitalization: TextCapitalization.words,
                    required: true,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFA35710),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _editing ? 'Save changes' : 'Save address',
                              style: GoogleFonts.blinker(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressFormField extends StatelessWidget {
  const _AddressFormField({
    required this.controller,
    required this.label,
    this.required = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? '$label is required.'
                : null
          : null,
      style: GoogleFonts.blinker(fontSize: 17),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFFFF4E3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF9A8267)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFA35710), width: 1.5),
        ),
      ),
    ),
  );
}

TextStyle _addressTextStyle() => GoogleFonts.blinker(
  fontSize: 16,
  height: 1.08,
  color: const Color(0xFF111111),
);

ButtonStyle _smallActionStyle() => OutlinedButton.styleFrom(
  foregroundColor: const Color(0xFF5B351A),
  side: const BorderSide(color: Color(0xFF8C684D)),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  minimumSize: const Size.fromHeight(42),
  textStyle: GoogleFonts.blinker(fontSize: 14, fontWeight: FontWeight.w700),
);

class _InvoiceItem {
  const _InvoiceItem({
    required this.name,
    required this.code,
    required this.quantity,
    required this.lineTotal,
    this.size,
  });

  final String name;
  final String code;
  final int quantity;
  final int lineTotal;
  final String? size;
}

List<_InvoiceItem> _orderItems(Map<String, dynamic> order) {
  final rawItems = _decodeItems(order['items']);
  if (rawItems.isEmpty) {
    return [
      _InvoiceItem(
        name: (order['product'] ?? 'Order item').toString(),
        code: (order['product_code'] ?? '').toString(),
        quantity: 1,
        lineTotal: _intValue(order['amount']),
      ),
    ];
  }
  return rawItems.map((item) {
    final quantity = _intValue(item['quantity'], fallback: 1);
    final lineTotal = _intValue(
      item['line_total'],
      fallback: _intValue(item['unit_price']) * quantity,
    );
    return _InvoiceItem(
      name: (item['product_name'] ?? item['name'] ?? 'Order item').toString(),
      code: (item['product_code'] ?? item['code'] ?? '').toString(),
      quantity: quantity,
      lineTotal: lineTotal,
      size: item['size']?.toString(),
    );
  }).toList();
}

List<Map<String, dynamic>> _decodeItems(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList();
      }
    } catch (_) {}
  }
  return const [];
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
