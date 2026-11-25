import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'policies.dart';
import 'home.dart';

const assets = '/assets/lib/assets';
const storage = 'https://dddriininznavwrsrgww.supabase.co/storage/v1/object/public/product_images';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) => div(classes: 'site-shell', [
    const SiteHeader(),
    Router(
      routes: [
        Route(path: '/', builder: (_, _) => const HomeContent()),
        Route(path: '/about', builder: (_, _) => const AboutContent()),
        Route(path: '/contact', builder: (_, _) => const ContactContent()),
        for (final slug in defaultPolicies.keys)
          Route(
            path: '/$slug',
            builder: (_, _) => PolicyContent(slug: slug),
          ),
        Route(path: '/404', builder: (_, _) => const NotFoundContent()),
      ],
    ),
    const SiteFooter(),
  ]);
}

Component pageHead(String title, String description, String path, {bool noIndex = false}) => Document.head(
  title: title,
  meta: {
    'description': description,
    'robots': noIndex ? 'noindex, follow' : 'index, follow',
  },
  children: [
    link(rel: 'canonical', href: 'https://kalasthali.co$path'),
    for (final (property, content) in [
      ('og:title', title),
      ('og:description', description),
      ('og:url', 'https://kalasthali.co$path'),
      ('og:image', 'https://kalasthali.co/assets/lib/assets/icon_logo.png'),
    ])
      Component.element(tag: 'meta', attributes: {'property': property, 'content': content}),
  ],
);

Component siteIcon(String path) => Component.element(
  tag: 'svg',
  attributes: {
    'viewBox': '0 0 24 24',
    'fill': 'none',
    'stroke': 'currentColor',
    'stroke-width': '2',
    'stroke-linecap': 'round',
    'stroke-linejoin': 'round',
    'aria-hidden': 'true',
  },
  children: [Component.element(tag: 'path', attributes: {'d': path})],
);

class SiteHeader extends StatelessComponent {
  const SiteHeader({super.key});

  @override
  Component build(BuildContext context) => header(classes: 'site-header', [
    a(href: '/', classes: 'brand-link', [
      img(src: '$assets/logo_text.png', alt: 'Kalasthali By Nisha'),
    ]),
    nav(
      classes: 'desktop-nav',
      attributes: {'aria-label': 'Main navigation'},
      [
        a(href: '/', classes: 'home-nav', [.text('HOME')]),
        a(href: '/#new-arrivals', [.text('NEW ARRIVALS')]),
        a(href: '/collections', [.text('COLLECTIONS')]),
      ],
    ),
    form(
      classes: 'header-search',
      action: '/collections',
      attributes: {'hidden': ''},
      [
        input<String>(
          name: 'search',
          attributes: {'type': 'search', 'placeholder': 'SEARCH FOR PRODUCTS', 'aria-label': 'Search for products'},
        ),
      ],
    ),
    div(classes: 'header-actions', [
      button(
        classes: 'header-control search-control',
        attributes: {'type': 'button', 'aria-label': 'Search products'},
        [siteIcon('M21 21l-4.35-4.35 M19 11a8 8 0 1 1-16 0 8 8 0 0 1 16 0z')],
      ),
      a(href: '/admin', classes: 'header-control admin-control', attributes: {'hidden': ''}, [.text('ADMIN')]),
      a(href: '/cart', classes: 'header-control cart-control', attributes: {'aria-label': 'Cart'}, [
        siteIcon('M2 3h2l2.4 11.4a2 2 0 0 0 2 1.6H19a2 2 0 0 0 2-1.6L22 7H5 M9 21h.01 M18 21h.01'),
      ]),
      a(href: '/account', classes: 'header-control account-control', [
        span(classes: 'account-icon', [siteIcon('M20 21a8 8 0 0 0-16 0 M12 13a5 5 0 1 0 0-10 5 5 0 0 0 0 10z')]),
        span(classes: 'account-label', [.text('LOG IN')]),
      ]),
    ]),
    button(
      classes: 'menu-toggle',
      attributes: {
        'type': 'button',
        'aria-label': 'Open menu',
        'aria-expanded': 'false',
        'aria-controls': 'mobile-menu',
      },
      [siteIcon('M4 6h16 M4 12h16 M4 18h16')],
    ),
    nav(
      id: 'mobile-menu',
      classes: 'mobile-menu',
      attributes: {'aria-label': 'Mobile navigation', 'hidden': ''},
      [
        a(href: '/', [.text('HOME')]),
        a(href: '/#new-arrivals', [.text('NEW ARRIVALS')]),
        a(href: '/collections', [.text('COLLECTIONS')]),
        a(href: '/cart', [.text('CART')]),
        a(href: '/account', classes: 'mobile-account', [.text('LOG IN / SIGN UP')]),
        a(href: '/admin', classes: 'mobile-admin', attributes: {'hidden': ''}, [.text('ADMIN')]),
      ],
    ),
  ]);
}

Component sectionTitle(String title) => div(classes: 'section-title', [
  h2([.text(title)]),
  div(classes: 'ornament-rule', []),
]);

class SiteFooter extends StatelessComponent {
  const SiteFooter({super.key});

  @override
  Component build(BuildContext context) => footer(classes: 'site-footer', [
    div(classes: 'footer-top', [
      img(src: '$assets/footer_icons/text.png', alt: 'Kalasthali By Nisha', classes: 'footer-logo'),
      div(classes: 'social-links', [
        for (final (label, icon, key) in [
          ('Instagram', 'instagram', 'INSTAGRAM_URL'),
          ('Facebook', 'facebook', 'FACEBOOK_URL'),
          ('Amazon', 'amazon', 'AMAZON_URL'),
          ('Myntra', 'myntra', 'MYNTRA_URL'),
        ])
          a(
            href: '#',
            classes: 'social-link',
            attributes: {'data-social-key': key, 'aria-label': label},
            [
              img(src: '$assets/footer_icons/$icon.png', alt: label),
            ],
          ),
      ]),
    ]),
    nav(
      classes: 'footer-nav',
      attributes: {'aria-label': 'Footer'},
      [
        a(href: '/about', [.text('ABOUT')]),
        a(href: '/collections', [.text('COLLECTIONS')]),
        a(href: '/privacy-policy', [.text('PRIVACY POLICY')]),
        a(href: '/terms-of-service', [.text('TERMS OF SERVICE')]),
        a(href: '/refund-policy', [.text('REFUND POLICY')]),
      ],
    ),
    p([.text('Copyright © ${DateTime.now().year} Kalasthali By Nisha')]),
  ]);
}

class AboutContent extends StatelessComponent {
  const AboutContent({super.key});

  @override
  Component build(BuildContext context) => main_(classes: 'about-page', [
    pageHead(
      'About Kalasthali | Handpainted Indian Art',
      'Discover Kalasthali By Nisha, celebrating handmade, hand-painted Indian art, heritage techniques, and contemporary living.',
      '/about',
    ),
    aboutBody(),
  ]);
}

const aboutCopy =
    'Over time, the true essence of handmade and hand-painted has slowly been lost. Kalasthali is an attempt to bring it back - by celebrating traditional art forms, forgotten techniques, and the beauty of creating by hand.\n\nInspired by nature, Pichwai, Lippan, textured art, and other traditional Indian crafts, Kalasthali creates home decor and wearable art that blends heritage with contemporary aesthetics. Our pieces are designed to fit effortlessly into modern lifestyles while preserving the charm, character and soul of our artistic heritage.\n\nBecause for us, handmade is more than a technique - it is a way of keeping art and history alive.\n\nKalasthali - where heritage meets contemporary living.';

Component aboutBody() => div(classes: 'about-body', [
  p(classes: 'about-copy', [.text(aboutCopy)]),
  img(src: '$assets/about_pfp.png', alt: 'Nisha Rohilla, owner of Kalasthali'),
]);

class ContactContent extends StatelessComponent {
  const ContactContent({super.key});

  @override
  Component build(BuildContext context) => main_(classes: 'contact-page', [
    pageHead(
      'Contact Kalasthali | Get In Touch',
      'Contact Kalasthali By Nisha about products, partnerships and business.',
      '/contact',
    ),
    contactBody(),
  ]);
}

Component contactBody() => div(classes: 'contact-body', [
  sectionTitle('Get In Touch'),
  p(classes: 'contact-intro', [
    .text('For queries regarding products, partnerships and business, contact us'),
  ]),
  div(classes: 'contact-cards', [
    a(href: 'mailto:kalasthali@gmail.com', classes: 'contact-card', [
      span(classes: 'contact-icon', attributes: {'aria-hidden': 'true'}, [
        siteIcon('M3 5h18v14H3z M3 6l9 7 9-7'),
      ]),
      span([
        strong([.text('Email')]),
        .text('kalasthali@gmail.com'),
      ]),
    ]),
    a(href: 'https://wa.me/919530324000', classes: 'contact-card', [
      span(classes: 'contact-icon', attributes: {'aria-hidden': 'true'}, [
        siteIcon('M4 4h16v12H8l-4 4V4z M8 8h8 M8 12h6'),
      ]),
      span([
        strong([.text('Call or WhatsApp')]),
        .text('+91 95303 24000'),
      ]),
    ]),
  ]),
]);

class PolicyContent extends StatelessComponent {
  const PolicyContent({required this.slug, super.key});
  final String slug;

  @override
  Component build(BuildContext context) {
    final policy = policyForSlug(slug);
    return main_(classes: 'policy-page', [
      pageHead('${policy.title} | Kalasthali By Nisha', '${policy.title} for Kalasthali By Nisha.', '/$slug'),
      article(
        classes: 'policy-card',
        attributes: {'data-policy-slug': slug},
        [
          h1(classes: 'policy-title', [.text(policy.title)]),
          p(classes: 'policy-date', [
            .text('Last updated: '),
            span(id: 'policy-updated', [.text('${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}')]),
          ]),
          hr(),
          div(id: 'policy-content', classes: 'policy-content', [
            for (final section in policy.content.trim().split('\n\n')) p([.text(section)]),
          ]),
        ],
      ),
    ]);
  }
}

class NotFoundContent extends StatelessComponent {
  const NotFoundContent({super.key});

  @override
  Component build(BuildContext context) => main_(classes: 'not-found-page', [
    pageHead(
      'Page Not Found | Kalasthali By Nisha',
      'The page you requested could not be found.',
      '/404',
      noIndex: true,
    ),
    h1([.text('404')]),
    div(classes: 'not-found-rule', []),
    h2([.text('This piece is not in the collection.')]),
    p([
      .text(
        'The link may have changed, or this page may no longer be available. Let us guide you back to the handcrafted collection.',
      ),
    ]),
    div(classes: 'not-found-actions', [
      a(href: '/', classes: 'primary-action', [.text('Back to home')]),
      a(href: '/collections', classes: 'secondary-action', [.text('View collection')]),
    ]),
  ]);
}
