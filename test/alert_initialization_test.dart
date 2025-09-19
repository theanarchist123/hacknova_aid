import 'package:flutter_test/flutter_test.dart';
import 'package:hacknova_aid/core/services/india_disaster_alert_service.dart';
import 'package:hacknova_aid/core/services/location_service.dart';
import 'package:hacknova_aid/core/services/alert_background_service.dart';

void main() {
  group('Alert System Initialization Tests', () {
    setUpAll(() {
      // Ensure Flutter binding is initialized for tests
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('India Disaster Alert Service should initialize without binding errors', () async {
      // This should not throw "Binding has not yet been initialized" error
      try {
        final alerts = await IndiaDisasterAlertService.getIndiaAlerts();
        print('✅ Alert service test passed - got ${alerts.length} alerts');
        expect(alerts, isA<List>());
      } catch (e) {
        if (e.toString().contains('Binding has not yet been initialized')) {
          fail('Binding initialization failed: $e');
        } else {
          // Other errors (like network issues) are acceptable for this test
          print('ℹ️ Non-binding error (acceptable): $e');
        }
      }
    });

    test('Location Service should handle binding initialization gracefully', () async {
      // This should not throw "Binding has not yet been initialized" error
      try {
        final position = await LocationService.getCurrentPosition();
        print('✅ Location service test passed - position: $position');
        // Position can be null due to permissions/settings, that's OK
        expect(position, anyOf(isNull, isA<Object>()));
      } catch (e) {
        if (e.toString().contains('Binding has not yet been initialized')) {
          fail('Binding initialization failed in LocationService: $e');
        } else {
          // Other errors (like permission issues) are acceptable for this test
          print('ℹ️ Non-binding error (acceptable): $e');
        }
      }
    });

    test('Background Alert Service should start without binding errors', () async {
      // This should not throw "Binding has not yet been initialized" error
      try {
        await AlertBackgroundService.startBackgroundMonitoring();
        print('✅ Background service test passed');
        
        // Clean up
        AlertBackgroundService.stopBackgroundMonitoring();
        
        expect(true, isTrue); // Test passes if no binding errors occur
      } catch (e) {
        if (e.toString().contains('Binding has not yet been initialized')) {
          fail('Binding initialization failed in AlertBackgroundService: $e');
        } else {
          // Other errors are acceptable for this test
          print('ℹ️ Non-binding error (acceptable): $e');
        }
      }
    });
  });
}