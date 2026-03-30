import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// Detects low system capabilities (e.g. RAM < 2GB or weak processor).
class DeviceInfoService {
  static bool _isLowMemory = false;

  static Future<void> initialize() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        if (androidInfo.isLowRamDevice == true) {
          _isLowMemory = true;
        } else {
          _isLowMemory = Platform.numberOfProcessors <= 4;
        }
      } else if (Platform.isIOS) {
        _isLowMemory = Platform.numberOfProcessors <= 4;
      } else {
        _isLowMemory = Platform.numberOfProcessors <= 4;
      }
    } catch (_) {
      // Fallback
      _isLowMemory = Platform.numberOfProcessors <= 4;
    }
  }

  static bool get isLowMemory => _isLowMemory;
}
