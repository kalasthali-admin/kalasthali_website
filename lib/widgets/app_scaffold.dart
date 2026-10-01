import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/responsive.dart';
import '../core/services/auth_service.dart';
import '../core/services/home_navigation_service.dart';

const double _desktopHeaderBreakpoint = 850;
const double _desktopHeaderControlHeight = 34;

class AppScaffold extends StatefulWidget {
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
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _scrollFocusNode = FocusNode(debugLabel: 'app-scroll-focus');
  final FocusNode _headerSearchFocusNode = FocusNode(
    debugLabel: 'header-search',
  );
  final TextEditingController _headerSearchController = TextEditingController();
  var _searchOpen = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollFocusNode.dispose();
    _headerSearchFocusNode.dispose();
    _headerSearchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _headerSearchFocusNode.requestFocus();
      });
    }
  }

  void _submitSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    setState(() => _searchOpen = false);
    Navigator.pushReplacementNamed(
      context,
      Uri(path: '/collections', queryParameters: {'search': query}).toString(),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !_scrollController.hasClients) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final position = _scrollController.position;
    final viewport = position.viewportDimension;
    final current = position.pixels;
    final delta = switch (key) {
      LogicalKeyboardKey.arrowDown => 80.0,
      LogicalKeyboardKey.arrowUp => -80.0,
      LogicalKeyboardKey.pageDown => viewport * .85,
      LogicalKeyboardKey.pageUp => -viewport * .85,
      LogicalKeyboardKey.home => -double.infinity,
      LogicalKeyboardKey.end => double.infinity,
      _ => null,
    };
    if (delta == null) return KeyEventResult.ignored;

    final target = delta.isInfinite
        ? (delta.isNegative
              ? position.minScrollExtent
              : position.maxScrollExtent)
        : (current + delta).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    const logoBackground = Color(0xFFFEF5E6);
    // Landscape phones can be wide enough for a desktop breakpoint but do not
    // have enough horizontal room for the full search/navigation row.
    final isMobile = useCompactLayout(
      context,
      breakpoint: _desktopHeaderBreakpoint,
    );
    final viewport = MediaQuery.sizeOf(context);
    final tabletPortrait =
        !isMobile && viewport.height > viewport.width && viewport.width < 1100;

    return Scaffold(
      backgroundColor: Color.fromRGBO(231, 226, 215, 1),
      endDrawer: isMobile
          ? _NavigationDrawer(currentRoute: widget.currentRoute)
          : null,
      appBar: AppBar(
        elevation: 5,
        scrolledUnderElevation: 5,
        shadowColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(5)),
        ),
        toolbarHeight: isMobile ? 80 : 88,
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
        title: isMobile
            ? const _MobileHeader()
            : _DesktopHeader(
                currentRoute: widget.currentRoute,
                searchOpen: _searchOpen,
                searchController: _headerSearchController,
                searchFocusNode: _headerSearchFocusNode,
                onSearchToggle: _toggleSearch,
                onSearchSubmitted: _submitSearch,
                showNavigationLinks: !tabletPortrait,
              ),
      ),
      body: Focus(
        focusNode: _scrollFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: PrimaryScrollController(
          controller: _scrollController,
          child: widget.centerBody ? Center(child: widget.body) : widget.body,
        ),
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    required this.currentRoute,
    required this.searchOpen,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchToggle,
    required this.onSearchSubmitted,
    required this.showNavigationLinks,
  });

  final String currentRoute;
  final bool searchOpen;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchSubmitted;
  final bool showNavigationLinks;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        _BrandMark(width: 258, height: 62),
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: searchOpen && showNavigationLinks
                  ? _HeaderSearchField(
                      key: const ValueKey('header-search'),
                      controller: searchController,
                      focusNode: searchFocusNode,
                      onSubmitted: onSearchSubmitted,
                    )
                  : (showNavigationLinks
                        ? _DesktopLinks(
                            key: const ValueKey('header-links'),
                            currentRoute: currentRoute,
                          )
                        : const SizedBox.shrink()),
            ),
          ),
        ),
        if (showNavigationLinks)
          _HeaderIconButton(
            tooltip: searchOpen ? 'Close search' : 'Search products',
            icon: searchOpen ? Icons.close : Icons.search,
            onTap: onSearchToggle,
          ),
        const _DesktopAdminButton(),
        const SizedBox(width: 8),
        _HeaderIconButton(
          tooltip: 'Cart',
          icon: Icons.shopping_cart_outlined,
          onTap: () => _goToCart(context),
        ),
        const SizedBox(width: 8),
        const _AccountHeaderButton(),
      ],
    ),
  );
}

class _DesktopLinks extends StatelessWidget {
  const _DesktopLinks({required this.currentRoute, super.key});

  final String currentRoute;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _TextNavLink(
        label: 'HOME',
        active: currentRoute == '/',
        onTap: () => _goTo(context, '/'),
      ),
      const SizedBox(width: 24),
      _TextNavLink(
        label: 'NEW ARRIVALS',
        onTap: () => HomeNavigationService.requestNewArrivals(context),
      ),
      const SizedBox(width: 24),
      _TextNavLink(
        label: 'COLLECTIONS',
        active: currentRoute == '/collections',
        onTap: () => _goTo(context, '/collections'),
      ),
    ],
  );
}

class _HeaderSearchField extends StatelessWidget {
  const _HeaderSearchField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 380),
    child: SizedBox(
      height: _desktopHeaderControlHeight,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          fontSize: 13,
          letterSpacing: 2,
          color: Color(0xFF1F1E25),
        ),
        decoration: const InputDecoration(
          hintText: 'SEARCH FOR PRODUCTS',
          hintStyle: TextStyle(
            fontSize: 12,
            letterSpacing: 2,
            color: Color(0xFF746D64),
          ),
          prefixIcon: Icon(Icons.search, size: 20),
          prefixIconColor: Color(0xFF746D64),
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          isDense: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            borderSide: BorderSide(color: Color(0xFF914B0D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            borderSide: BorderSide(color: Color(0xFF914B0D), width: 1.5),
          ),
        ),
      ),
    ),
  );
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: _BrandMark(height: 58),
    ),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        onTap: () => _goTo(context, '/'),
        child: Image.asset(
          'lib/assets/logo_text.png',
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    ),
  );
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
                  if (item.route == '/cart') {
                    _goToCart(context);
                    return;
                  }
                  _goTo(context, item.route!);
                },
              ),
            StreamBuilder(
              stream: AuthService.userChanges,
              initialData: AuthService.currentUser,
              builder: (context, snapshot) {
                final user = snapshot.data ?? AuthService.currentUser;
                if (!AuthService.isAdmin(user)) return const SizedBox.shrink();
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  tileColor: currentRoute == '/admin'
                      ? const Color(0xFFE7D0AE)
                      : Colors.transparent,
                  leading: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Color(0xFF1F1E25),
                  ),
                  title: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Color(0xFF1F1E25),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _goTo(context, '/admin');
                  },
                );
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

class _TextNavLink extends StatefulWidget {
  const _TextNavLink({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  State<_TextNavLink> createState() => _TextNavLinkState();
}

class _TextNavLinkState extends State<_TextNavLink> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFF1F1E25),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.3,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 1.5,
                width: widget.active || _hovered ? 44 : 0,
                color: const Color(0xFF914B0D),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    const size = _desktopHeaderControlHeight;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF914B0D)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 23, color: const Color(0xFF1F1E25)),
          ),
        ),
      ),
    );
  }
}

class _DesktopAdminButton extends StatelessWidget {
  const _DesktopAdminButton();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.userChanges,
      initialData: AuthService.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data ?? AuthService.currentUser;
        if (!AuthService.isAdmin(user)) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _goTo(context, '/admin'),
              child: Container(
                height: _desktopHeaderControlHeight,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF914B0D)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Color(0xFF1F1E25),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.1,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AccountHeaderButton extends StatelessWidget {
  const _AccountHeaderButton();

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: AuthService.userChanges,
    initialData: AuthService.currentUser,
    builder: (context, snapshot) {
      final user = snapshot.data ?? AuthService.currentUser;
      final label = user == null ? 'Log In' : AuthService.firstName(user);
      const height = _desktopHeaderControlHeight;
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 145),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _goTo(context, '/account'),
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF914B0D)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 22,
                    color: const Color(0xFF1F1E25),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F1E25),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
  _NavItem(label: 'HOME', route: '/', icon: Icons.home_outlined),
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

void _goToCart(BuildContext context) {
  _goTo(context, AuthService.currentUser == null ? '/account' : '/cart');
}
