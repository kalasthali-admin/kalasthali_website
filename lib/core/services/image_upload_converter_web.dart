// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

/// Converts a PNG or JPEG to WebP in the browser before it leaves the device.
Future<Uint8List> convertImageToWebp(Uint8List bytes, String inputMime) async {
  // A copied buffer keeps the browser Blob constructor from receiving a Dart
  // typed-list wrapper on some web renderers.
  final stableBytes = Uint8List.fromList(bytes);
  final input = html.Blob([stableBytes.buffer], inputMime);
  final objectUrl = html.Url.createObjectUrlFromBlob(input);
  try {
    final image = html.ImageElement()..src = objectUrl;
    await Future.any([
      image.onLoad.first,
      image.onError.first.then<void>(
        (_) => throw StateError('The selected image could not be decoded.'),
      ),
    ]);
    if (image.naturalWidth == 0 || image.naturalHeight == 0) {
      throw StateError('The selected image could not be decoded.');
    }

    final canvas = html.CanvasElement(
      width: image.naturalWidth,
      height: image.naturalHeight,
    );
    canvas.context2D.drawImage(image, 0, 0);
    final output = await canvas.toBlob('image/webp', .8);
    if (output.type != 'image/webp') {
      throw StateError('This browser could not create a WebP image.');
    }

    final reader = html.FileReader();
    final loaded = reader.onLoad.first;
    reader.readAsArrayBuffer(output);
    await loaded;
    final result = reader.result;
    if (result is Uint8List) return Uint8List.fromList(result);
    if (result is ByteBuffer) return Uint8List.fromList(result.asUint8List());
    throw StateError('The converted WebP could not be read.');
  } finally {
    html.Url.revokeObjectUrl(objectUrl);
  }
}
