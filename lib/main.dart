import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'core/supabase_config.dart';
import 'pages/collection_page.dart';
import 'pages/contact_page.dart';
import 'pages/home_page.dart';
import 'pages/about_page.dart';
import 'pages/product_page.dart';
import 'pages/settings_page.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  setUrlStrategy(PathUrlStrategy());
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  runApp(const KalasthaliApp());
}

class KalasthaliApp extends StatelessWidget {
  const KalasthaliApp({super.key});

  static const String homeRoute = '/home';
  static const String collectionRoute = '/collections';
  static const String aboutRoute = '/about';
  static const String contactRoute = '/contact';
  static const String productRoute = '/product';
  static const String settingsRoute = '/settings';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF65421F)),
      ),
      title: 'Kalasthali By Nisha',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
      initialRoute: homeRoute,
      routes: {
        homeRoute: (context) => const HomePage(),
        collectionRoute: (context) => const CollectionPage(),
        aboutRoute: (context) => const AboutPage(),
        contactRoute: (context) => const ContactPage(),
        productRoute: (context) => const ProductPage(),
        settingsRoute: (context) => const SettingsPage(),
      },
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        if (uri.path == '/') {
          return MaterialPageRoute<void>(
            builder: (_) => const HomePage(),
            settings: const RouteSettings(name: homeRoute),
          );
        }

        if (uri.path == collectionRoute || uri.path == '/collection') {
          return MaterialPageRoute<void>(
            builder: (_) => CollectionPage(
              initialCategory: uri.queryParameters['category'],
              initialSearch: uri.queryParameters['search'],
            ),
            settings: settings,
          );
        }

        if (uri.path == productRoute) {
          final code = uri.queryParameters['code'] ?? uri.query;
          return MaterialPageRoute<void>(
            builder: (_) => ProductPage(productCode: code),
            settings: settings,
          );
        }

        return MaterialPageRoute<void>(
          builder: (_) => const UnknownRoutePage(),
          settings: settings,
        );
      },
    );
  }
}

class UnknownRoutePage extends StatelessWidget {
  const UnknownRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: const Center(child: Text('This page does not exist.')),
    );
  }
}
