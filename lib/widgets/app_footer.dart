import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  static const _background = Color(0xFFD6C0AA);

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    final compactMobile = mobile && MediaQuery.sizeOf(context).width < 360;
    final logoWidth = compactMobile ? 130.0 : (mobile ? 164.0 : 292.0);
    final iconSize = compactMobile ? 28.0 : (mobile ? 34.0 : 50.0);
    final iconGap = mobile ? 8.0 : 24.0;
    final horizontalPadding = mobile ? 20.0 : 34.0;

    return Container(
      width: double.infinity,
      color: _background,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: mobile ? 28 : 34,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'lib/assets/footer_icons/text.png',
                width: logoWidth,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const Spacer(),
              _FooterLink(
                label: 'Instagram',
                imagePath: 'lib/assets/footer_icons/instagram.png',
                url: _instagramUrl,
                size: iconSize,
              ),
              SizedBox(width: iconGap),
              _FooterLink(
                label: 'Facebook',
                imagePath: 'lib/assets/footer_icons/facebook.png',
                url: _facebookUrl,
                size: iconSize,
              ),
              SizedBox(width: iconGap),
              _FooterLink(
                label: 'Amazon',
                imagePath: 'lib/assets/footer_icons/amazon.png',
                url: _amazonUrl,
                size: iconSize,
              ),
              SizedBox(width: iconGap),
              _FooterLink(
                label: 'Myntra',
                imagePath: 'lib/assets/footer_icons/myntra.png',
                url: _myntraUrl,
                size: iconSize,
              ),
            ],
          ),
          SizedBox(height: mobile ? 22 : 30),
          Text(
            'Copyright © ${DateTime.now().year} Kalasthali By Nisha',
            style: TextStyle(
              color: const Color(0xFF4E3827),
              fontSize: mobile ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.label,
    required this.imagePath,
    required this.url,
    required this.size,
  });

  final String label;
  final String imagePath;
  final String url;
  final double size;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label link has not been configured yet.')),
      );
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $label.')));
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Open Kalasthali on $label',
    child: Tooltip(
      message: label,
      child: InkResponse(
        radius: size / 2 + 8,
        onTap: () => _open(context),
        child: Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    ),
  );
}

const _instagramUrl = String.fromEnvironment('INSTAGRAM_URL');
const _facebookUrl = String.fromEnvironment('FACEBOOK_URL');
const _amazonUrl = String.fromEnvironment('AMAZON_URL');
const _myntraUrl = String.fromEnvironment('MYNTRA_URL');
