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
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        mobile ? 22 : 54,
                        mobile ? 70 : 104,
                        mobile ? 22 : 54,
                        mobile ? 88 : 120,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: user == null
                              ? const _AccountAuthForm()
                              : _AccountDetails(user: user),
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

class _AccountDetails extends StatelessWidget {
  const _AccountDetails({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF5E6),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFD5B48A), width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${AuthService.firstName(user)}',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 40,
            color: const Color(0xFF5B351A),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your account is ready for saved details, orders, and secure checkout.',
          style: GoogleFonts.blinker(fontSize: 18, height: 1.35),
        ),
        const SizedBox(height: 28),
        const Divider(color: Color(0xFFD5B48A)),
        const SizedBox(height: 18),
        Text('EMAIL', style: GoogleFonts.blinker(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          user.email ?? 'No email address',
          style: GoogleFonts.blinker(fontSize: 19),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Supabase.instance.client.auth.signOut(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFA35710),
              side: const BorderSide(color: Color(0xFFA35710), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text('Log out', style: GoogleFonts.blinker(fontSize: 18)),
          ),
        ),
      ],
    ),
  );
}
