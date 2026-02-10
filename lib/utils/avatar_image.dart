import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

Future<Uint8List> prepareAvatarBytes(
  XFile pickedFile, {
  int maxDimension = 512,
  int quality = 75,
}) async {
  if (kIsWeb) {
    return pickedFile.readAsBytes();
  }

  // Try native compression first (works well on mobile; may be unsupported on Windows/Linux).
  try {
    final compressed = await FlutterImageCompress.compressWithFile(
      pickedFile.path,
      minWidth: maxDimension,
      minHeight: maxDimension,
      quality: quality,
      format: CompressFormat.jpeg,
    );

    if (compressed != null && compressed.isNotEmpty) {
      return Uint8List.fromList(compressed);
    }
  } on UnimplementedError {
    // Fallback to pure-dart compression below.
  } catch (_) {
    // Fallback to pure-dart compression below.
  }

  // Pure-dart fallback (works on desktop/web). This also handles platforms
  // where `flutter_image_compress` is not implemented.
  final originalBytes = await pickedFile.readAsBytes();
  final decoded = img.decodeImage(originalBytes);
  if (decoded == null) {
    return originalBytes;
  }

  final resized = _resizeMax(decoded, maxDimension);
  final encoded = img.encodeJpg(resized, quality: quality);
  return Uint8List.fromList(encoded);
}

img.Image _resizeMax(img.Image src, int maxDim) {
  if (src.width <= maxDim && src.height <= maxDim) {
    return src;
  }

  if (src.width >= src.height) {
    return img.copyResize(
      src,
      width: maxDim,
      interpolation: img.Interpolation.average,
    );
  }

  return img.copyResize(
    src,
    height: maxDim,
    interpolation: img.Interpolation.average,
  );
}
