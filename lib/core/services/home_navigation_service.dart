import 'package:flutter/widgets.dart';

import 'public_page_navigation.dart';

/// Coordinates navigation to named sections on the home page.
class HomeNavigationService {
  HomeNavigationService._();

  static final newArrivalsKey = GlobalKey();
  static var _scrollToNewArrivalsWhenReady = false;

  static void requestNewArrivals(BuildContext context) {
    if (Uri.base.path != '/') {
      openPublicPage(context, '/#new-arrivals');
      return;
    }
    if (ModalRoute.of(context)?.settings.name == '/') {
      _scrollToNewArrivals();
      return;
    }

    _scrollToNewArrivalsWhenReady = true;
    Navigator.pushReplacementNamed(context, '/');
  }

  static void completePendingRequest() {
    if (!_scrollToNewArrivalsWhenReady) return;
    _scrollToNewArrivalsWhenReady = false;
    _scrollToNewArrivals();
  }

  static void _scrollToNewArrivals() {
    final targetContext = newArrivalsKey.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
      alignment: 0.08,
    );
  }
}
