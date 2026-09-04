import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'core/supabase_config.dart';
import 'pages/collection_page.dart';
import 'pages/contact_page.dart';
import 'pages/home_page.dart';
import 'pages/not_found_page.dart';
import 'pages/about_page.dart';
import 'pages/account_page.dart';
import 'pages/checkout_page.dart';
import 'pages/cart_page.dart';
import 'pages/product_page.dart';
import 'pages/settings_page.dart';
import 'pages/admin_page.dart';

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
  static const String adminRoute = '/admin';
  static const String accountRoute = '/account';
  static const String checkoutRoute = '/checkout';
  static const String cartRoute = '/cart';

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
        adminRoute: (context) => const AdminPage(),
        accountRoute: (context) => const AccountPage(),
        checkoutRoute: (context) => const CheckoutPage(),
        cartRoute: (context) => const CartPage(),
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

        if (uri.path == checkoutRoute) {
          return MaterialPageRoute<void>(
            builder: (_) =>
                CheckoutPage(productCode: uri.queryParameters['code'] ?? ''),
            settings: settings,
          );
        }

        return MaterialPageRoute<void>(
          builder: (_) => const NotFoundPage(),
          settings: settings,
        );
      },
    );
  }
}
