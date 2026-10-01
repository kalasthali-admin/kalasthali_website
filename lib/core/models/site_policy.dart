class SitePolicy {
  const SitePolicy({
    required this.slug,
    required this.title,
    required this.content,
    this.updatedAt,
  });

  final String slug;
  final String title;
  final String content;
  final DateTime? updatedAt;

  factory SitePolicy.fromJson(Map<String, dynamic> json) => SitePolicy(
    slug: json['slug'] as String? ?? '',
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
  );

  Map<String, String> toJson() => {
    'slug': slug,
    'title': title,
    'content': content,
  };
}

const defaultPolicies = <String, SitePolicy>{
  'privacy-policy': SitePolicy(
    slug: 'privacy-policy',
    title: 'Privacy Policy',
    content:
        '''Kalasthali By Nisha respects your privacy and is committed to handling your personal information responsibly.

Information we collect
When you create an account or place an order, we may collect your name, email address, phone number, delivery address, order details, and payment-related references. Payment card information is processed by our payment provider and is not stored by Kalasthali By Nisha.

How we use information
We use this information to process orders, arrange delivery, provide customer support, prevent fraud, and send service-related communications such as order confirmations and receipts.

Sharing information
We share information only when necessary to operate our store, including with payment providers, delivery partners, and technology providers. We do not sell personal information.

Data security and retention
We use reasonable safeguards to protect information. We retain order and account information for as long as needed to provide our services, meet legal obligations, resolve disputes, and enforce agreements.

Your choices
You may request access to, correction of, or deletion of your personal information, subject to applicable legal requirements. Contact us using the details published on our website.

Updates to this policy
We may update this Privacy Policy from time to time. The latest version will always be available on this page.''',
  ),
  'terms-of-service': SitePolicy(
    slug: 'terms-of-service',
    title: 'Terms of Service',
    content:
        '''Welcome to Kalasthali By Nisha. By using this website or placing an order, you agree to these Terms of Service.

Orders and availability
All orders are subject to acceptance and product availability. Product images, colours, dimensions, and descriptions are presented as accurately as possible, but minor variations may occur because products are handcrafted and screen displays vary.

Pricing and payment
Prices are shown in Indian Rupees unless stated otherwise. We may correct pricing or listing errors before accepting an order. Payment must be successfully completed through the available payment method before an order is confirmed.

Delivery
You are responsible for providing accurate delivery information. Delivery estimates are indicative and may change due to courier availability, weather, holidays, or other circumstances outside our control.

Acceptable use
You must not misuse this website, interfere with its operation, attempt unauthorized access, or use it for fraudulent or unlawful activity.

Intellectual property
Website content, product imagery, branding, and designs belong to Kalasthali By Nisha or its licensors and may not be copied or used without permission.

Changes and contact
We may update these Terms at any time. Questions about these Terms can be sent through the contact details listed on our website.''',
  ),
  'refund-policy': SitePolicy(
    slug: 'refund-policy',
    title: 'Refund Policy',
    content:
        '''We want you to be satisfied with your Kalasthali By Nisha purchase. Please read this policy before placing an order.

Return and refund eligibility
To request support for a damaged, incorrect, or incomplete order, contact us promptly after delivery with your order ID and clear photographs of the item and packaging. Requests are reviewed on a case-by-case basis.

Non-returnable items
Items that are worn, altered, washed, damaged after delivery, or returned without approval may not be eligible for a refund or exchange. Colour variations caused by photography or screen settings are not normally treated as defects.

Approved refunds
If a refund is approved, it will be issued to the original payment method where possible. Processing times depend on your bank or payment provider.

Order cancellation
Cancellation requests can be made before an order has been dispatched. We cannot guarantee cancellation once processing or dispatch has begun.

Contact us
For assistance, use the contact details published on our website and include your order ID in your message.''',
  ),
};

SitePolicy policyForSlug(String slug) => defaultPolicies[slug]!;
