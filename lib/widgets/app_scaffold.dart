import 'package:flutter/material.dart';

import '../core/services/auth_service.dart';

const double _desktopHeaderBreakpoint = 850;
const double _headerSearchBreakpoint = 1200;

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
        toolbarHeight: isMobile ? 80 : 90,
        automaticallyImplyLeading: false,
        backgroundColor: logoBackground,
        actions: isMobile
            ? const [
                _AccountHeaderButton(compact: true),
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
    final showSearch =
        MediaQuery.sizeOf(context).width >= _headerSearchBreakpoint;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSearch &&
            currentRoute != '/collections' &&
            currentRoute != '/admin') ...[
          const _ProductSearchField(),
          const SizedBox(width: 10),
        ],
        _HeaderButton(
          label: 'COLLECTION',
          onTap: () => _goTo(context, '/collections'),
          isActive: currentRoute == '/collections',
        ),
        const SizedBox(width: 10),
        _HeaderButton(
          label: 'CART',
          onTap: () => _goTo(context, '/cart'),
          isActive: currentRoute == '/cart',
          icon: Icons.shopping_cart_outlined,
        ),
        const SizedBox(width: 10),
        _AccountHeaderButton(isActive: currentRoute == '/account'),
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
        onSubmitted: (value) {
          final query = value.trim();
          if (query.isEmpty) return;
          Navigator.pushNamed(
            context,
            Uri(
              path: '/collections',
              queryParameters: {'search': query},
            ).toString(),
          );
        },
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
            for (final item in _primaryItems)
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
            const Divider(),
            const _DrawerAccountItem(),
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
    this.isActive = false,
    this.icon,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19),
                const SizedBox(width: 5),
              ],
              Padding(
                padding: const EdgeInsets.all(5),
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

class _AccountHeaderButton extends StatelessWidget {
  const _AccountHeaderButton({this.compact = false, this.isActive = false});

  final bool compact;
  final bool isActive;

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: AuthService.userChanges,
    initialData: AuthService.currentUser,
    builder: (context, snapshot) {
      final user = snapshot.data ?? AuthService.currentUser;
      final label = user == null ? 'Log In' : AuthService.firstName(user);
      if (!compact) {
        return _HeaderButton(
          label: label,
          isActive: isActive,
          onTap: () => _goTo(context, '/account'),
        );
      }
      return TextButton.icon(
        onPressed: () => _goTo(context, '/account'),
        icon: Icon(user == null ? Icons.login : Icons.person_outline, size: 18),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF1F1E25),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1F1E25),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          maximumSize: const Size(112, 48),
        ),
      );
    },
  );
}

class _DrawerAccountItem extends StatelessWidget {
  const _DrawerAccountItem();

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: AuthService.userChanges,
    initialData: AuthService.currentUser,
    builder: (context, snapshot) {
      final user = snapshot.data ?? AuthService.currentUser;
      final label = user == null
          ? 'LOG IN / SIGN UP'
          : AuthService.firstName(user);
      return ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(
          user == null ? Icons.login_outlined : Icons.person_outline,
          color: const Color(0xFF1F1E25),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1F1E25),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        subtitle: user == null || user.email == null
            ? null
            : Text(user.email!, overflow: TextOverflow.ellipsis),
        onTap: () {
          Navigator.of(context).pop();
          _goTo(context, '/account');
        },
      );
    },
  );
}

class _NavItem {
  const _NavItem({required this.label, this.route, this.icon});

  final String label;
  final String? route;
  final IconData? icon;
}

const List<_NavItem> _primaryItems = [
  _NavItem(label: 'HOME', route: '/home', icon: Icons.home_outlined),
  _NavItem(
    label: 'COLLECTION',
    route: '/collections',
    icon: Icons.grid_view_outlined,
  ),
  _NavItem(label: 'CART', route: '/cart', icon: Icons.shopping_cart_outlined),
];

void _goTo(BuildContext context, String route) {
  if (ModalRoute.of(context)?.settings.name == route) {
    return;
  }

  Navigator.pushReplacementNamed(context, route);
}
