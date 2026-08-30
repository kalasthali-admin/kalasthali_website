import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class AdminGalleryImage {
  const AdminGalleryImage({
    required this.name,
    required this.url,
    required this.isThumbnail,
  });

  final String name;
  final String url;
  final bool isThumbnail;

  factory AdminGalleryImage.fromJson(Map<String, dynamic> json) =>
      AdminGalleryImage(
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
        isThumbnail: json['isThumbnail'] as bool? ?? false,
      );
}

class AdminGallery {
  const AdminGallery({required this.code, required this.images});

  final String code;
  final List<AdminGalleryImage> images;

  factory AdminGallery.fromJson(Map<String, dynamic> json) => AdminGallery(
    code: json['code'] as String? ?? '',
    images: (json['images'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AdminGalleryImage.fromJson)
        .toList(),
  );
}

class AdminService {
  AdminService._();

  static final instance = AdminService._();
  static const isTestMode = bool.fromEnvironment('ADMIN_TEST_MODE');
  String? _token;

  bool get isAuthenticated => _token != null;

  Uri _uri(String action, [Map<String, String>? query]) => Uri.base.replace(
    path: '/api/admin',
    queryParameters: {'action': action, ...?query},
  );

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<void> login(String password) async {
    final response = await http.post(
      _uri('login'),
      headers: _headers,
      body: jsonEncode({'password': password}),
    );
    final data = _decode(response);
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw AdminException('Could not start the admin session.');
    }
    _token = token;
  }

  void signOut() => _token = null;

  Future<List<Product>> getProducts() async {
    final response = await http.get(_uri('products'), headers: _headers);
    final data = _decode(response);
    if (data is! List<dynamic>) throw AdminException('Invalid products data.');
    return data
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  Future<List<AdminGallery>> getGallery() async {
    final response = await http.get(_uri('gallery'), headers: _headers);
    final data = _decode(response);
    if (data is! List<dynamic>) throw AdminException('Invalid gallery data.');
    return data
        .whereType<Map<String, dynamic>>()
        .map(AdminGallery.fromJson)
        .toList();
  }

  Future<Product> create(Map<String, dynamic> product) async {
    final response = await http.post(
      _uri('create'),
      headers: _headers,
      body: jsonEncode({'product': product}),
    );
    final data = _decode(response);
    return Product.fromJson(data);
  }

  Future<Product> update(String code, Map<String, dynamic> product) async {
    final response = await http.patch(
      _uri('update'),
      headers: _headers,
      body: jsonEncode({'code': code, 'product': product}),
    );
    final data = _decode(response);
    return Product.fromJson(data);
  }

  Future<void> delete(String code) async {
    final response = await http.delete(
      _uri('delete', {'code': code}),
      headers: _headers,
    );
    if (response.statusCode >= 400) _decode(response);
  }

  Future<void> uploadImage(String code, List<int> bytes) async {
    final response = await http.post(
      _uri('image_upload'),
      headers: _headers,
      body: jsonEncode({'code': code, 'imageBase64': base64Encode(bytes)}),
    );
    _decode(response);
  }

  Future<void> setThumbnail(String code, String name) async {
    final response = await http.post(
      _uri('image_thumbnail'),
      headers: _headers,
      body: jsonEncode({'code': code, 'name': name}),
    );
    _decode(response);
  }

  Future<void> deleteImage(String code, String name) async {
    final response = await http.delete(
      _uri('image_delete'),
      headers: _headers,
      body: jsonEncode({'code': code, 'name': name}),
    );
    if (response.statusCode >= 400) _decode(response);
  }

  dynamic _decode(http.Response response) {
    dynamic data;
    try {
      data = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      throw AdminException('The admin server returned an invalid response.');
    }
    if (response.statusCode >= 400) {
      final message = data is Map<String, dynamic>
          ? data['error'] as String?
          : null;
      if (response.statusCode == 401) _token = null;
      throw AdminException(message ?? 'Admin request failed.');
    }
    return data;
  }
}

class AdminException implements Exception {
  const AdminException(this.message);
  final String message;

  @override
  String toString() => message;
}
