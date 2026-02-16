import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceUtils {
  static const String _deviceIdKey = 'device_id';
  // Method channel for native device ID access
  static const MethodChannel _channel = MethodChannel('device_id_channel');

  /// Fetches device ID using method channel for native access
  /// Returns Android ID on Android and identifierForVendor on iOS
  static Future<String> fetchAndSaveDeviceId() async {
    String deviceId = '';

    try {
      // Use method channel to get native device ID
      deviceId = await _channel.invokeMethod('getDeviceId');
      print("Native DeviceId: $deviceId");
    } catch (e) {
      print("Method channel failed, falling back to device_info_plus: $e");
      // Fallback to device_info_plus if method channel fails
      deviceId = await _getDeviceIdFallback();
    }

    // Final fallback if nothing found → generate persistent UUID
    if (deviceId.isEmpty) {
      deviceId = _generateFallbackId();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceIdKey, deviceId);

    return deviceId;
  }

  /// Fallback method using device_info_plus package
  static Future<String> _getDeviceIdFallback() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      print("Fallback Android DeviceId: ${androidInfo.id}");
      // Note: androidInfo.id is build ID, not unique device ID
      deviceId = androidInfo.id ?? '';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
    }

    return deviceId;
  }

  static Future<String?> getSavedDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceIdKey);
  }

  static String _generateFallbackId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Gets device ID using method channel (preferred method)
  /// This will use native Android ID or iOS identifierForVendor
  static Future<String> getDeviceIdFromMethodChannel() async {
    try {
      final deviceId = await _channel.invokeMethod('getDeviceId');
      print("Method channel device ID: $deviceId");
      return deviceId ?? '';
    } catch (e) {
      print("Method channel error: $e");
      return '';
    }
  }

  /// Comprehensive device info method for debugging
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    Map<String, dynamic> info = {};

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        info = {
          'platform': 'Android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'manufacturer': androidInfo.manufacturer,
          'androidId': androidInfo.id,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        info = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'identifierForVendor': iosInfo.identifierForVendor,
        };
      }

      // Add method channel device ID
      final methodChannelId = await getDeviceIdFromMethodChannel();
      info['methodChannelDeviceId'] = methodChannelId;

      // Add saved device ID
      final savedId = await getSavedDeviceId();
      info['savedDeviceId'] = savedId;

    } catch (e) {
      print("Error getting device info: $e");
      info['error'] = e.toString();
    }

    return info;
  }

  /// Clear saved device ID (useful for testing)
  static Future<void> clearSavedDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
  }

  static Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceName = 'Unknown Device';

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        // Format: Brand Model (e.g., "Samsung SM-G991B" or "Google Pixel 6")
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        // Format: Device name (e.g., "iPhone", "iPad")
        deviceName = iosInfo.name ?? iosInfo.model ?? 'iOS Device';
      }
    } catch (e) {
      print("Error getting device name: $e");
    }

    return deviceName;
  }

  /// Gets the app version and build number
  /// Returns version in format "version+buildNumber" (e.g., "1.0.29+30")
  static Future<String> getAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      // Format: version+buildNumber (e.g., "1.0.29+30")
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      print("Error getting app version: $e");
      return 'Unknown';
    }
  }
}
