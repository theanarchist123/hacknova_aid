import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'free_alerts_service.dart';

class DisasterAlertsService {
  // Using API config for endpoints (legacy fallback)
  static const String _usgsEarthquakeUrl = ApiConfig.usgsEarthquakeApi;
  
  Future<List<Map<String, dynamic>>> fetchDisasterAlerts({
    double? latitude,
    double? longitude,
    int radiusKm = 300, // Reduced for India-focused results
  }) async {
    try {
      print('🇮🇳 Fetching India-focused disaster alerts using free CORS-safe APIs...');
      
      // Primary source: Use the new free alerts service (USGS + NASA EONET + ReliefWeb)
      if (latitude != null && longitude != null) {
        final freeAlerts = await FreeAlertsService.instance.fetchAlertsNear(
          lat: latitude,
          lon: longitude,
          days: 7, // Last 7 days
          radiusKm: radiusKm,
        );
        
        print('✅ Fetched ${freeAlerts.length} India-focused alerts from free APIs');
        
        // If we have good results, return them
        if (freeAlerts.isNotEmpty) {
          return freeAlerts;
        }
      }
      
      // Fallback: Try legacy USGS directly if the free service fails
      print('⚠️ Falling back to direct USGS API...');
      final fallbackAlerts = await _fetchUSGSFallback(latitude, longitude, radiusKm);
      
      if (fallbackAlerts.isNotEmpty) {
        return fallbackAlerts;
      }
      
      // Last resort: Emergency static data
      print('📋 Using emergency fallback alerts...');
      return _getEmergencyFallbackAlerts(latitude, longitude);
      
    } catch (e) {
      print('❌ Error fetching disaster alerts: $e');
      return _getEmergencyFallbackAlerts(latitude, longitude);
    }
  }

  /// Legacy USGS fallback (direct API call)
  Future<List<Map<String, dynamic>>> _fetchUSGSFallback(
    double? latitude,
    double? longitude,
    int radiusKm,
  ) async {
    if (latitude == null || longitude == null) return [];
    
    try {
      final startTime = DateTime.now().subtract(Duration(days: 7)).toIso8601String();
      final url = Uri.parse(
        '$_usgsEarthquakeUrl?format=geojson'
        '&latitude=$latitude&longitude=$longitude'
        '&maxradiuskm=$radiusKm&starttime=$startTime'
      );
      
      final response = await http.get(url).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = (data['features'] as List?) ?? [];
        
        return features.map<Map<String, dynamic>>((feature) {
          final properties = feature['properties'] ?? {};
          final coordinates = (feature['geometry']?['coordinates'] as List?) ?? [];
          
          final magnitude = (properties['mag'] as num?)?.toDouble();
          final eventTime = properties['time'] as int?;
          final timestamp = eventTime != null 
              ? DateTime.fromMillisecondsSinceEpoch(eventTime, isUtc: true)
              : DateTime.now();
              
          return {
            'id': 'usgs_fallback_${properties['code'] ?? timestamp.millisecondsSinceEpoch}',
            'title': 'Earthquake M${magnitude?.toStringAsFixed(1) ?? '?'} - ${properties['place'] ?? 'Unknown'}',
            'type': 'earthquake',
            'description': properties['title'] ?? 'Earthquake detected',
            'severity': magnitude != null && magnitude >= 5.0 ? 'severe' : 'moderate',
            'severityLevel': magnitude != null && magnitude >= 5.0 ? 4 : 3,
            'source': 'USGS (Fallback)',
            'lat': coordinates.length >= 2 ? (coordinates[1] as num).toDouble() : null,
            'lon': coordinates.length >= 2 ? (coordinates[0] as num).toDouble() : null,
            'timestamp': timestamp.toIso8601String(),
            'magnitude': magnitude,
            'location': properties['place'],
            'affectedArea': properties['place'] ?? 'Unknown location',
            'coordinates': {
              'latitude': coordinates.length >= 2 ? (coordinates[1] as num).toDouble() : null,
              'longitude': coordinates.length >= 2 ? (coordinates[0] as num).toDouble() : null,
            },
            'isRead': false,
            'isPinned': false,
            'status': 'active',
          };
        }).toList();
      }
    } catch (e) {
      print('❌ USGS fallback failed: $e');
    }
    
    return [];
  }

  /// Emergency fallback alerts when all APIs fail - India-focused
  List<Map<String, dynamic>> _getEmergencyFallbackAlerts(double? lat, double? lon) {
    final now = DateTime.now();
    
    // Determine user's region in India for more relevant alerts
    String region = 'India';
    String stateInfo = '';
    if (lat != null && lon != null) {
      if (lat >= 28 && lat <= 32 && lon >= 76 && lon <= 79) {
        region = 'Northern India';
        stateInfo = 'Delhi/NCR region';
      } else if (lat >= 18 && lat <= 20 && lon >= 72 && lon <= 75) {
        region = 'Western India';
        stateInfo = 'Mumbai/Maharashtra region';
      } else if (lat >= 12 && lat <= 14 && lon >= 77 && lon <= 78) {
        region = 'Southern India';
        stateInfo = 'Bangalore/Karnataka region';
      } else if (lat >= 22 && lat <= 23 && lon >= 88 && lon <= 89) {
        region = 'Eastern India';
        stateInfo = 'Kolkata/West Bengal region';
      } else if (lat >= 17 && lat <= 18 && lon >= 78 && lon <= 79) {
        region = 'Southern India';
        stateInfo = 'Hyderabad/Telangana region';
      }
    }
    
    return [
      {
        'id': 'fallback_weather_${now.millisecondsSinceEpoch}',
        'title': 'Weather Monitoring Active - $region',
        'type': 'weather',
        'category': 'monitoring',
        'severity': 'info',
        'severityLevel': 1,
        'description': 'Indian Meteorological Department (IMD) weather monitoring systems are active in $region. Stay alert for monsoon and weather updates.',
        'source': 'India Emergency Fallback System',
        'timestamp': now.toIso8601String(),
        'lat': lat,
        'lon': lon,
        'affectedArea': stateInfo.isNotEmpty ? stateInfo : region,
        'coordinates': {
          'latitude': lat,
          'longitude': lon,
        },
        'isRead': false,
        'isPinned': false,
        'status': 'active',
        'distance_km': 0.0,
        'priority': 1,
        'country': 'India',
      },
      {
        'id': 'fallback_emergency_${(now.millisecondsSinceEpoch + 1)}',
        'title': 'NDRF & Emergency Services Active - India',
        'type': 'emergency_services',
        'category': 'information',
        'severity': 'info',
        'severityLevel': 1,
        'description': 'National Disaster Response Force (NDRF) and state emergency services are available 24/7 across India. Emergency helpline: 108',
        'source': 'India Emergency Fallback System',
        'timestamp': now.subtract(Duration(hours: 1)).toIso8601String(),
        'lat': lat,
        'lon': lon,
        'affectedArea': 'Pan-India coverage',
        'coordinates': {
          'latitude': lat,
          'longitude': lon,
        },
        'isRead': false,
        'isPinned': false,
        'status': 'active',
        'distance_km': 5.0,
        'priority': 1,
        'country': 'India',
      },
      {
        'id': 'fallback_monsoon_${(now.millisecondsSinceEpoch + 2)}',
        'title': 'Seasonal Weather Advisory - India',
        'type': 'weather',
        'category': 'advisory',
        'severity': 'info',
        'severityLevel': 2,
        'description': 'Stay prepared for seasonal weather changes including monsoons, cyclones, and extreme temperatures. Follow IMD updates regularly.',
        'source': 'India Emergency Fallback System',
        'timestamp': now.subtract(Duration(hours: 2)).toIso8601String(),
        'lat': lat,
        'lon': lon,
        'affectedArea': 'India - Seasonal',
        'coordinates': {
          'latitude': lat,
          'longitude': lon,
        },
        'isRead': false,
        'isPinned': false,
        'status': 'active',
        'distance_km': 10.0,
        'priority': 2,
        'country': 'India',
      },
    ];
  }

  /// Test connectivity to disaster alert services
  Future<bool> testConnectivity() async {
    try {
      final connectivityResults = await FreeAlertsService.instance.testConnectivity();
      final anyAvailable = connectivityResults.values.any((available) => available);
      
      if (anyAvailable) {
        print('✅ At least one disaster alert service is available');
        return true;
      } else {
        print('⚠️ No disaster alert services available - will use fallback data');
        return false;
      }
    } catch (e) {
      print('❌ Connectivity test failed: $e');
      return false;
    }
  }
}
