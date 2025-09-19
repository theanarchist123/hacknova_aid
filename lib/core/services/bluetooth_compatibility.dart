import 'dart:io';
import 'package:flutter/foundation.dart';

/// Bluetooth compatibility layer for different platforms
class BluetoothCompatibility {
  static bool get isBluetoothSupported {
    if (kIsWeb) return false;
    
    // Bluetooth Serial (SPP) is only supported on mobile platforms
    if (Platform.isAndroid || Platform.isIOS) {
      return true;
    }
    
    // Windows, macOS, Linux don't support Bluetooth Serial through Flutter
    return false;
  }
  
  static bool get supportsBluetoothClassic {
    return Platform.isAndroid;
  }
  
  static bool get supportsBLE {
    return Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS;
  }
  
  static String get platformName {
    if (Platform.isWindows) return 'Windows';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}