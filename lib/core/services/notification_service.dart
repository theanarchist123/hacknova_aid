import 'dart:async';
import 'india_disaster_alert_service.dart';
import 'language_preference_service.dart';
import 'location_service.dart';
import 'google_services.dart';
import 'package:latlong2/latlong.dart';

class NotificationService {
  static StreamController<Map<String, dynamic>>? _notificationController;
  static Timer? _monitoringTimer;
  static List<String> _lastAlertIds = [];
  
  // Start monitoring for real-time notifications
  static Stream<Map<String, dynamic>> startNotificationStream() {
    _notificationController ??= StreamController<Map<String, dynamic>>.broadcast();
    
    // Start monitoring every 5 minutes for new alerts
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _checkForNewAlerts();
    });
    
    // Check immediately when stream starts
    _checkForNewAlerts();
    
    return _notificationController!.stream;
  }
  
  static Future<void> _checkForNewAlerts() async {
    try {
      // Get current location
      final position = await LocationService.getCurrentPosition();
      if (position == null) return;
      
      // Get current weather for weather-based notifications
      final weather = await GoogleServices.getCurrentWeather(
        position.latitude, 
        position.longitude
      );
      
      // Check for weather-based notifications
      _checkWeatherNotifications(weather);
      
      // Get user's preferred language for notifications
      final preferredLanguage = await LanguagePreferenceService.getPreferredLanguage();
      
      // Get disaster alerts using the same service as the main screen
      final userLocation = LatLng(position.latitude, position.longitude);
      final alerts = await IndiaDisasterAlertService.getIndiaAlerts(
        userLocation: userLocation,
        limitResults: 10,
        languageCode: preferredLanguage,
      );
      
      // Check for new high-priority alerts
      for (var alert in alerts) {
        final alertId = alert.id;
        if (!_lastAlertIds.contains(alertId)) {
          _lastAlertIds.add(alertId);
          
          // Only send notification for high-priority alerts
          if (_isHighPriorityAlert(alert)) {
            _sendNotification({
              'type': 'disaster_alert',
              'title': alert.title,
              'message': alert.description,
              'severity': alert.severity.name,
              'icon': _getAlertIcon(alert.type.name),
              'timestamp': DateTime.now().toIso8601String(),
              'data': alert.toMap(),
              'language': preferredLanguage,
            });
          }
        }
      }
      
      // Keep only last 50 alert IDs to prevent memory issues
      if (_lastAlertIds.length > 50) {
        _lastAlertIds = _lastAlertIds.sublist(_lastAlertIds.length - 50);
      }
      
    } catch (e) {
      print('Error checking for notifications: $e');
    }
  }
  
  static void _checkWeatherNotifications(Map<String, dynamic>? weather) {
    if (weather == null) return;
    
    final windSpeed = weather['wind_speed'] ?? 0;
    final precipitation = weather['precipitation'] ?? 0;
    final weatherCode = weather['weather_code'] ?? 0;
    
    // High wind warning
    if (windSpeed > 50) {
      _sendNotification({
        'type': 'weather_alert',
        'title': 'High Wind Warning',
        'message': 'Wind speeds reaching ${windSpeed.toStringAsFixed(1)} km/h. Take precautions.',
        'severity': 'high',
        'icon': '🌪️',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {'wind_speed': windSpeed},
      });
    }
    
    // Heavy rain warning
    if (precipitation > 15) {
      _sendNotification({
        'type': 'weather_alert',
        'title': 'Heavy Rain Alert',
        'message': 'Heavy rainfall detected. Avoid flood-prone areas.',
        'severity': 'moderate',
        'icon': '🌧️',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {'precipitation': precipitation},
      });
    }
    
    // Thunderstorm warning
    if (weatherCode >= 95) {
      _sendNotification({
        'type': 'weather_alert',
        'title': 'Thunderstorm Warning',
        'message': 'Thunderstorm conditions detected. Stay indoors.',
        'severity': 'high',
        'icon': '⛈️',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {'weather_code': weatherCode},
      });
    }
  }
  
  static bool _isHighPriorityAlert(DisasterAlert alert) {
    final severity = alert.severity.name.toLowerCase();
    final type = alert.type.name.toLowerCase();
    
    // High priority: severe/critical severity or dangerous disaster types
    return severity == 'severe' || 
           severity == 'critical' ||
           type == 'earthquake' ||
           type == 'tsunami' ||
           type == 'cyclone' ||
           type == 'wildfire';
  }
  
  static String _getAlertIcon(String alertType) {
    final type = alertType.toLowerCase();
    if (type == 'earthquake') return '🏗️';
    if (type == 'flood') return '🌊';
    if (type == 'wildfire') return '🔥';
    if (type == 'cyclone' || type == 'storm') return '🌀';
    if (type == 'tsunami') return '🌊';
    if (type == 'landslide') return '⛰️';
    if (type == 'drought') return '🏜️';
    return '⚠️';
  }
  
  static void _sendNotification(Map<String, dynamic> notification) {
    if (_notificationController != null && !_notificationController!.isClosed) {
      _notificationController!.add(notification);
    }
  }
  
  // Manually trigger emergency notifications (for testing)
  static void triggerEmergencyNotification(String type, String message) {
    _sendNotification({
      'type': 'emergency',
      'title': 'Emergency Alert',
      'message': message,
      'severity': 'extreme',
      'icon': '🚨',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {'manual': true, 'alert_type': type},
    });
  }
  
  // Monitor specific location for alerts
  static void monitorLocation(double latitude, double longitude) {
    // This could be used to monitor a different location than current position
    // For now, we'll use current location
  }
  
  static void dispose() {
    _monitoringTimer?.cancel();
    _notificationController?.close();
    _notificationController = null;
    _lastAlertIds.clear();
  }
}
