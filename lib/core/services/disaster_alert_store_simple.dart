import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:sembast/sembast.dart';

import '../models/community_pin.dart';
import 'community_pin_store.dart';
import 'india_disaster_alert_service.dart';
import 'location_service.dart';

/// Enhanced alert store that integrates disaster alerts with community pins
class DisasterAlertStore {
  static const String _alertsStoreName = 'disaster_alerts';
  
  // Store reference
  final _alertsStoreRef = stringMapStoreFactory.store(_alertsStoreName);
  
  // Database instance
  Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // For now, return a simple in-memory database
    _database = await databaseFactoryMemory.openDatabase('alerts.db');
    return _database!;
  }
  
  /// Store new disaster alerts
  Future<void> storeAlerts(List<DisasterAlert> alerts) async {
    try {
      final db = await database;
      
      for (final alert in alerts) {
        await _alertsStoreRef.record(alert.id).put(db, alert.toMap());
      }
      
      print('💾 Stored ${alerts.length} new alerts');
    } catch (e) {
      print('❌ Error storing alerts: $e');
    }
  }
  
  /// Get recent alerts (simplified version)
  Future<List<DisasterAlert>> getRecentAlerts({int limit = 50}) async {
    try {
      // For now, fetch fresh alerts from the service
      final alertService = IndiaDisasterAlertService();
      final alerts = await alertService.getCurrentAlerts();
      return alerts.take(limit).toList();
    } catch (e) {
      print('❌ Error getting recent alerts: $e');
      return [];
    }
  }
  
  /// Get alerts by severity (simplified)
  Future<List<DisasterAlert>> getAlertsBySeverity(AlertSeverity severity) async {
    try {
      final allAlerts = await getRecentAlerts();
      return allAlerts.where((alert) => alert.severity == severity).toList();
    } catch (e) {
      print('❌ Error filtering alerts by severity: $e');
      return [];
    }
  }
  
  /// Get alerts by type (simplified)
  Future<List<DisasterAlert>> getAlertsByType(DisasterType type) async {
    try {
      final allAlerts = await getRecentAlerts();
      return allAlerts.where((alert) => alert.type == type).toList();
    } catch (e) {
      print('❌ Error filtering alerts by type: $e');
      return [];
    }
  }
  
  /// Get alerts near location (simplified)
  Future<List<DisasterAlert>> getAlertsNearLocation(
    Map<String, double> location, {
    double radiusKm = 50.0,
  }) async {
    try {
      final allAlerts = await getRecentAlerts();
      final userLat = location['latitude']!;
      final userLng = location['longitude']!;
      
      return allAlerts.where((alert) {
        final distance = LocationService.calculateDistance(
          userLat, userLng,
          alert.latitude, alert.longitude
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      print('❌ Error getting nearby alerts: $e');
      return [];
    }
  }
  
  /// Clean up old alerts (placeholder)
  Future<void> cleanupOldAlerts() async {
    print('🗑️ Alert cleanup - feature temporarily disabled');
  }
  
  /// Get alert statistics (simplified)
  Future<Map<String, dynamic>> getAlertStatistics() async {
    try {
      final allAlerts = await getRecentAlerts();
      
      return {
        'total': allAlerts.length,
        'critical': allAlerts.where((a) => a.severity == AlertSeverity.critical).length,
        'severe': allAlerts.where((a) => a.severity == AlertSeverity.severe).length,
        'moderate': allAlerts.where((a) => a.severity == AlertSeverity.moderate).length,
        'minor': allAlerts.where((a) => a.severity == AlertSeverity.minor).length,
      };
    } catch (e) {
      print('❌ Error getting alert statistics: $e');
      return {
        'total': 0,
        'critical': 0,
        'severe': 0,
        'moderate': 0,
        'minor': 0,
      };
    }
  }
}