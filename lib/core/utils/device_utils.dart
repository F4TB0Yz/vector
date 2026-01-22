import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class JtDeviceData {
  final String deviceId;
  final String model;
  final String brand;
  final String androidVersion;
  final String appVersion;

  JtDeviceData({
    required this.deviceId,
    required this.model,
    required this.brand,
    required this.androidVersion,
    required this.appVersion,
  });

  @override
  String toString() {
    return 'JtDeviceData(deviceId: $deviceId, model: $model, brand: $brand, androidVersion: $androidVersion, appVersion: $appVersion)';
  }
}

class DeviceUtils {
  static const String _ansiGreen = '\x1B[32m';
  static const String _ansiCyan = '\x1B[36m';
  static const String _ansiReset = '\x1B[0m';

  static Future<JtDeviceData> getJtDeviceData() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    const AndroidId androidIdPlugin = AndroidId();

    String deviceId = 'unknown_device_id';
    String model = 'Unknown_Model';
    String brand = 'generic';
    String androidVersion = '10';

    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        final String? id = await androidIdPlugin.getId();

        deviceId = id ?? androidInfo.id; // Fallback to androidInfo.id
        model = androidInfo.model;
        brand = androidInfo.brand;
        androidVersion = androidInfo.version.release;
      } else if (Platform.isIOS) {
        // Placeholder for iOS if needed in future
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        model = iosInfo.model;
        deviceId = iosInfo.identifierForVendor ?? 'ios_uuid';
        brand = 'apple';
        androidVersion = iosInfo.systemVersion;
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    final data = JtDeviceData(
      deviceId: deviceId,
      model: model,
      brand: brand,
      androidVersion: androidVersion,
      appVersion: packageInfo.version,
    );

    _logColored(data);
    return data;
  }

  static void _logColored(JtDeviceData data) {
    if (kDebugMode) {
      print('$_ansiCyan==========================================$_ansiReset');
      print('$_ansiGreen[DeviceUtils] REAL DEVICE DATA ACQUIRED:$_ansiReset');
      print('$_ansiGreen -> Device ID:   ${data.deviceId}$_ansiReset');
      print('$_ansiGreen -> Model:       ${data.model}$_ansiReset');
      print('$_ansiGreen -> Brand:       ${data.brand}$_ansiReset');
      print(
        '$_ansiGreen -> OS Version:  Android-${data.androidVersion}$_ansiReset',
      );
      print('$_ansiGreen -> App Version: ${data.appVersion}$_ansiReset');
      print('$_ansiCyan==========================================$_ansiReset');
    }
  }
}
