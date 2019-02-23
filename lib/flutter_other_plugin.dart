import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// A data class that contains various information about the user's location.
///
/// speedAccuracy cannot be provided on iOS and thus is always 0.
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double speedAccuracy;
  final double heading;

  LocationData._(
    this.latitude,
    this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.speedAccuracy,
    this.heading,
  );

  factory LocationData.fromMap(Map<String, double> dataMap) {
    return LocationData._(
      dataMap['latitude'],
      dataMap['longitude'],
      dataMap['accuracy'],
      dataMap['altitude'],
      dataMap['speed'],
      dataMap['speed_accuracy'],
      dataMap['heading'],
    );
  }
}

const MethodChannel _channel = const MethodChannel('flutter_other_plugin');
const EventChannel _stream =
    const EventChannel('flutter_other_plugin/locationstream');

class FlutterOtherPlugin {
  Stream<LocationData> _onLocationChanged;

  /// Gets the current location of the user.
  ///
  /// Throws an error if the app has no permission to access location.
  Future<LocationData> getLocation() => _channel
      .invokeMethod('getLocation')
      .then((result) => LocationData.fromMap(result.cast<String, double>()));

  /// Checks if the app has permission to access location.
  Future<bool> hasPermission() =>
      _channel.invokeMethod('hasPermission').then((result) => result == 1);

  /// save image to Gallery
  /// imageBytes can't null
  static Future save(Uint8List imageBytes) async {
    assert(imageBytes != null);
    final result =
        await _channel.invokeMethod('saveImageToGallery', imageBytes);
    return result;
  }

  /// Returns a stream of location information.
  Stream<LocationData> onLocationChanged() {
    if (_onLocationChanged == null) {
      _onLocationChanged = _stream.receiveBroadcastStream().map<LocationData>(
          (element) => LocationData.fromMap(element.cast<String, double>()));
    }
    return _onLocationChanged;
  }
}
