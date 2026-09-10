import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../models/site_policy.dart';

class AdminGalleryImage {
  const AdminGalleryImage({
    required this.name,
    required this.url,
    required this.sourceUrl,
    required this.isThumbnail,
  });

  final String name;
  final String url;
  final String sourceUrl;
  final bool isThumbnail;

  factory AdminGalleryImage.fromJson(Map<String, dynamic> json) =>
      AdminGalleryImage(
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
        sourceUrl:
            (json['sourceUrl'] as String?) ?? (json['url'] as String?) ?? '',
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

class _ImageUploadTicket {
  const _ImageUploadTicket({required this.path, required this.uploadUrl});

  final String path;
  final String uploadUrl;

  factory _ImageUploadTicket.fromJson(Map<String, dynamic> json) =>
      _ImageUploadTicket(
        path: json['path'] as String? ?? '',
        uploadUrl: json['uploadUrl'] as String? ?? '',
      );
}

class AdminService {
  AdminService._();

  static final instance = AdminService._();
  static const maxImageBytes = 10 * 1024 * 1024;

  Uri _uri(String action, [Map<String, String>? query]) => Uri.base.replace(
    path: '/api/admin',
    queryParameters: {'action': action, ...?query},
  );

  Map<String, String> get _headers {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw const AdminException('Log in with an authorized admin account.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

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

  Future<List<SitePolicy>> getPolicies() async {
    final response = await http.get(_uri('policies'), headers: _headers);
    final data = _decode(response);
    if (data is! List<dynamic>) throw AdminException('Invalid policies data.');
    return data
        .whereType<Map<String, dynamic>>()
        .map(SitePolicy.fromJson)
        .toList();
  }

  Future<SitePolicy> updatePolicy(SitePolicy policy) async {
    final response = await http.put(
      _uri('policy'),
      headers: _headers,
      body: jsonEncode({'policy': policy.toJson()}),
    );
    return SitePolicy.fromJson(_decode(response) as Map<String, dynamic>);
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

  Future<AdminGallery> uploadImage(String code, List<int> bytes) async {
    if (bytes.isEmpty || bytes.length > maxImageBytes) {
      throw const AdminException(
        'Converted WebP images must be smaller than 10 MB.',
      );
    }
    final response = await http.post(
      _uri('image_upload_ticket'),
      headers: _headers,
      body: jsonEncode({'code': code, 'byteLength': bytes.length}),
    );
    final ticket = _ImageUploadTicket.fromJson(
      _decode(response) as Map<String, dynamic>,
    );
    if (ticket.path.isEmpty || ticket.uploadUrl.isEmpty) {
      throw const AdminException('Could not prepare the image upload.');
    }

    final upload = await http.put(
      Uri.parse(ticket.uploadUrl),
      headers: const {'Content-Type': 'image/webp'},
      body: bytes,
    );
    if (upload.statusCode < 200 || upload.statusCode >= 300) {
      throw AdminException(_uploadError(upload));
    }

    final galleries = await getGallery();
    return galleries.where((gallery) => gallery.code == code).firstOrNull ??
        (throw const AdminException(
          'The image uploaded, but its gallery could not be refreshed.',
        ));
  }

  String _uploadError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
    } on FormatException {
      // Storage can return an empty or non-JSON error response.
    }
    return 'Supabase could not upload the image.';
  }

  Future<AdminGallery> setThumbnail(String code, String name) async {
    final response = await http.post(
      _uri('image_thumbnail'),
      headers: _headers,
      body: jsonEncode({'code': code, 'name': name}),
    );
    return AdminGallery.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<AdminGallery> deleteImage(String code, String name) async {
    final response = await http.delete(
      _uri('image_delete'),
      headers: _headers,
      body: jsonEncode({'code': code, 'name': name}),
    );
    return AdminGallery.fromJson(_decode(response) as Map<String, dynamic>);
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
