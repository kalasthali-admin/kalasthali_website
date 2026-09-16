import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderServiceException implements Exception {
  const OrderServiceException(this.message);
  final String message;
}

class _ReturnUploadTicket {
  const _ReturnUploadTicket({required this.path, required this.uploadUrl});
  final String path;
  final String uploadUrl;

  factory _ReturnUploadTicket.fromJson(Map<String, dynamic> json) =>
      _ReturnUploadTicket(
        path: (json['path'] ?? '').toString(),
        uploadUrl: (json['uploadUrl'] ?? '').toString(),
      );
}

class OrderService {
  OrderService._();
  static final instance = OrderService._();

  Uri _uri(String action) => Uri.base.replace(
    path: '/api/orders',
    queryParameters: {'action': action},
  );

  Future<Map<String, String>> _headers({bool refresh = false}) async {
    final auth = Supabase.instance.client.auth;
    if (refresh) await auth.refreshSession();
    final token = auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw const OrderServiceException('Please log in to manage this order.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _post(String action, Map<String, dynamic> body) async {
    Future<http.Response> send(bool refresh) async => http.post(
      _uri(action),
      headers: await _headers(refresh: refresh),
      body: jsonEncode(body),
    );
    final response = await send(false);
    return response.statusCode == 401 ? send(true) : response;
  }

  dynamic _decode(http.Response response) {
    dynamic data;
    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      throw const OrderServiceException(
        'The order service returned an invalid response.',
      );
    }
    if (response.statusCode >= 400) {
      throw OrderServiceException(
        data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Could not update this order.',
      );
    }
    return data;
  }

  Future<void> cancelOrder(String orderId) async {
    _decode(await _post('cancel', {'orderId': orderId}));
  }

  Future<void> requestReturn(
    String orderId,
    List<ReturnImageUpload> images,
  ) async {
    if (images.isEmpty) {
      throw const OrderServiceException(
        'Add at least one image of the received product.',
      );
    }
    final evidence = <String>[];
    for (final image in images) {
      final ticketData = _decode(
        await _post('return_upload_ticket', {
          'orderId': orderId,
          'byteLength': image.bytes.length,
          'contentType': image.contentType,
        }),
      );
      final ticket = _ReturnUploadTicket.fromJson(
        ticketData as Map<String, dynamic>,
      );
      if (ticket.path.isEmpty || ticket.uploadUrl.isEmpty) {
        throw const OrderServiceException(
          'Could not prepare a return image upload.',
        );
      }
      final uploaded = await http.put(
        Uri.parse(ticket.uploadUrl),
        headers: {'Content-Type': image.contentType},
        body: image.bytes,
      );
      if (uploaded.statusCode < 200 || uploaded.statusCode >= 300) {
        throw const OrderServiceException(
          'Could not upload a return image. Please try again.',
        );
      }
      evidence.add(ticket.path);
    }
    _decode(
      await _post('request_return', {'orderId': orderId, 'evidence': evidence}),
    );
  }
}

class ReturnImageUpload {
  const ReturnImageUpload({required this.bytes, required this.contentType});
  final Uint8List bytes;
  final String contentType;
}
