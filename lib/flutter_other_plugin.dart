import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class FlutterOtherPlugin {
  static const MethodChannel _channel =
      const MethodChannel('flutter_other_plugin');

  /// save image to Gallery
  /// imageBytes can't null
  static Future save(Uint8List imageBytes) async {
    assert(imageBytes != null);
    final result =
    await _channel.invokeMethod('saveImageToGallery', imageBytes);
    return result;
  }
}
