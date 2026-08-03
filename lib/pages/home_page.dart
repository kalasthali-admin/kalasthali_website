import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/popular_products_carousel.dart';
import '../widgets/app_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Home',
      currentRoute: '/home',
      centerBody: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 0 : 28,
                isMobile ? 0 : 30,
                isMobile ? 0 : 28,
                isMobile ? 0 : 40,
              ),
              child: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1600),
                      child: isMobile
                          ? const _MobileHero()
                          : const _DesktopHero(),
                    ),
                  ),
                  SizedBox(height: 100),
                  PopularProductsCarousel(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DesktopHero extends StatelessWidget {
  const _DesktopHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isTablet = width < 1100;
          final cardWidth = isTablet ? width * 0.44 : width * 0.43;
          final leftOffset = isTablet ? 28.0 : 42.0;
          final bottomOffset = isTablet ? 40.0 : 82.0;
          final titleSize = isTablet ? 32.0 : 42.0;
          final subtitleSize = isTablet ? 16.0 : 20.0;
          final innerPadding = isTablet
              ? const EdgeInsets.fromLTRB(22, 20, 22, 20)
              : const EdgeInsets.fromLTRB(30, 28, 30, 24);
          final minimumHeight = isTablet ? 180.0 : null;

          return Stack(
            children: [
              AspectRatio(
                aspectRatio: 1829 / 852,
                child: Image.asset(
                  'lib/assets/homepage_art_large.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                left: leftOffset,
                bottom: bottomOffset,
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
          );
        },
      ),
    );
  }
}

class _MobileHero extends StatelessWidget {
  const _MobileHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 393 / 852,
          child: Image.asset(
            'lib/assets/homepage_art_mobile.png',
            fit: BoxFit.cover,
            width: double.infinity,
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
            subtitleSize: 18,
            buttonCenter: true,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            outerPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            innerPadding: const EdgeInsets.fromLTRB(24, 26, 24, 36),
            minHeight: 450,
            onExplore: () => _goToCollection(context),
          ),
        ),
      ],
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
    this.buttonHorizontalPadding = 22,
    this.buttonVerticalPadding = 18,
    this.buttonIconSize = 24,
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: subtitleSize,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
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
                        children: [
                          Text(
                            'Explore',
                            style: GoogleFonts.blinker(
                              fontSize: buttonTextSize,
                            ),
                          ),
                          SizedBox(width: 10),
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

void _goToCollection(BuildContext context) {
  Navigator.pushReplacementNamed(context, '/collection');
}
