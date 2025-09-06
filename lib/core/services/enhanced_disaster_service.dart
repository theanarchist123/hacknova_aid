import 'disaster_alerts_service.dart';
import 'google_services.dart';
import 'location_service.dart';

class EnhancedDisasterService {
  static Future<Map<String, dynamic>> getEnhancedDisasterInfo() async {
    try {
      // Get current location
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        return _getFallbackDisasterInfo();
      }

      final latitude = position.latitude;
      final longitude = position.longitude;

      // Get disaster alerts
      final disasterService = DisasterAlertsService();
      final alerts = await disasterService.fetchDisasterAlerts(
        latitude: latitude,
        longitude: longitude,
      );
      
      // Get current weather
      final weather = await GoogleServices.getCurrentWeather(latitude, longitude);
      
      // Get location details using reverse geocoding
      final locationInfo = await GoogleServices.reverseGeocode(latitude, longitude);
      
      return {
        'location': {
          'coordinates': {'latitude': latitude, 'longitude': longitude},
          'address': locationInfo?['formatted_address'] ?? 'Current Location',
          'place_id': locationInfo?['place_id'],
        },
        'weather': weather,
        'disaster_alerts': alerts,
        'risk_assessment': _calculateRiskLevel(alerts, weather),
        'recommendations': _generateRecommendations(alerts, weather),
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Enhanced Disaster Service Error: $e');
      return _getFallbackDisasterInfo();
    }
  }

  static Map<String, dynamic> _calculateRiskLevel(List<Map<String, dynamic>>? alerts, Map<String, dynamic>? weather) {
    int riskScore = 0;
    String riskLevel = 'Low';
    List<String> riskFactors = [];

    // Analyze alerts
    if (alerts != null && alerts.isNotEmpty) {
      for (var alert in alerts) {
        final severity = alert['severity']?.toLowerCase() ?? '';
        if (severity.contains('extreme') || severity.contains('severe')) {
          riskScore += 40;
          riskFactors.add('Active ${alert['type']} alert');
        } else if (severity.contains('moderate')) {
          riskScore += 20;
          riskFactors.add('Moderate ${alert['type']} warning');
        } else {
          riskScore += 10;
          riskFactors.add('Minor ${alert['type']} advisory');
        }
      }
    }

    // Analyze weather conditions
    if (weather != null) {
      final windSpeed = weather['wind_speed'] ?? 0;
      final precipitation = weather['precipitation'] ?? 0;
      final weatherCode = weather['weather_code'] ?? 0;

      if (windSpeed > 50) {
        riskScore += 30;
        riskFactors.add('High wind speeds');
      } else if (windSpeed > 25) {
        riskScore += 15;
        riskFactors.add('Moderate wind speeds');
      }

      if (precipitation > 10) {
        riskScore += 25;
        riskFactors.add('Heavy precipitation');
      } else if (precipitation > 2) {
        riskScore += 10;
        riskFactors.add('Light precipitation');
      }

      // Weather code analysis (based on WMO codes)
      if (weatherCode >= 95) { // Thunderstorm
        riskScore += 35;
        riskFactors.add('Thunderstorm conditions');
      } else if (weatherCode >= 80) { // Heavy rain
        riskScore += 25;
        riskFactors.add('Heavy rain conditions');
      }
    }

    // Determine risk level
    if (riskScore >= 70) {
      riskLevel = 'Extreme';
    } else if (riskScore >= 50) {
      riskLevel = 'High';
    } else if (riskScore >= 30) {
      riskLevel = 'Moderate';
    } else if (riskScore >= 10) {
      riskLevel = 'Low';
    } else {
      riskLevel = 'Minimal';
    }

    return {
      'level': riskLevel,
      'score': riskScore,
      'factors': riskFactors,
      'color': _getRiskColor(riskLevel),
    };
  }

  static String _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Extreme': return '#FF0000';
      case 'High': return '#FF6600';
      case 'Moderate': return '#FFCC00';
      case 'Low': return '#99CC00';
      case 'Minimal': return '#00CC00';
      default: return '#808080';
    }
  }

  static List<Map<String, dynamic>> _generateRecommendations(List<Map<String, dynamic>>? alerts, Map<String, dynamic>? weather) {
    List<Map<String, dynamic>> recommendations = [];

    // Weather-based recommendations
    if (weather != null) {
      final windSpeed = weather['wind_speed'] ?? 0;
      final precipitation = weather['precipitation'] ?? 0;

      if (windSpeed > 50) {
        recommendations.add({
          'type': 'safety',
          'priority': 'high',
          'title': 'High Wind Warning',
          'description': 'Avoid outdoor activities. Secure loose objects.',
          'icon': '🌪️',
        });
      }

      if (precipitation > 10) {
        recommendations.add({
          'type': 'safety',
          'priority': 'high',
          'title': 'Heavy Rain Alert',
          'description': 'Avoid flood-prone areas. Stay indoors if possible.',
          'icon': '🌧️',
        });
      }
    }

    // Alert-based recommendations
    if (alerts != null && alerts.isNotEmpty) {
      for (var alert in alerts) {
        final alertType = alert['type']?.toLowerCase() ?? '';
        
        if (alertType.contains('earthquake')) {
          recommendations.add({
            'type': 'emergency',
            'priority': 'extreme',
            'title': 'Earthquake Preparedness',
            'description': 'Drop, Cover, and Hold On. Have emergency kit ready.',
            'icon': '🏗️',
          });
        } else if (alertType.contains('flood')) {
          recommendations.add({
            'type': 'evacuation',
            'priority': 'high',
            'title': 'Flood Safety',
            'description': 'Move to higher ground. Avoid walking/driving through flood water.',
            'icon': '🌊',
          });
        } else if (alertType.contains('fire')) {
          recommendations.add({
            'type': 'evacuation',
            'priority': 'extreme',
            'title': 'Fire Safety',
            'description': 'Evacuate immediately if instructed. Have escape route ready.',
            'icon': '🔥',
          });
        }
      }
    }

    // General preparedness recommendations
    recommendations.add({
      'type': 'preparedness',
      'priority': 'medium',
      'title': 'Emergency Kit Check',
      'description': 'Ensure you have water, food, flashlight, and first aid supplies.',
      'icon': '🎒',
    });

    return recommendations;
  }

  static Map<String, dynamic> _getFallbackDisasterInfo() {
    return {
      'location': {
        'coordinates': {'latitude': 19.0760, 'longitude': 72.8777},
        'address': 'Mumbai, Maharashtra, India',
        'place_id': 'fallback_mumbai',
      },
      'weather': {
        'location': 'Mumbai, Maharashtra, India',
        'temperature': 28.5,
        'humidity': 65,
        'precipitation': 0.2,
        'wind_speed': 12.3,
        'weather_code': 2,
        'timezone': 'Asia/Kolkata',
        'last_updated': DateTime.now().toIso8601String(),
        'description': 'Partly cloudy with mild conditions',
      },
      'disaster_alerts': [
        {
          'id': 'fallback_001',
          'type': 'Weather Advisory',
          'title': 'Monsoon Update',
          'description': 'Moderate rainfall expected in the region. Stay updated with weather conditions.',
          'severity': 'Minor',
          'location': 'Mumbai Metropolitan Region',
          'coordinates': {'latitude': 19.0760, 'longitude': 72.8777},
          'timestamp': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
          'source': 'Local Weather Service',
          'category': 'weather',
        }
      ],
      'risk_assessment': {
        'level': 'Low',
        'score': 15,
        'factors': ['Seasonal weather patterns'],
        'color': '#99CC00',
      },
      'recommendations': [
        {
          'type': 'preparedness',
          'priority': 'medium',
          'title': 'Monsoon Preparedness',
          'description': 'Keep umbrellas handy and avoid flood-prone areas during heavy rainfall.',
          'icon': '☔',
        }
      ],
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  // Get directions to nearest emergency facility
  static Future<Map<String, dynamic>?> getEmergencyDirections(double currentLat, double currentLng, String facilityType) async {
    try {
      // Find nearest facility
      final places = await GoogleServices.searchPlaces(
        latitude: currentLat,
        longitude: currentLng,
        type: facilityType,
        radius: 5000,
      );

      if (places.isEmpty) return null;

      final nearestPlace = places.first;
      
      // Get directions
      final directions = await GoogleServices.getDirections(
        originLat: currentLat,
        originLng: currentLng,
        destLat: nearestPlace['latitude'],
        destLng: nearestPlace['longitude'],
        mode: 'driving',
      );

      return {
        'facility': nearestPlace,
        'directions': directions,
      };
    } catch (e) {
      print('Emergency Directions Error: $e');
      return null;
    }
  }
}
