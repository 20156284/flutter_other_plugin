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

  //获取地理定位
  Future<LocationData> getLocation() => _channel
      .invokeMethod('getLocation')
      .then((result) => LocationData.fromMap(result.cast<String, double>()));

  /// Checks if the app has permission to access location.
  Future<bool> hasPermission() =>
      _channel.invokeMethod('hasPermission').then((result) => result == 1);

  //保存图片
  static Future<bool> save(Uint8List imageBytes) async {
    assert(imageBytes != null);
    bool _save = await _channel.invokeMethod('saveImageToGallery', imageBytes);
    return _save;
  }

  //播放铃声 如果静的情况调用震动
  static Future<bool> playBell(String bellUrl) async {
    assert(bellUrl != null);
    return _channel.invokeMethod('playBell', bellUrl);
  }

  Stream<LocationData> onLocationChanged() {
    if (_onLocationChanged == null) {
      _onLocationChanged = _stream.receiveBroadcastStream().map<LocationData>(
          (element) => LocationData.fromMap(element.cast<String, double>()));
    }
    return _onLocationChanged;
  }
}
