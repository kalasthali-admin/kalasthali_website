import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'About',
      currentRoute: '/about',
      body: Text('Learn more about Kalasthali here.'),
    );
  }
}
