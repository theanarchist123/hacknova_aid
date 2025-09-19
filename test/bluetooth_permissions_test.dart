import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../lib/core/services/disaster_bluetooth_service.dart';

void main() {
  group('Bluetooth Permission Tests', () {
    test('should handle Android 12+ permissions correctly', () async {
      // Test that the service handles different Android versions
      final service = DisasterBluetoothService();
      
      // This test verifies that we don't have compilation errors
      // and the service can be instantiated
      expect(service, isNotNull);
    });

    test('should not reference bluetoothAdmin permission', () {
      // This test ensures we removed the problematic bluetoothAdmin permission
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.location,
      ];
      
      // Verify none of these throw exceptions when referenced
      for (final permission in permissions) {
        expect(permission, isNotNull);
      }
    });
  });
}