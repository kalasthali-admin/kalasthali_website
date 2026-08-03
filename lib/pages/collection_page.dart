import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Collection',
      currentRoute: '/collection',
      body: Text('Browse the collection page.'),
    );
  }
}
