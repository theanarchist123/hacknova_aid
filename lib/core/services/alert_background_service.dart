import 'dart:async';
import 'package:flutter/widgets.dart';

import 'disaster_alert_store.dart';
import 'location_service.dart';
import 'india_disaster_alert_service.dart' show DisasterAlert, AlertSeverity;

/// Background service for automatic alert fetching and notifications
class AlertBackgroundService {
  static Timer? _alertTimer;
  static Timer? _cleanupTimer;
  static bool _isRunning = false;
  static DateTime? _lastFetchTime;
  
  // Background fetch intervals
  static const Duration _alertFetchInterval = Duration(minutes: 30);
  static const Duration _cleanupInterval = Duration(hours: 6);
  static const Duration _minFetchInterval = Duration(minutes: 5);

  /// Initialize and start background alert monitoring
  static Future<void> startBackgroundMonitoring() async {
    if (_isRunning) {
      print('⚠️ Background monitoring already running');
      return;
    }

    print('🚀 Starting disaster alert background monitoring...');
    
    // Ensure Flutter binding is available for platform channels
    WidgetsFlutterBinding.ensureInitialized();
    
    _isRunning = true;

    // Delay initial fetch to allow app initialization
    Timer(Duration(seconds: 5), () {
      _fetchAlertsInBackground();
    });

    // Set up periodic alert fetching
    _alertTimer = Timer.periodic(_alertFetchInterval, (timer) {
      _fetchAlertsInBackground();
    });

    // Set up periodic cleanup
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      _cleanupInBackground();
    });

    print('✅ Background monitoring started');
  }

  /// Stop background monitoring
  static void stopBackgroundMonitoring() {
    if (!_isRunning) return;

    print('🛑 Stopping background monitoring...');
    
    _alertTimer?.cancel();
    _cleanupTimer?.cancel();
    _alertTimer = null;
    _cleanupTimer = null;
    _isRunning = false;

    print('✅ Background monitoring stopped');
  }

  /// Fetch alerts in background with rate limiting
  static void _fetchAlertsInBackground() async {
    try {
      // Rate limiting - don't fetch too frequently
      if (_lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _minFetchInterval) {
        print('⏱️ Skipping fetch - too recent');
        return;
      }

      print('🔄 Background alert fetch started...');
      _lastFetchTime = DateTime.now();

      final alertStore = DisasterAlertStore.instance;
      
      // Fetch fresh alerts
      final alerts = await alertStore.fetchAndStoreAlerts();
      
      // Check for high-priority alerts
      final criticalAlerts = alerts.where((a) => 
        a.severity.index >= AlertSeverity.severe.index).toList();

      if (criticalAlerts.isNotEmpty) {
        print('🚨 Found ${criticalAlerts.length} critical/severe alerts');
        _notifyAboutCriticalAlerts(criticalAlerts);
      }

      print('✅ Background fetch completed: ${alerts.length} alerts processed');

    } catch (e) {
      if (e.toString().contains('Database not available') || 
          e.toString().contains('Binding has not yet been initialized')) {
        print('⚠️ Background fetch skipped - app not fully initialized');
        return;
      }
      print('❌ Background fetch failed: $e');
    }
  }

  /// Clean up old data in background
  static void _cleanupInBackground() async {
    try {
      print('🧹 Starting background cleanup...');
      
      final alertStore = DisasterAlertStore.instance;
      await alertStore.cleanupOldAlerts();
      
      // Clean up location cache if very old
      if (!LocationService.hasCachedLocation()) {
        LocationService.clearCache();
      }

      print('✅ Background cleanup completed');

    } catch (e) {
      print('❌ Background cleanup failed: $e');
    }
  }

  /// Notify about critical alerts (would integrate with push notifications)
  static void _notifyAboutCriticalAlerts(List<DisasterAlert> alerts) {
    // This would integrate with Firebase Cloud Messaging or local notifications
    // For now, just log the critical alerts
    
    for (final alert in alerts) {
      print('🚨 CRITICAL ALERT: ${alert.title}');
      print('   📍 Location: ${alert.location.latitude}, ${alert.location.longitude}');
      print('   ⏰ Time: ${alert.timestamp}');
      print('   🔗 Source: ${alert.source}');
    }

    // TODO: Implement actual push notifications
    // NotificationService.showCriticalAlert(alerts);
  }

  /// Force refresh alerts (useful for pull-to-refresh)
  static Future<List<DisasterAlert>> forceRefreshAlerts() async {
    try {
      print('🔄 Force refreshing alerts...');
      
      final alertStore = DisasterAlertStore.instance;
      final alerts = await alertStore.fetchAndStoreAlerts(forceRefresh: true);
      
      _lastFetchTime = DateTime.now();
      print('✅ Force refresh completed: ${alerts.length} alerts');
      
      return alerts;

    } catch (e) {
      print('❌ Force refresh failed: $e');
      rethrow;
    }
  }

  /// Get current background service status
  static Map<String, dynamic> getServiceStatus() {
    return {
      'is_running': _isRunning,
      'last_fetch': _lastFetchTime?.toIso8601String(),
      'alert_timer_active': _alertTimer?.isActive ?? false,
      'cleanup_timer_active': _cleanupTimer?.isActive ?? false,
      'next_fetch_in_minutes': _lastFetchTime != null ? 
        _alertFetchInterval.inMinutes - DateTime.now().difference(_lastFetchTime!).inMinutes : 0,
    };
  }

  /// Get alert statistics for background monitoring
  static Future<Map<String, dynamic>> getBackgroundStats() async {
    try {
      final alertStore = DisasterAlertStore.instance;
      final stats = await alertStore.getAlertStatistics();
      final summary = await alertStore.getAlertSummary();
      
      return {
        'service_status': getServiceStatus(),
        'alert_stats': stats,
        'alert_summary': summary,
        'timestamp': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      print('❌ Error getting background stats: $e');
      return {
        'error': e.toString(),
        'service_status': getServiceStatus(),
      };
    }
  }

  /// Schedule one-time alert fetch (useful for app launch)
  static Future<void> scheduleImmediateFetch() async {
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _minFetchInterval) {
      print('⏱️ Skipping immediate fetch - too recent');
      return;
    }

    print('⚡ Scheduling immediate alert fetch...');
    
    // Run in a separate timer to avoid blocking
    Timer(Duration(seconds: 1), () {
      _fetchAlertsInBackground();
    });
  }

  /// Check if we need fresh alerts based on last fetch time
  static bool needsFreshAlerts() {
    if (_lastFetchTime == null) return true;
    
    final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
    return timeSinceLastFetch > _alertFetchInterval;
  }

  /// Get time until next scheduled fetch
  static Duration? getTimeUntilNextFetch() {
    if (_lastFetchTime == null || !_isRunning) return null;
    
    final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
    final remainingTime = _alertFetchInterval - timeSinceLastFetch;
    
    return remainingTime.isNegative ? Duration.zero : remainingTime;
  }
}