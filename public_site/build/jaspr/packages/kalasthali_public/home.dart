import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'app.dart';

class HomeContent extends StatelessComponent {
  const HomeContent({super.key});

  @override
  Component build(BuildContext context) => main_(classes: 'home-main', [
    pageHead(
      'Kalasthali By Nisha | Handpainted Clothing',
      'Handpainted clothing crafted with art and individuality.',
      '/',
    ),
    section(classes: 'hero', [
      Component.element(
        tag: 'picture',
        children: [
          source(attributes: {'media': '(max-width: 699px)', 'srcset': '$assets/homepage_art_mobile.webp'}),
          img(src: '$assets/homepage_art_large.webp', alt: 'Handpainted art and clothing by Kalasthali'),
        ],
      ),
      div(classes: 'hero-card', [
        h1([.text('Handpainted Art'), br(), .text('At its finest.')]),
        p([.text('All at your fingertips')]),
        a(href: '/collections', classes: 'hero-explore', [
          .text('Explore'),
          span(attributes: {'aria-hidden': 'true'}, [.text('›')]),
        ]),
      ]),
    ]),
    section(id: 'new-arrivals', classes: 'home-section arrivals-section', [
      sectionTitle('New Arrivals'),
      div(classes: 'carousel-shell', [
        button(
          classes: 'carousel-arrow prev',
          attributes: {'type': 'button', 'aria-label': 'Previous product'},
          [.text('‹')],
        ),
        div(
          id: 'popular-products',
          classes: 'carousel-track',
          attributes: {'aria-live': 'polite'},
          [
            p(classes: 'carousel-loading', [.text('Loading new arrivals...')]),
          ],
        ),
        button(
          classes: 'carousel-arrow next',
          attributes: {'type': 'button', 'aria-label': 'Next product'},
          [.text('›')],
        ),
      ]),
      div(id: 'carousel-dots', classes: 'carousel-dots', []),
    ]),
    section(classes: 'home-section categories-section', [
      sectionTitle('Shop By Category'),
      div(classes: 'category-grid', [
        _category('Home Decor', 'home_decor', 'home-decor'),
        _category('Sarees', 'sarees', 'saree'),
        _category('Dresses', 'dresses', 'dress'),
        _category('Dupatta', 'dupattas', 'dupatta'),
      ]),
      a(href: '/collections', classes: 'explore-more', [
        .text('Explore More'),
        span([.text('↗')]),
      ]),
    ]),
    section(classes: 'home-section about-section', [
      sectionTitle('About'),
      aboutBody(),
    ]),
    section(classes: 'home-section reviews-section', [
      sectionTitle('What Customers Say'),
      div(classes: 'review-grid', [
        _review('DGW', 'Absolutely gorgeous. A true piece of art! It instantly becomes the focal point of any room.'),
        _review(
          'DML',
          'A stunning piece! The deep midnight tones of the petals look so elegant, and when a tea light is lit, the glow against the lotus design is pure magic.',
        ),
        _review('CBS', 'Beautiful hand painting. I liked the work very much. Thank you for the kurta and shirt.'),
      ]),
    ]),
    section(classes: 'home-section contact-section', [contactBody()]),
  ]);
}

Component _category(String title, String asset, String filter) =>
    a(href: '/collections?category=$filter', classes: 'category-card', [
      Component.element(
        tag: 'picture',
        children: [
          source(attributes: {'media': '(max-width: 699px)', 'srcset': '$assets/category_grid/${asset}_small.png'}),
          img(src: '$assets/category_grid/${asset}_large.png', alt: title),
        ],
      ),
      span([.text(title.toUpperCase())]),
    ]);

Component _review(String code, String copy) => article(classes: 'review-card', [
  img(src: '$storage/$code/thumbnail.webp', alt: 'Kalasthali product $code'),
  div(classes: 'review-copy', [
    div(classes: 'review-stars', attributes: {'aria-label': 'Five out of five stars'}, [.text('★★★★★')]),
    p([.text('"$copy"')]),
  ]),
]);
