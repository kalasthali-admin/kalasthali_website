import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/auth_service.dart';
import '../core/services/seo_service.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_scaffold.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    SeoService.setPage(
      title: 'Account | Kalasthali By Nisha',
      description: 'Sign in to your Kalasthali account.',
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
              final mobile = constraints.maxWidth < 700;
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          mobile ? 22 : 54,
                          mobile ? 70 : 104,
                          mobile ? 22 : 54,
                          mobile ? 88 : 120,
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
                : 'Log in to access your Kalasthali account.',
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

  @override
  void initState() {
    super.initState();
    _addresses = _loadAddresses();
  }

  Future<List<Map<String, dynamic>>> _loadAddresses() async =>
      (await Supabase.instance.client
                  .from('user_addresses')
                  .select()
                  .eq('user_id', widget.user.id)
                  .order('created_at')
              as List)
          .cast<Map<String, dynamic>>();

  Future<void> _refresh() async =>
      setState(() => _addresses = _loadAddresses());

  Future<void> _select(String id) async {
    await Supabase.instance.client
        .from('user_addresses')
        .update({'is_selected': true})
        .eq('id', id);
    await _refresh();
  }

  Future<void> _delete(String id) async {
    await Supabase.instance.client.from('user_addresses').delete().eq('id', id);
    await _refresh();
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
      Row(
        children: [
          Expanded(
            child: _ProfileValue(
              label: 'EMAIL',
              value: widget.user.email ?? 'No email address',
            ),
          ),
          const Expanded(
            child: _ProfileValue(label: 'PHONE NUMBER', value: 'Not added'),
          ),
        ],
      ),
      const SizedBox(height: 38),
      Text(
        'SAVED ADDRESSES',
        style: GoogleFonts.blinker(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      const SizedBox(height: 14),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _addresses,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          if (snapshot.data!.isEmpty)
            return Text(
              'No saved addresses yet. Add one during checkout.',
              style: GoogleFonts.blinker(fontSize: 17),
            );
          return Column(
            children: snapshot.data!
                .map(
                  (address) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _AddressCard(
                      address: address,
                      onSelect: _select,
                      onDelete: _delete,
                    ),
                  ),
                )
                .toList(),
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

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onSelect,
    required this.onDelete,
  });
  final Map<String, dynamic> address;
  final ValueChanged<String> onSelect, onDelete;
  @override
  Widget build(BuildContext context) {
    final selected = address['is_selected'] == true;
    final id = address['id'] as String;
    return Container(
      width: 640,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD5B48A)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x182D1E12), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address['receiver_name'] ?? '',
                  style: GoogleFonts.blinker(fontSize: 16),
                ),
                Text(
                  address['address_line1'] ?? '',
                  style: GoogleFonts.blinker(fontSize: 15),
                ),
                if ((address['address_line2'] ?? '').toString().isNotEmpty)
                  Text(
                    address['address_line2'],
                    style: GoogleFonts.blinker(fontSize: 15),
                  ),
                Text(
                  '${address['city'] ?? ''}, ${address['state_pincode'] ?? ''}',
                  style: GoogleFonts.blinker(fontSize: 15),
                ),
                Text(
                  address['country'] ?? 'India',
                  style: GoogleFonts.blinker(fontSize: 15),
                ),
                const SizedBox(height: 10),
                Text(
                  address['phone_number'] ?? '',
                  style: GoogleFonts.blinker(fontSize: 15),
                ),
              ],
            ),
          ),
          Column(
            children: [
              FilledButton(
                onPressed: selected ? null : () => onSelect(id),
                child: Text(selected ? 'SELECTED' : 'SELECT THIS ADDRESS'),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/checkout'),
                    child: const Text('EDIT'),
                  ),
                  TextButton(
                    onPressed: () => onDelete(id),
                    child: const Text('DELETE'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
