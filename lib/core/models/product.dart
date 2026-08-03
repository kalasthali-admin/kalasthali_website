class Product {
  final String code;
  final String type;
  final String name;
  final String description;
  final String? specifications;
  final String? sizes;
  final String? price;
  final bool? isPopular;

  Product({
    required this.code,
    required this.type,
    required this.name,
    required this.description,
    this.specifications,
    this.sizes,
    this.price,
    this.isPopular,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      specifications: json['specifications'] as String?,
      sizes: json['sizes'] as String?,
      price: json['price'] as String?,
      isPopular: json['is_popular'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'type': type,
    'name': name,
    'description': description,
    'specifications': specifications,
    'sizes': sizes,
    'price': price,
    'is_popular': isPopular,
  };
}
