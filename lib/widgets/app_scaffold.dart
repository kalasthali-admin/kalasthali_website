import 'package:flutter/material.dart';

const double _desktopHeaderBreakpoint = 1220;

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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < _desktopHeaderBreakpoint;
    final logoHeight = isMobile ? 58.0 : 80.0;

    return Scaffold(
      backgroundColor: Color.fromRGBO(231, 226, 215, 1),
      endDrawer: isMobile
          ? _NavigationDrawer(currentRoute: currentRoute)
          : null,
      appBar: AppBar(
        elevation: 5,
        scrolledUnderElevation: 0,
        shadowColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        toolbarHeight: 110,
        automaticallyImplyLeading: false,
        backgroundColor: logoBackground,
        actions: isMobile
            ? const [
                EndDrawerButton(
                  style: ButtonStyle(
                    foregroundColor: WidgetStatePropertyAll(Color(0xFF1F1E25)),
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
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    'lib/assets/logo_text.png',
                    height: logoHeight,
                    fit: BoxFit.contain,
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
        for (final item in _primaryItems) ...[
          _HeaderButton(
            label: item.label,
            onTap: () => _goTo(context, item.route!),
            isActive: currentRoute == item.route,
          ),
          const SizedBox(width: 18),
        ],
        Container(width: 3, height: 68, color: const Color(0xFFA69E91)),
        const SizedBox(width: 18),
        _HeaderButton(
          label: 'LOG IN',
          onTap: () => _showLoginSheet(context),
          icon: Icons.account_circle,
        ),
      ],
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
            for (final item in [..._primaryItems, _loginItem])
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
                  if (item.route == null) {
                    _showLoginSheet(context);
                    return;
                  }

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
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: icon == null ? 20 : 18,
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
                Icon(icon, size: 34, color: const Color(0xFF1F1E25)),
                const SizedBox(width: 12),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.4,
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
  _NavItem(label: 'COLLECTION', route: '/collection'),
  _NavItem(label: 'ABOUT', route: '/about'),
  _NavItem(label: 'CONTACT', route: '/contact'),
];

const _NavItem _loginItem = _NavItem(
  label: 'LOG IN',
  icon: Icons.account_circle,
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

void _goTo(BuildContext context, String route) {
  if (ModalRoute.of(context)?.settings.name == route) {
    return;
  }

  Navigator.pushReplacementNamed(context, route);
}
