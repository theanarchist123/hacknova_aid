import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:sembast/sembast.dart';

import '../models/community_pin.dart';
import 'community_pin_store.dart';
import 'india_disaster_alert_service.dart';
import 'location_service.dart';

/// Enhanced alert store that integrates disaster alerts with community pins
class DisasterAlertStore {
  static const String _alertsStore = 'disaster_alerts';
  static const String _alertPinsStore = 'alert_pins_mapping';
  
  static DisasterAlertStore? _instance;
  DisasterAlertStore._internal();
  
  static DisasterAlertStore get instance {
    _instance ??= DisasterAlertStore._internal();
    return _instance!;
  }

  StoreRef<String, Map<String, Object?>> get _alertsStoreRef => 
      stringMapStoreFactory.store(_alertsStore);
  
  StoreRef<String, Map<String, Object?>> get _alertPinsStoreRef => 
      stringMapStoreFactory.store(_alertPinsStore);

  /// Get database from CommunityPinStore
  Future<Database> get database async {
    try {
      return await CommunityPinStore.instance.database;
    } catch (e) {
      if (e.toString().contains('Binding has not yet been initialized')) {
        print('⚠️ Database not available - Flutter binding not initialized');
        throw Exception('Database not available - app initialization required');
      }
      rethrow;
    }
  }

  /// Fetch fresh alerts and store them locally
  Future<List<DisasterAlert>> fetchAndStoreAlerts({
    bool forceRefresh = false,
  }) async {
    try {
      print('🚨 Fetching disaster alerts for India...');
      
      // Get user location for proximity-based prioritization
      final userLocation = await LocationService.getLocationWithFallback();
      
      // Fetch alerts from multiple sources
      final alerts = await IndiaDisasterAlertService.getIndiaAlerts(
        userLocation: userLocation,
        limitResults: 20, // Limit to 20 alerts for local storage
      );

      // Store alerts in local database
      await _storeAlertsLocally(alerts);

      // Convert high-priority alerts to community pins
      await _convertAlertsToPins(alerts);

      print('✅ Successfully processed ${alerts.length} disaster alerts');
      return alerts;

    } catch (e) {
      print('❌ Error fetching disaster alerts: $e');
      // Return cached alerts if available
      return await getCachedAlerts();
    }
  }

  /// Store alerts in local Sembast database
  Future<void> _storeAlertsLocally(List<DisasterAlert> alerts) async {
    final db = await database;
    
    for (final alert in alerts) {
      await _alertsStoreRef.record(alert.id).put(db, alert.toMap());
    }
    
    print('💾 Stored ${alerts.length} alerts in local database');
  }

  /// Convert critical/severe alerts to community pins for map display
  Future<void> _convertAlertsToPins(List<DisasterAlert> alerts) async {
    final db = await database;
    final pinStore = CommunityPinStore.instance;
    
    for (final alert in alerts) {
      // Only convert high-severity alerts to pins
      if (alert.severity.index < AlertSeverity.severe.index) continue;

      // Check if we already have a pin for this alert
      final existingMapping = await _alertPinsStoreRef.record(alert.id).get(db);
      if (existingMapping != null) continue;

      // Create a community pin from the alert
      final pin = CommunityPin(
        id: 'alert_${alert.id}',
        type: _getPinTypeFromAlert(alert.type),
        title: alert.title,
        description: alert.description,
        location: alert.location,
        createdAt: alert.timestamp,
        updatedAt: DateTime.now(),
        createdBy: 'system_alert',
        verifiedBy: ['official_source'],
        isSyncedToBluetooth: false,
        metadata: {
          'alert_id': alert.id,
          'alert_source': alert.source,
          'alert_severity': alert.severity.index,
          'alert_type': alert.type.index,
          'is_disaster_alert': true,
          'source_url': alert.sourceUrl,
          ...alert.metadata,
        },
      );

      // Insert the pin
      await pinStore.insertPin(pin);

      // Store the mapping
      await _alertPinsStoreRef.record(alert.id).put(db, {
        'alert_id': alert.id,
        'pin_id': pin.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('📍 Created pin for ${alert.severity.name} alert: ${alert.title}');
    }
  }

  /// Get cached alerts from local database
  Future<List<DisasterAlert>> getCachedAlerts() async {
    try {
      final db = await database;
      
      // Get alerts from last 24 hours
      final cutoffTime = DateTime.now().subtract(Duration(hours: 24));
      
      final finder = Finder(
        filter: Filter.greaterThan('timestamp', cutoffTime.toIso8601String()),
        sortOrders: [SortOrder('timestamp', false)],
      );
      
      final records = await _alertsStoreRef.find(db, finder: finder);
      final alerts = records.map((record) => DisasterAlert.fromMap(record.value)).toList();
      
      print('📱 Retrieved ${alerts.length} cached alerts');
      return alerts;
      
    } catch (e) {
      if (e.toString().contains('Database not available') || 
          e.toString().contains('Binding has not yet been initialized')) {
        print('⚠️ Database not available for cached alerts, returning empty list');
        return [];
      }
      print('❌ Error getting cached alerts: $e');
      return [];
    }
  }

  /// Get alerts near a specific location
  Future<List<DisasterAlert>> getAlertsNearLocation(
    LatLng location, {
    double radiusKm = 100.0,
  }) async {
    final allAlerts = await getCachedAlerts();
    
    final nearbyAlerts = allAlerts.where((alert) {
      final distance = LocationService.calculateDistance(
        location.latitude,
        location.longitude,
        alert.location.latitude,
        alert.location.longitude,
      );
      return distance <= radiusKm;
    }).toList();

    // Sort by distance
    nearbyAlerts.sort((a, b) {
      final distanceA = LocationService.calculateDistance(
        location.latitude,
        location.longitude,
        a.location.latitude,
        a.location.longitude,
      );
      final distanceB = LocationService.calculateDistance(
        location.latitude,
        location.longitude,
        b.location.latitude,
        b.location.longitude,
      );
      return distanceA.compareTo(distanceB);
    });

    return nearbyAlerts;
  }

  /// Get alerts by severity level
  Future<List<DisasterAlert>> getAlertsBySeverity(AlertSeverity severity) async {
    final db = await database;
    
    final finder = Finder(
      filter: Filter.equals('severity', severity.index),
      sortOrders: [SortOrder('timestamp', false)],
    );
    
    final records = await _alertsStoreRef.find(db, finder: finder);
    return records.map((record) => DisasterAlert.fromMap(record.value)).toList();
  }

  /// Get alerts by disaster type
  Future<List<DisasterAlert>> getAlertsByType(DisasterType type) async {
    final db = await database;
    
    final finder = Finder(
      filter: Filter.equals('type', type.index),
      sortOrders: [SortOrder('timestamp', false)],
    );
    
    final records = await _alertsStoreRef.find(db, finder: finder);
    return records.map((record) => DisasterAlert.fromMap(record.value)).toList();
  }

  /// Get location-aware alert summary
  Future<Map<String, dynamic>> getAlertSummary() async {
    try {
      final userLocation = await LocationService.getLocationWithFallback();
      final allAlerts = await getCachedAlerts();
      
      if (userLocation == null) {
        return {
          'total': allAlerts.length,
          'has_location': false,
        };
      }

      final nearbyAlerts = await getAlertsNearLocation(userLocation, radiusKm: 100);
      final criticalAlerts = allAlerts.where((a) => a.severity == AlertSeverity.critical).length;
      final severeAlerts = allAlerts.where((a) => a.severity == AlertSeverity.severe).length;
      
      final regionName = LocationService.getRegionForLocation(userLocation);
      final nearestCity = LocationService.getNearestCity(userLocation);

      return {
        'total': allAlerts.length,
        'nearby': nearbyAlerts.length,
        'critical': criticalAlerts,
        'severe': severeAlerts,
        'has_location': true,
        'user_region': regionName,
        'nearest_city': nearestCity['city'],
        'city_distance': nearestCity['distance_km'],
        'location_coordinates': {
          'lat': userLocation.latitude,
          'lon': userLocation.longitude,
        },
      };
    } catch (e) {
      print('❌ Error getting alert summary: $e');
      return {'total': 0, 'error': e.toString()};
    }
  }

  /// Convert disaster type to community pin type
  PinType _getPinTypeFromAlert(DisasterType disasterType) {
    switch (disasterType) {
      case DisasterType.earthquake:
        return PinType.hazard;
      case DisasterType.flood:
        return PinType.flood;
      case DisasterType.cyclone:
        return PinType.hazard;
      case DisasterType.tsunami:
        return PinType.hazard;
      case DisasterType.wildfire:
        return PinType.fire;
      case DisasterType.storm:
        return PinType.hazard;
      case DisasterType.drought:
        return PinType.water_source;
      case DisasterType.landslide:
        return PinType.landslide;
      case DisasterType.other:
        return PinType.other;
    }
  }

  /// Clean up old alerts (older than 7 days)
  Future<void> cleanupOldAlerts() async {
    try {
      final db = await database;
      final cutoffTime = DateTime.now().subtract(Duration(days: 7));
      
      final finder = Finder(
        filter: Filter.lessThan('timestamp', cutoffTime.toIso8601String()),
      );
      
      final deletedCount = await _alertsStoreRef.delete(db, finder: finder);
      print('🗑️ Cleaned up $deletedCount old alerts');
      
    } catch (e) {
      print('❌ Error cleaning up old alerts: $e');
    }
  }

  /// Clear all cached alerts (useful for testing)
  Future<void> clearAllAlerts() async {
    try {
      final db = await database;
      await _alertsStoreRef.delete(db);
      await _alertPinsStoreRef.delete(db);
      
      // Also clear API cache
      IndiaDisasterAlertService.clearCache();
      LocationService.clearCache();
      
      print('🗑️ Cleared all alerts and cache');
    } catch (e) {
      print('❌ Error clearing alerts: $e');
    }
  }

  /// Get statistics about stored alerts
  Future<Map<String, int>> getAlertStatistics() async {
    try {
      final allAlerts = await getCachedAlerts();
      final stats = <String, int>{};
      
      // Count by severity
      for (final severity in AlertSeverity.values) {
        stats['severity_${severity.name}'] = 
          allAlerts.where((a) => a.severity == severity).length;
      }
      
      // Count by type
      for (final type in DisasterType.values) {
        stats['type_${type.name}'] = 
          allAlerts.where((a) => a.type == type).length;
      }
      
      // Count by source
      final sources = allAlerts.map((a) => a.source).toSet();
      for (final source in sources) {
        stats['source_$source'] = allAlerts.where((a) => a.source == source).length;
      }
      
      stats['total'] = allAlerts.length;
      return stats;
      
    } catch (e) {
      print('❌ Error getting alert statistics: $e');
      return {'error': 1};
    }
  }
}