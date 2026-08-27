import 'package:flutter/material.dart';

import '../core/services/cart_service.dart';

const double _desktopHeaderBreakpoint = 850;

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.currentRoute,
    required this.body,
    this.centerBody = true,
    super.key,
  });

  final String title;
  final String currentRoute;
  final Widget body;
  final bool centerBody;

  @override
  Widget build(BuildContext context) {
    const logoBackground = Color(0xFFFEF5E6);
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    // Landscape phones can be wide enough for a desktop breakpoint but do not
    // have enough horizontal room for the full search/navigation row.
    final isMobile =
        screenWidth < _desktopHeaderBreakpoint || screenSize.height < 600;
    final logoHeight = isMobile ? 58.0 : 70.0;

    return Scaffold(
      backgroundColor: Color.fromRGBO(231, 226, 215, 1),
      endDrawer: isMobile
          ? _NavigationDrawer(currentRoute: currentRoute)
          : null,
      appBar: AppBar(
        elevation: 5,
        scrolledUnderElevation: 5,
        shadowColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(5)),
        ),
        toolbarHeight: 110,
        automaticallyImplyLeading: false,
        backgroundColor: logoBackground,
        actions: isMobile
            ? const [
                Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: EndDrawerButton(
                    style: ButtonStyle(
                      foregroundColor: WidgetStatePropertyAll(
                        Color(0xFF1F1E25),
                      ),
                    ),
                  ),
                ),
              ]
            : const [],
        titleSpacing: 0,
        title: Row(
          children: [
            SizedBox(width: isMobile ? 12 : 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    overlayColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                    onTap: () => _goTo(context, '/home'),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'lib/assets/logo_text.png',
                        height: logoHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!isMobile) _DesktopNavigation(currentRoute: currentRoute),
            SizedBox(width: isMobile ? 12 : 24),
          ],
        ),
      ),
      body: centerBody ? Center(child: body) : body,
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _ProductSearchField(),
        const SizedBox(width: 10),
        _HeaderButton(
          label: 'COLLECTION',
          onTap: () => _goTo(context, '/collections'),
          isActive: currentRoute == '/collections',
        ),
        const SizedBox(width: 12),
        Container(width: 2, height: 40, color: const Color(0xFFA69E91)),
        const SizedBox(width: 16),
        AnimatedBuilder(
          animation: CartService.instance,
          builder: (context, _) => _HeaderButton(
            label: 'CART (${CartService.instance.itemCount})',
            onTap: () => _goTo(context, '/cart'),
            icon: Icons.shopping_bag_outlined,
          ),
        ),
      ],
    );
  }
}

class _ProductSearchField extends StatelessWidget {
  const _ProductSearchField();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 700,
      height: 45,
      child: TextField(
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: Color(0xFF1F1E25),
          fontSize: 18,
          letterSpacing: 2,
        ),
        decoration: const InputDecoration(
          hintText: 'SEARCH FOR PRODUCTS',
          hintStyle: TextStyle(
            color: Color(0xFF746D64),
            fontSize: 18,
            letterSpacing: 2,
          ),
          prefixIcon: Icon(Icons.search, size: 19),
          prefixIconColor: Color(0xFF746D64),
          filled: true,
          fillColor: Color(0xFFE7D0AE),
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF914B0D)),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }
}

class _NavigationDrawer extends StatelessWidget {
  const _NavigationDrawer({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFEF5E6),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 20),
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1E25),
                ),
              ),
            ),
            for (final item in [..._primaryItems, _cartItem])
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                tileColor: item.route != null && currentRoute == item.route
                    ? const Color(0xFFE7D0AE)
                    : Colors.transparent,
                leading: item.icon == null
                    ? null
                    : Icon(item.icon, color: const Color(0xFF1F1E25)),
                title: Text(
                  item.label,
                  style: const TextStyle(
                    color: Color(0xFF1F1E25),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _goTo(context, item.route!);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.isActive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isActive
        ? const Color(0xFFE2C7A0)
        : const Color(0xFFE7D0AE);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: icon == null ? 10 : 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 24, color: const Color(0xFF1F1E25)),
                const SizedBox(width: 8),
              ],
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, this.route, this.icon});

  final String label;
  final String? route;
  final IconData? icon;
}

const List<_NavItem> _primaryItems = [
  _NavItem(label: 'HOME', route: '/home'),
  _NavItem(label: 'COLLECTION', route: '/collections'),
];

const _NavItem _cartItem = _NavItem(
  label: 'CART',
  route: '/cart',
  icon: Icons.shopping_bag_outlined,
);

Future<void> _showLoginSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFFFEF5E6),
    barrierColor: Colors.black54,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8C7B0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Log In',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1E25),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This is a placeholder sign-in sheet for now. We can wire it to a real auth flow next.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF4B463E),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF914B0D),
                  side: const BorderSide(color: Color(0xFF914B0D), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _showCreateAccountSheet(context),
                child: const Text('Create account'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF914B0D),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showCreateAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFFFEF5E6),
    barrierColor: Colors.black54,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8C7B0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1E25),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Use your email address and a password to get started.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF4B463E),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF914B0D),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {},
                child: const Text('Create account'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _goTo(BuildContext context, String route) {
  if (ModalRoute.of(context)?.settings.name == route) {
    return;
  }

  Navigator.pushReplacementNamed(context, route);
}
