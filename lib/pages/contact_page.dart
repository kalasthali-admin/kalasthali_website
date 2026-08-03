import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Contact',
      currentRoute: '/contact',
      body: Text('Get in touch with Kalasthali here.'),
    );
  }
}
