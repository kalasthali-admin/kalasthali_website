import 'dart:typed_data';

Future<Uint8List> convertPngToWebp(Uint8List bytes) => Future.error(
  UnsupportedError('PNG conversion is available in the web admin dashboard.'),
);
