import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

void openPublicPage(BuildContext context, String path) {
  web.window.location.assign(path);
}

void clearProductAddIntent() {
  final uri = Uri.base;
  final query = Map<String, String>.from(uri.queryParameters)..remove('add');
  web.window.history.replaceState(
    null,
    '',
    uri.replace(queryParameters: query.isEmpty ? null : query).toString(),
  );
}
