import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/responsive.dart';
import '../core/services/home_navigation_service.dart';
import '../core/services/seo_service.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/popular_products_carousel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomeNavigationService.completePendingRequest();
    });
    SeoService.setPage(
      title: 'Kalasthali By Nisha | Handpainted Clothing',
      description: 'Handpainted clothing crafted with art and individuality.',
      path: '/',
    );
    return AppScaffold(
      title: 'Home',
      currentRoute: '/',
      centerBody: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = useCompactLayout(context, breakpoint: 700);

          return CustomScrollView(
            primary: true,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, isMobile ? 0 : 40),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: isMobile
                            ? const _MobileHero()
                            : const _DesktopHero(),
                      ),
                      const SizedBox(height: 100),
                      KeyedSubtree(
                        key: HomeNavigationService.newArrivalsKey,
                        child: Column(
                          children: [
                            const _SectionHeader(title: 'New Arrivals'),
                            SizedBox(height: isMobile ? 40 : 52),
                            PopularProductsCarousel(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 110),
                      const _ShopByCategory(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              const AppFooterSliver(),
            ],
          );
        },
      ),
    );
  }
}

class _DesktopHero extends StatelessWidget {
  const _DesktopHero();

  static const _assetWidth = 3796.0;
  static const _transparentTop = 70.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final viewport = MediaQuery.sizeOf(context);
        final tabletPortrait = width < 1100 && viewport.height > viewport.width;
        // Keep the desktop landing artwork intentionally immersive.
        final heroHeight = tabletPortrait
            ? viewport.height * 0.5
            : (width < 1100
                  ? width / 2
                  : (width / 2).clamp(1080.0, double.infinity));
        final transparentTop = width * _transparentTop / _assetWidth;
        final isTablet = width < 1100;
        final cardWidth = isTablet ? width * 0.44 : width * 0.43;
        final overlayOffset = isTablet ? 28.0 : 42.0;
        final overlayTop =
            heroHeight * (tabletPortrait ? 0.46 : (isTablet ? 0.48 : 0.52));
        final titleSize = isTablet ? 32.0 : 42.0;
        final subtitleSize = isTablet ? 16.0 : 22.0;
        final innerPadding = isTablet
            ? const EdgeInsets.fromLTRB(22, 20, 22, 22)
            : const EdgeInsets.fromLTRB(30, 28, 30, 30);
        final minimumHeight = isTablet ? 180.0 : null;

        return SizedBox(
          height: heroHeight,
          child: Stack(
            children: [
              ClipRect(
                child: Transform.translate(
                  offset: Offset(0, -transparentTop),
                  child: SizedBox(
                    width: width,
                    height: heroHeight + transparentTop,
                    child: Image.asset(
                      'lib/assets/homepage_art_large.webp',
                      fit: BoxFit.cover,
                      width: width,
                      height: heroHeight + transparentTop,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: overlayOffset,
                top: overlayTop,
                width: cardWidth,
                child: _HeroCard(
                  title: 'Handpainted Art\nAt its finest.',
                  subtitle: 'All at your fingertips',
                  titleSize: titleSize,
                  subtitleSize: subtitleSize,
                  buttonCenter: false,
                  innerPadding: innerPadding,
                  minHeight: minimumHeight,
                  buttonTextSize: isTablet ? 16 : 18,
                  buttonVerticalPadding: isTablet ? 15 : 18,
                  buttonHorizontalPadding: isTablet ? 18 : 22,
                  buttonIconSize: isTablet ? 22 : 24,
                  onExplore: () => _goToCollection(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileHero extends StatelessWidget {
  const _MobileHero();

  static const _assetWidth = 786.0;
  static const _transparentTop = 80.0;
  static const _heroAspectRatio = 393 / 852;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final heroHeight = width / _heroAspectRatio;
      final transparentTop = width * _transparentTop / _assetWidth;

      return SizedBox(
        height: heroHeight,
        child: Stack(
          children: [
            ClipRect(
              child: Transform.translate(
                offset: Offset(0, -transparentTop),
                child: SizedBox(
                  height: heroHeight + transparentTop,
                  width: width,
                  child: Image.asset(
                    'lib/assets/homepage_art_mobile.webp',
                    fit: BoxFit.cover,
                    width: width,
                    height: heroHeight + transparentTop,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _HeroCard(
                title: 'Handpainted Art\nAt its finest',
                subtitle: 'All at your fingertips',
                titleSize: 36,
                subtitleSize: 24,
                buttonCenter: true,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                outerPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                innerPadding: const EdgeInsets.fromLTRB(24, 26, 24, 36),
                minHeight: 450,
                onExplore: () => _goToCollection(context),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ShopByCategory extends StatelessWidget {
  const _ShopByCategory();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = useCompactLayout(context, breakpoint: 700);
        final showThreeColumns = constraints.maxWidth >= 1200;
        final tileWidth = isMobile
            ? constraints.maxWidth - 32
            : (constraints.maxWidth > 560
                  ? 266.0
                  : (constraints.maxWidth - 28) / 2);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: showThreeColumns ? 1580 : 560,
              ),
              child: Column(
                children: [
                  const _SectionHeader(title: 'Shop By Category'),
                  SizedBox(height: isMobile ? 40 : 52),
                  if (isMobile) ...[
                    _CategoryButton(
                      label: 'Home Decor',
                      imagePath:
                          'lib/assets/category_grid/home_decor_small.png',
                      onTap: () => _goToCollection(context, 'home-decor'),
                    ),
                    const SizedBox(height: 30),
                    _CategoryButton(
                      label: 'Sarees',
                      imagePath: 'lib/assets/category_grid/sarees_small.png',
                      onTap: () => _goToCollection(context, 'sarees'),
                    ),
                    const SizedBox(height: 30),
                    _CategoryButton(
                      label: 'Dresses',
                      imagePath: 'lib/assets/category_grid/dresses_small.png',
                      onTap: () => _goToCollection(context, 'dresses'),
                    ),
                  ] else if (showThreeColumns) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _CategoryButton(
                            label: 'Home Decor',
                            imagePath:
                                'lib/assets/category_grid/home_decor_large.png',
                            onTap: () => _goToCollection(context, 'home-decor'),
                          ),
                        ),
                        const SizedBox(width: 30),
                        Expanded(
                          child: _CategoryButton(
                            label: 'Sarees',
                            imagePath:
                                'lib/assets/category_grid/sarees_large.png',
                            onTap: () => _goToCollection(context, 'sarees'),
                          ),
                        ),
                        const SizedBox(width: 30),
                        Expanded(
                          child: _CategoryButton(
                            label: 'Dresses',
                            imagePath:
                                'lib/assets/category_grid/dresses_large.png',
                            onTap: () => _goToCollection(context, 'dresses'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        SizedBox(
                          width: tileWidth,
                          child: _CategoryButton(
                            label: 'Home Decor',
                            imagePath:
                                'lib/assets/category_grid/home_decor_large.png',
                            onTap: () => _goToCollection(context, 'home-decor'),
                          ),
                        ),
                        const SizedBox(width: 28),
                        SizedBox(
                          width: tileWidth,
                          child: _CategoryButton(
                            label: 'Sarees',
                            imagePath:
                                'lib/assets/category_grid/sarees_large.png',
                            onTap: () => _goToCollection(context, 'sarees'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: tileWidth,
                      child: _CategoryButton(
                        label: 'Dresses',
                        imagePath: 'lib/assets/category_grid/dresses_large.png',
                        onTap: () => _goToCollection(context, 'dresses'),
                      ),
                    ),
                  ],
                  SizedBox(height: isMobile ? 44 : 50),
                  _ExploreMoreButton(isMobile: isMobile),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isMobile = useCompactLayout(context, breakpoint: 700);
    final wide = MediaQuery.sizeOf(context).width >= 1200;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 1580 : 560),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: isMobile ? 36 : 50,
                  height: 1.05,
                  color: const Color(0xFF1F1E25),
                ),
              ),
              const SizedBox(height: 14),
              const _CategoryDivider(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDivider extends StatelessWidget {
  const _CategoryDivider();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF65421F);

    return Row(
      children: [
        Transform.rotate(
          angle: 0.785398,
          child: const SizedBox(
            width: 5,
            height: 5,
            child: DecoratedBox(decoration: BoxDecoration(color: color)),
          ),
        ),
        const Expanded(child: Divider(color: color, height: 1, thickness: 1)),
        Transform.rotate(
          angle: 0.785398,
          child: const SizedBox(
            width: 5,
            height: 5,
            child: DecoratedBox(decoration: BoxDecoration(color: color)),
          ),
        ),
      ],
    );
  }
}

class _CategoryButton extends StatefulWidget {
  const _CategoryButton({
    required this.label,
    required this.imagePath,
    required this.onTap,
  });

  final String label;
  final String imagePath;
  final VoidCallback onTap;

  @override
  State<_CategoryButton> createState() => _CategoryButtonState();
}

class _CategoryButtonState extends State<_CategoryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isHovered
                  ? const [
                      BoxShadow(
                        color: Color(0x552D1E12),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Image.asset(widget.imagePath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _ExploreMoreButton extends StatelessWidget {
  const _ExploreMoreButton({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isMobile ? 172 : 264,
      height: isMobile ? 44 : 54,
      child: FilledButton(
        onPressed: () => _goToCollection(context),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF9D510F),
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Explore More',
              style: GoogleFonts.blinker(fontSize: isMobile ? 15 : 21),
            ),
            const SizedBox(width: 6),
            Icon(Icons.north_east_rounded, size: isMobile ? 21 : 26),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.titleSize,
    required this.subtitleSize,
    required this.buttonCenter,
    required this.onExplore,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.outerPadding = const EdgeInsets.all(0),
    this.innerPadding = const EdgeInsets.fromLTRB(30, 28, 30, 24),
    this.minHeight,
    this.buttonTextSize = 26,
    this.buttonHorizontalPadding = 20,
    this.buttonVerticalPadding = 10,
    this.buttonIconSize = 40,
  });

  final String title;
  final String subtitle;
  final double titleSize;
  final double subtitleSize;
  final bool buttonCenter;
  final VoidCallback onExplore;
  final BorderRadius borderRadius;
  final EdgeInsets outerPadding;
  final EdgeInsets innerPadding;
  final double? minHeight;
  final double buttonTextSize;
  final double buttonHorizontalPadding;
  final double buttonVerticalPadding;
  final double buttonIconSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: outerPadding,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            constraints: minHeight == null
                ? null
                : BoxConstraints(minHeight: minHeight!),
            decoration: BoxDecoration(
              color: const Color(0xFF8E7A63).withValues(alpha: 0.42),
              borderRadius: borderRadius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Padding(
              padding: innerPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white,
                      fontSize: titleSize,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.blinker(
                      color: Colors.white,
                      fontSize: subtitleSize,
                      height: 1.15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 50),
                  Align(
                    alignment: buttonCenter
                        ? Alignment.center
                        : Alignment.centerRight,
                    child: FilledButton(
                      onPressed: onExplore,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFAA611C),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: buttonHorizontalPadding,
                          vertical: buttonVerticalPadding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '  Explore',
                            style: GoogleFonts.blinker(
                              fontSize: buttonTextSize,
                            ),
                          ),
                          //SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: buttonIconSize,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _goToCollection(BuildContext context, [String? category]) {
  Navigator.pushReplacementNamed(
    context,
    Uri(
      path: '/collections',
      queryParameters: category == null ? null : {'category': category},
    ).toString(),
  );
}
