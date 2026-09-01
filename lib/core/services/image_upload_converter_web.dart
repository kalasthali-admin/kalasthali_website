import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Converts an uploaded PNG to WebP in the browser before it leaves the device.
Future<Uint8List> convertPngToWebp(Uint8List bytes) async {
  final input = html.Blob([bytes], 'image/png');
  final objectUrl = html.Url.createObjectUrlFromBlob(input);
  try {
    final image = html.ImageElement()..src = objectUrl;
    await image.onLoad.first;
    if (image.naturalWidth == 0 || image.naturalHeight == 0) {
      throw StateError('The selected PNG could not be decoded.');
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
    if (result is! ByteBuffer) {
      throw StateError('The converted WebP could not be read.');
    }
    return Uint8List.fromList(result.asUint8List());
  } finally {
    html.Url.revokeObjectUrl(objectUrl);
  }
}
