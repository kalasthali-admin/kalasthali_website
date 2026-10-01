class ProductReview {
  const ProductReview({
    required this.id,
    required this.productCode,
    required this.reviewerName,
    required this.rating,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String productCode;
  final String reviewerName;
  final int rating;
  final String text;
  final DateTime? createdAt;

  factory ProductReview.fromJson(Map<String, dynamic> json) => ProductReview(
    id: (json['id'] ?? '').toString(),
    productCode: (json['product_code'] ?? '').toString(),
    reviewerName: (json['reviewer_name'] ?? 'Customer').toString(),
    rating: ((json['rating'] as num?)?.toInt() ?? 0).clamp(1, 5),
    text: (json['review_text'] ?? '').toString(),
    createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
  );
}
