import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:hacknova_aid/core/services/india_disaster_alert_service.dart';
import 'package:hacknova_aid/core/services/location_service.dart';
import 'package:hacknova_aid/core/services/disaster_alert_store.dart';

void main() {
  group('India Disaster Alert System Tests', () {
    
    test('should fetch USGS earthquake data for India', () async {
      print('🧪 Testing USGS earthquake data fetch...');
      
      final alerts = await IndiaDisasterAlertService.getIndiaAlerts();
      
      expect(alerts, isNotNull);
      print('✅ Fetched ${alerts.length} alerts');
      
      if (alerts.isNotEmpty) {
        final firstAlert = alerts.first;
        expect(firstAlert.id, isNotEmpty);
        expect(firstAlert.title, isNotEmpty);
        expect(firstAlert.source, isNotEmpty);
        
        print('📋 Sample alert:');
        print('   ID: ${firstAlert.id}');
        print('   Title: ${firstAlert.title}');
        print('   Type: ${firstAlert.type}');
        print('   Severity: ${firstAlert.severity}');
        print('   Source: ${firstAlert.source}');
        print('   Location: ${firstAlert.location.latitude}, ${firstAlert.location.longitude}');
        print('   Time: ${firstAlert.timestamp}');
      }
    });

    test('should prioritize alerts by location proximity', () async {
      print('🧪 Testing location-based alert prioritization...');
      
      // Use Mumbai coordinates for testing
      final mumbaiLocation = LatLng(19.0760, 72.8777);
      
      final alerts = await IndiaDisasterAlertService.getIndiaAlerts(
        userLocation: mumbaiLocation,
        proximityKm: 100.0,
      );
      
      expect(alerts, isNotNull);
      print('✅ Fetched ${alerts.length} location-prioritized alerts');
      
      // Check if alerts have distance metadata
      for (final alert in alerts.take(3)) {
        if (alert.metadata['distance_km'] != null) {
          print('📍 Alert "${alert.title}" - Distance: ${alert.metadata['distance_km']}km');
        }
      }
    });

    test('should store and retrieve alerts locally', () async {
      print('🧪 Testing local alert storage...');
      
      final alertStore = DisasterAlertStore.instance;
      
      // Clear existing alerts for clean test
      await alertStore.clearAllAlerts();
      
      // Fetch and store alerts
      final alerts = await alertStore.fetchAndStoreAlerts();
      
      expect(alerts, isNotNull);
      print('✅ Stored ${alerts.length} alerts locally');
      
      // Retrieve cached alerts
      final cachedAlerts = await alertStore.getCachedAlerts();
      
      expect(cachedAlerts, isNotNull);
      expect(cachedAlerts.length, equals(alerts.length));
      print('✅ Retrieved ${cachedAlerts.length} cached alerts');
    });

    test('should get alert summary with location info', () async {
      print('🧪 Testing alert summary with location...');
      
      final alertStore = DisasterAlertStore.instance;
      final summary = await alertStore.getAlertSummary();
      
      expect(summary, isNotNull);
      expect(summary['total'], isA<int>());
      
      print('📊 Alert Summary:');
      print('   Total alerts: ${summary['total']}');
      print('   Has location: ${summary['has_location']}');
      
      if (summary['has_location'] == true) {
        print('   Nearby alerts: ${summary['nearby']}');
        print('   Critical alerts: ${summary['critical']}');
        print('   Severe alerts: ${summary['severe']}');
        print('   User region: ${summary['user_region']}');
        print('   Nearest city: ${summary['nearest_city']} (${summary['city_distance']}km away)');
      }
    });

    test('should filter alerts by disaster type', () async {
      print('🧪 Testing alert filtering by disaster type...');
      
      final alertStore = DisasterAlertStore.instance;
      
      // Ensure we have some alerts
      await alertStore.fetchAndStoreAlerts();
      
      // Test filtering by earthquake type
      final earthquakeAlerts = await alertStore.getAlertsByType(DisasterType.earthquake);
      print('🌍 Found ${earthquakeAlerts.length} earthquake alerts');
      
      // Test filtering by severe severity
      final severeAlerts = await alertStore.getAlertsBySeverity(AlertSeverity.severe);
      print('🚨 Found ${severeAlerts.length} severe alerts');
    });

    test('should get location information correctly', () async {
      print('🧪 Testing location service...');
      
      // Test region mapping
      final mumbaiLocation = LatLng(19.0760, 72.8777);
      final mumbaiRegion = LocationService.getRegionForLocation(mumbaiLocation);
      expect(mumbaiRegion, equals('Maharashtra'));
      print('✅ Mumbai region: $mumbaiRegion');
      
      final delhiLocation = LatLng(28.6139, 77.2090);
      final delhiRegion = LocationService.getRegionForLocation(delhiLocation);
      expect(delhiRegion, equals('Delhi/NCR'));
      print('✅ Delhi region: $delhiRegion');
      
      // Test nearest city
      final nearestToMumbai = LocationService.getNearestCity(mumbaiLocation);
      expect(nearestToMumbai['city'], equals('Mumbai'));
      print('✅ Nearest city to Mumbai: ${nearestToMumbai['city']} (${nearestToMumbai['distance_km']}km)');
    });

    test('should calculate distances correctly', () async {
      print('🧪 Testing distance calculations...');
      
      final mumbai = LatLng(19.0760, 72.8777);
      final delhi = LatLng(28.6139, 77.2090);
      
      final distance = LocationService.calculateDistance(
        mumbai.latitude,
        mumbai.longitude,
        delhi.latitude,
        delhi.longitude,
      );
      
      // Mumbai to Delhi is approximately 1150-1200 km
      expect(distance, greaterThan(1100));
      expect(distance, lessThan(1300));
      print('✅ Mumbai to Delhi distance: ${distance.toStringAsFixed(1)}km');
    });

    test('should get alert statistics', () async {
      print('🧪 Testing alert statistics...');
      
      final alertStore = DisasterAlertStore.instance;
      
      // Ensure we have some alerts
      await alertStore.fetchAndStoreAlerts();
      
      final stats = await alertStore.getAlertStatistics();
      
      expect(stats, isNotNull);
      expect(stats['total'], isA<int>());
      
      print('📈 Alert Statistics:');
      stats.forEach((key, value) {
        print('   $key: $value');
      });
    });
  });
}