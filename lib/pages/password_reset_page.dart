import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/responsive.dart';
import '../core/services/auth_service.dart';
import '../core/services/seo_service.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_scaffold.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  var _loading = false;
  String? _message;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (AuthService.currentSession == null) {
      setState(() {
        _message = 'This password reset link is invalid or has expired.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await AuthService.updatePassword(_password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your password has been updated.')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/account', (_) => false);
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SeoService.setPage(
      title: 'Reset Password | Kalasthali By Nisha',
      description: 'Choose a new password for your Kalasthali account.',
      path: '/reset-password',
    );
    return AppScaffold(
      title: 'Reset Password',
      currentRoute: '/account',
      centerBody: false,
      body: LayoutBuilder(
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
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF5E6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFD5B48A),
                            width: 1.5,
                          ),
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
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reset your password',
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 38,
                                    color: const Color(0xFF5B351A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Choose a new password for your account.',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 18,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 26),
                                TextFormField(
                                  controller: _password,
                                  obscureText: true,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'New password',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => (value?.length ?? 0) < 6
                                      ? 'Use at least 6 characters.'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmation,
                                  obscureText: true,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Confirm new password',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => value != _password.text
                                      ? 'The passwords do not match.'
                                      : null,
                                ),
                                if (_message != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    _message!,
                                    style: GoogleFonts.ibmPlexSans(
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
                                        ? const SizedBox.square(
                                            dimension: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'Update password',
                                            style: GoogleFonts.ibmPlexSans(
                                              fontSize: 19,
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
                  ),
                ),
              ),
              const AppFooterSliver(),
            ],
          );
        },
      ),
    );
  }
}
