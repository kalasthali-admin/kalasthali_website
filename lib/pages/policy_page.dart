import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/site_policy.dart';
import '../core/responsive.dart';
import '../core/services/policy_service.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_scaffold.dart';

class PolicyPage extends StatelessWidget {
  const PolicyPage({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final fallback = policyForSlug(slug);
    return AppScaffold(
      title: fallback.title,
      currentRoute: '/$slug',
      centerBody: false,
      body: FutureBuilder<SitePolicy>(
        future: PolicyService.instance.getPolicy(slug),
        builder: (context, snapshot) {
          final policy = snapshot.data ?? fallback;
          final mobile = useCompactLayout(context, breakpoint: 700);
          return CustomScrollView(
            primary: true,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    mobile ? 22 : 48,
                    mobile ? 52 : 82,
                    mobile ? 22 : 48,
                    mobile ? 64 : 96,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: Container(
                        padding: EdgeInsets.all(mobile ? 24 : 46),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF5E6),
                          border: Border.all(color: const Color(0xFFD5B48A)),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x242D1E12),
                              blurRadius: 22,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              policy.title,
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: mobile ? 38 : 52,
                                color: const Color(0xFF5B351A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Last updated: ${_lastUpdated(policy.updatedAt)}',
                              style: GoogleFonts.blinker(
                                color: const Color(0xFF765F4B),
                                fontSize: mobile ? 15 : 17,
                              ),
                            ),
                            const SizedBox(height: 28),
                            const Divider(color: Color(0xFFD5B48A)),
                            const SizedBox(height: 24),
                            for (final section in policy.content.trim().split(
                              '\n\n',
                            )) ...[
                              Text(
                                section,
                                style: GoogleFonts.blinker(
                                  fontSize: mobile ? 17 : 19,
                                  height: 1.45,
                                  color: const Color(0xFF332A25),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
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

String _lastUpdated(DateTime? value) {
  final date = value ?? DateTime.now();
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
