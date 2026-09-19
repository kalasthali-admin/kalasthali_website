import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/responsive.dart';
import '../widgets/app_scaffold.dart';
import '../core/services/seo_service.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    SeoService.setPage(
      title: 'About Kalasthali | Handpainted Indian Art',
      description:
          'Discover Kalasthali By Nisha, celebrating handmade, hand-painted Indian art, heritage techniques, and contemporary living.',
      path: '/about',
    );
    return const AppScaffold(
      title: 'About',
      currentRoute: '/about',
      centerBody: false,
      body: _AboutRouteContent(),
    );
  }
}

class _AboutRouteContent extends StatelessWidget {
  const _AboutRouteContent();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = useCompactLayout(context, breakpoint: 700);
      final viewport = MediaQuery.sizeOf(context);
      final stacked =
          mobile || (viewport.height > viewport.width && viewport.width < 1100);
      final copy = Text(
        'Over time, the true essence of handmade and hand-painted has slowly been lost. Kalasthali is an attempt to bring it back - by celebrating traditional art forms, forgotten techniques, and the beauty of creating by hand.\n\nInspired by nature, Pichwai, Lippan, textured art, and other traditional Indian crafts, Kalasthali creates home decor and wearable art that blends heritage with contemporary aesthetics. Our pieces are designed to fit effortlessly into modern lifestyles while preserving the charm, character and soul of our artistic heritage.\n\nBecause for us, handmade is more than a technique - it is a way of keeping art and history alive.\n\nKalasthali - where heritage meets contemporary living.',
        style: GoogleFonts.ibmPlexSans(
          fontSize: mobile ? 18 : (stacked ? 22 : 25),
          height: 1.22,
          color: Colors.black,
        ),
      );
      final portrait = Semantics(
        image: true,
        label: 'Nisha Rohilla, owner of Kalasthali',
        child: Image.asset('lib/assets/about_pfp.png', fit: BoxFit.contain),
      );
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          mobile ? 28 : (stacked ? 42 : 38),
          mobile ? 56 : 92,
          mobile ? 28 : (stacked ? 42 : 38),
          mobile ? 88 : 120,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1580),
            child: stacked
                ? Column(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: mobile ? 390 : 460,
                        ),
                        child: portrait,
                      ),
                      SizedBox(height: mobile ? 42 : 56),
                      copy,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 6, child: copy),
                      const SizedBox(width: 76),
                      Expanded(flex: 4, child: portrait),
                    ],
                  ),
          ),
        ),
      );
    },
  );
}
