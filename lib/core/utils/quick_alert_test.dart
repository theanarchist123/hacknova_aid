import 'package:flutter/widgets.dart';
import '../services/disaster_alert_store.dart';
import '../services/location_service.dart';

/// Quick helper to manually test disaster alerts after app initialization
class QuickAlertTest {
  /// Simple test that can be called from anywhere in the app
  static Future<void> testNow() async {
    try {
      print('\n🚀 Quick Alert Test Started...');
      
      // Test 1: Check if Flutter binding is ready
      try {
        WidgetsBinding.instance;
        print('✅ Flutter binding is ready');
      } catch (e) {
        print('❌ Flutter binding not ready: $e');
        return;
      }
      
      // Test 2: Test location services
      print('\n📍 Testing location...');
      final location = await LocationService.getLocationWithFallback();
      if (location != null) {
        print('✅ Location: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}');
        final region = LocationService.getRegionForLocation(location);
        final city = LocationService.getNearestCity(location);
        print('   Region: $region');
        print('   Nearest: ${city['city']} (${city['distance_km']}km)');
      } else {
        print('❌ Could not get location');
      }
      
      // Test 3: Test alert fetching
      print('\n🚨 Testing alerts...');
      final alertStore = DisasterAlertStore.instance;
      
      // First try to get cached alerts
      final cachedAlerts = await alertStore.getCachedAlerts();
      print('📱 Cached alerts: ${cachedAlerts.length}');
      
      // Try to fetch fresh alerts
      final freshAlerts = await alertStore.fetchAndStoreAlerts();
      print('🆕 Fresh alerts fetched: ${freshAlerts.length}');
      
      if (freshAlerts.isNotEmpty) {
        print('\n📊 Alert breakdown:');
        final typeCount = <String, int>{};
        final severityCount = <String, int>{};
        
        for (final alert in freshAlerts) {
          typeCount[alert.type.name] = (typeCount[alert.type.name] ?? 0) + 1;
          severityCount[alert.severity.name] = (severityCount[alert.severity.name] ?? 0) + 1;
        }
        
        print('   By type: $typeCount');
        print('   By severity: $severityCount');
        
        // Show first alert as example
        final firstAlert = freshAlerts.first;
        print('\n🔍 First alert example:');
        print('   Title: ${firstAlert.title}');
        print('   Type: ${firstAlert.type.name}');
        print('   Severity: ${firstAlert.severity.name}');
        print('   Source: ${firstAlert.source}');
        print('   Location: ${firstAlert.location.latitude.toStringAsFixed(4)}, ${firstAlert.location.longitude.toStringAsFixed(4)}');
      }
      
      // Test 4: Get summary
      print('\n📈 Getting alert summary...');
      final summary = await alertStore.getAlertSummary();
      print('   Total: ${summary['total']}');
      print('   Nearby: ${summary['nearby']}');
      print('   Critical: ${summary['critical']}');
      print('   Severe: ${summary['severe']}');
      print('   User location: ${summary['has_location']}');
      if (summary['has_location'] == true) {
        print('   User region: ${summary['user_region']}');
        print('   Nearest city: ${summary['nearest_city']}');
      }
      
      print('\n✅ Quick Alert Test Completed Successfully!');
      
    } catch (e) {
      print('\n❌ Quick Alert Test Failed: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// Simple test just for location
  static Future<void> testLocationOnly() async {
    try {
      print('\n📍 Location Test...');
      
      final location = await LocationService.getLocationWithFallback();
      if (location != null) {
        print('✅ Location: ${location.latitude}, ${location.longitude}');
        print('   Region: ${LocationService.getRegionForLocation(location)}');
        print('   Nearest: ${LocationService.getNearestCity(location)}');
      } else {
        print('❌ No location available');
      }
      
    } catch (e) {
      print('❌ Location test failed: $e');
    }
  }

  /// Test just database connection
  static Future<void> testDatabaseOnly() async {
    try {
      print('\n💾 Database Test...');
      
      final alertStore = DisasterAlertStore.instance;
      final cachedAlerts = await alertStore.getCachedAlerts();
      print('✅ Database accessible, cached alerts: ${cachedAlerts.length}');
      
    } catch (e) {
      print('❌ Database test failed: $e');
    }
  }
}

/// Extension to add quick test methods to any widget
extension QuickTestExtension on State {
  /// Call this from any widget to test alerts
  void testAlertsQuick() {
    QuickAlertTest.testNow();
  }
}