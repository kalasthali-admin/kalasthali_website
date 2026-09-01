import 'dart:typed_data';

Future<Uint8List> convertImageToWebp(Uint8List bytes, String inputMime) =>
    Future.error(
      UnsupportedError(
        'Image conversion is available in the web admin dashboard.',
      ),
    );
