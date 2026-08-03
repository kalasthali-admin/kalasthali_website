import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Log In',
      currentRoute: '/login',
      body: Text('Sign in to your account here.'),
    );
  }
}
