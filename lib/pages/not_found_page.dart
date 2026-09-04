import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/services/seo_service.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_scaffold.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    SeoService.setPage(
      title: 'Page Not Found | Kalasthali By Nisha',
      description: 'The page you requested could not be found.',
      path: '/404',
    );

    return AppScaffold(
      title: 'Page not found',
      currentRoute: '/404',
      centerBody: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      mobile ? 24 : 54,
                      mobile ? 74 : 110,
                      mobile ? 24 : 54,
                      mobile ? 92 : 140,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: _NotFoundContent(mobile: mobile),
                      ),
                    ),
                  ),
                  const AppFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotFoundContent extends StatelessWidget {
  const _NotFoundContent({required this.mobile});

  final bool mobile;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        '404',
        style: GoogleFonts.dmSerifDisplay(
          fontSize: mobile ? 112 : 170,
          height: .85,
          letterSpacing: 4,
          color: const Color(0xFFA35710),
        ),
      ),
      const SizedBox(height: 28),
      Container(
        height: 1,
        width: mobile ? 170 : 250,
        color: const Color(0xFF9A8267),
      ),
      const SizedBox(height: 28),
      Text(
        'This piece is not in the collection.',
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSerifDisplay(
          fontSize: mobile ? 30 : 42,
          height: 1.05,
          color: const Color(0xFF5B351A),
        ),
      ),
      const SizedBox(height: 16),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Text(
          'The link may have changed, or this page may no longer be available. Let us guide you back to the handcrafted collection.',
          textAlign: TextAlign.center,
          style: GoogleFonts.blinker(
            fontSize: mobile ? 18 : 20,
            height: 1.35,
            color: const Color(0xFF4E463E),
          ),
        ),
      ),
      const SizedBox(height: 36),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 14,
        children: [
          FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA35710),
              minimumSize: const Size(180, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Back to home',
              style: GoogleFonts.blinker(fontSize: 18),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/collections', (route) => false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFA35710),
              side: const BorderSide(color: Color(0xFFA35710), width: 1.5),
              minimumSize: const Size(180, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'View collection',
              style: GoogleFonts.blinker(fontSize: 18),
            ),
          ),
        ],
      ),
    ],
  );
}
