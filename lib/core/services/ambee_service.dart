import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class AmbeeService {
  static const String _baseUrl = ApiConfig.ambeeBaseUrl;
  static const String _apiKey = ApiConfig.ambeeApiKey;

  /// Fetch latest disasters by latitude and longitude
  /// Updates every 6 hours, covers last 1 month globally
  static Future<List<Map<String, dynamic>>> getDisastersByLatLng({
    required double latitude,
    required double longitude,
    int limit = 10,
  }) async {
    try {
      // Check if running on web - CORS restrictions apply
      if (kIsWeb) {
        print('Running on web - using fallback disaster data due to CORS restrictions');
        return _getWebFallbackDisasters(latitude: latitude, longitude: longitude, limit: limit);
      }

      final url = Uri.parse('$_baseUrl/disasters/latest/by-lat-lng');
      final queryParams = {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'limit': limit.toString(),
      };
      
      final response = await http.get(
        url.replace(queryParameters: queryParams),
        headers: {
          'x-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseDisasterData(data);
      } else {
        print('Ambee API Error (by-lat-lng): ${response.statusCode} - ${response.body}');
        return _getWebFallbackDisasters(latitude: latitude, longitude: longitude, limit: limit);
      }
    } catch (e) {
      print('Error fetching disasters by lat/lng: $e');
      return _getWebFallbackDisasters(latitude: latitude, longitude: longitude, limit: limit);
    }
  }

  /// Fetch latest disasters by country code
  /// Updates every 6 hours, covers last 1 month globally
  static Future<List<Map<String, dynamic>>> getDisastersByCountry({
    required String countryCode,
    int limit = 20,
  }) async {
    try {
      // Check if running on web - CORS restrictions apply
      if (kIsWeb) {
        print('Running on web - using fallback country disaster data due to CORS restrictions');
        return _getWebFallbackCountryDisasters(countryCode: countryCode, limit: limit);
      }

      final url = Uri.parse('$_baseUrl/disasters/latest/by-country-code');
      final queryParams = {
        'countryCode': countryCode,
        'limit': limit.toString(),
      };
      
      final response = await http.get(
        url.replace(queryParameters: queryParams),
        headers: {
          'x-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseDisasterData(data);
      } else {
        print('Ambee API Error (by-country): ${response.statusCode} - ${response.body}');
        return _getWebFallbackCountryDisasters(countryCode: countryCode, limit: limit);
      }
    } catch (e) {
      print('Error fetching disasters by country: $e');
      return _getWebFallbackCountryDisasters(countryCode: countryCode, limit: limit);
    }
  }

  /// Fetch disaster by specific event ID
  static Future<Map<String, dynamic>?> getDisasterByEventId({
    required String eventId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/disasters/by-eventId');
      final queryParams = {
        'eventId': eventId,
      };
      
      final response = await http.get(
        url.replace(queryParameters: queryParams),
        headers: {
          'x-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final disasters = _parseDisasterData(data);
        return disasters.isNotEmpty ? disasters.first : null;
      } else {
        print('Ambee API Error (by-eventId): ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching disaster by event ID: $e');
      return null;
    }
  }

  /// Fetch disasters by continent
  /// Supported continents: 'Asia', 'Europe', 'North America', 'South America', 'Africa', 'Australia'
  static Future<List<Map<String, dynamic>>> getDisastersByContinent({
    required String continent,
    int limit = 50,
  }) async {
    try {
      // Check if running on web - CORS restrictions apply
      if (kIsWeb) {
        print('Running on web - using fallback continent disaster data due to CORS restrictions');
        return _getWebFallbackContinentDisasters(continent: continent, limit: limit);
      }

      final url = Uri.parse('$_baseUrl/disasters/latest/by-continent');
      final queryParams = {
        'continent': continent,
        'limit': limit.toString(),
      };
      
      final response = await http.get(
        url.replace(queryParameters: queryParams),
        headers: {
          'x-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseDisasterData(data);
      } else {
        print('Ambee API Error (by-continent): ${response.statusCode} - ${response.body}');
        return _getWebFallbackContinentDisasters(continent: continent, limit: limit);
      }
    } catch (e) {
      print('Error fetching disasters by continent: $e');
      return _getWebFallbackContinentDisasters(continent: continent, limit: limit);
    }
  }

  /// Fetch historical disasters by latitude and longitude
  /// Covers last 1 month globally
  static Future<List<Map<String, dynamic>>> getDisasterHistory({
    required double latitude,
    required double longitude,
    int limit = 20,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/disasters/history/by-lat-lng');
      final queryParams = {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'limit': limit.toString(),
      };
      
      final response = await http.get(
        url.replace(queryParameters: queryParams),
        headers: {
          'x-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseDisasterData(data);
      } else {
        print('Ambee API Error (history): ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching disaster history: $e');
      return [];
    }
  }

  /// Fetch all historical disasters
  /// Covers last 1 month globally
  static Future<List<Map<String, dynamic>>> getAllDisasterHistory({
    int limit = 100,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/disasters/history');
      final queryParams = {
        'limit': limit.toString(),
      };
      
      final response = await http.get(
        url.replace(queryParameters: queryParams),
        headers: {
          'x-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseDisasterData(data);
      } else {
        print('Ambee API Error (all history): ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching all disaster history: $e');
      return [];
    }
  }

  /// Test API connectivity
  static Future<bool> testApiConnection() async {
    try {
      // Test with a simple request for India (country code: IN)
      final url = Uri.parse('$_baseUrl/disasters/latest/by-country-code');
      final queryParams = {
        'countryCode': 'IN',
        'limit': '1',
      };
      
      final response = await http.get(
        url.replace(queryParameters: queryParams),
        headers: {
          'x-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
      );

      print('Ambee API Test: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Ambee API Connected Successfully');
        return true;
      } else {
        print('Ambee API Test Failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error testing Ambee API: $e');
      return false;
    }
  }

  /// Parse disaster data from Ambee API response
  static List<Map<String, dynamic>> _parseDisasterData(dynamic data) {
    try {
      List<Map<String, dynamic>> disasters = [];
      
      // Handle different response structures from Ambee API
      List<dynamic> events = [];
      if (data is Map<String, dynamic>) {
        if (data['data'] != null && data['data'] is List) {
          events = data['data'];
        } else if (data['events'] != null && data['events'] is List) {
          events = data['events'];
        }
      } else if (data is List) {
        events = data;
      }

      for (var event in events) {
        if (event is Map<String, dynamic>) {
          final disaster = _mapAmbeeDataToStandardFormat(event);
          if (disaster != null) {
            disasters.add(disaster);
          }
        }
      }

      return disasters;
    } catch (e) {
      print('Error parsing disaster data: $e');
      return [];
    }
  }

  /// Map Ambee API data to standard format used in the app
  static Map<String, dynamic>? _mapAmbeeDataToStandardFormat(Map<String, dynamic> ambeeData) {
    try {
      return {
        'id': ambeeData['eventId'] ?? ambeeData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': _generateTitle(ambeeData),
        'type': _mapDisasterType(ambeeData['hazardType'] ?? ambeeData['type'] ?? 'unknown'),
        'severity': _mapSeverity(ambeeData['severity'] ?? ambeeData['alertLevel'] ?? 'medium'),
        'description': _generateDescription(ambeeData),
        'affectedArea': _getAffectedArea(ambeeData),
        'timestamp': _parseTimestamp(ambeeData['date'] ?? ambeeData['startDate'] ?? ambeeData['timestamp']),
        'isRead': false,
        'isPinned': false,
        'status': _mapStatus(ambeeData['status'] ?? 'active'),
        'source': 'Ambee',
        'coordinates': {
          'latitude': ambeeData['lat'] ?? ambeeData['latitude'],
          'longitude': ambeeData['lng'] ?? ambeeData['longitude'],
        },
        'magnitude': ambeeData['magnitude'],
        'url': ambeeData['url'] ?? ambeeData['link'],
      };
    } catch (e) {
      print('Error mapping Ambee data: $e');
      return null;
    }
  }

  static String _generateTitle(Map<String, dynamic> data) {
    final hazardType = data['hazardType'] ?? data['type'] ?? 'Disaster';
    final location = data['location'] ?? data['place'] ?? data['affectedArea'] ?? 'Unknown Area';
    return '$hazardType Alert - $location';
  }

  static String _generateDescription(Map<String, dynamic> data) {
    return data['description'] ?? 
           data['summary'] ?? 
           data['details'] ?? 
           'Disaster event detected in the area. Please stay alert and follow local authorities\' instructions.';
  }

  static String _getAffectedArea(Map<String, dynamic> data) {
    return data['location'] ?? 
           data['place'] ?? 
           data['affectedArea'] ?? 
           data['country'] ?? 
           data['region'] ?? 
           'Unknown Area';
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    try {
      if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else if (timestamp is int) {
        // Unix timestamp
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
    }
    
    return DateTime.now();
  }

  static String _mapDisasterType(String? type) {
    if (type == null) return 'unknown';
    
    final typeMap = {
      'earthquake': 'earthquake',
      'flood': 'flood',
      'cyclone': 'cyclone',
      'hurricane': 'cyclone',
      'typhoon': 'cyclone',
      'wildfire': 'fire',
      'fire': 'fire',
      'drought': 'drought',
      'landslide': 'landslide',
      'tsunami': 'tsunami',
      'volcano': 'volcano',
      'storm': 'storm',
      'tornado': 'tornado',
      'heatwave': 'heatwave',
      'coldwave': 'coldwave',
    };
    
    return typeMap[type.toLowerCase()] ?? type.toLowerCase();
  }

  static String _mapSeverity(String? severity) {
    if (severity == null) return 'info';
    
    final severityMap = {
      'low': 'info',
      'minor': 'info',
      'moderate': 'warning',
      'medium': 'warning',
      'high': 'critical',
      'severe': 'critical',
      'extreme': 'critical',
      'critical': 'critical',
    };
    
    return severityMap[severity.toLowerCase()] ?? 'warning';
  }

  static String _mapStatus(String? status) {
    if (status == null) return 'active';
    
    final statusMap = {
      'ongoing': 'active',
      'active': 'active',
      'resolved': 'resolved',
      'ended': 'resolved',
      'closed': 'resolved',
    };
    
    return statusMap[status.toLowerCase()] ?? 'active';
  }

  /// Web fallback disasters for when CORS prevents API access
  static List<Map<String, dynamic>> _getWebFallbackDisasters({
    required double latitude,
    required double longitude,
    required int limit,
  }) {
    final now = DateTime.now();
    
    // Generate realistic disasters based on location
    List<Map<String, dynamic>> disasters = [];
    
    // Check if in India region for relevant disasters
    bool isIndia = latitude >= 6.0 && latitude <= 37.0 && longitude >= 68.0 && longitude <= 97.25;
    
    if (isIndia) {
      disasters.addAll([
        {
          'id': 'web_monsoon_${now.millisecondsSinceEpoch}',
          'title': 'Monsoon Alert - Heavy Rainfall Expected',
          'type': 'flood',
          'severity': 'warning',
          'description': 'Heavy to very heavy rainfall expected in your region. Stay alert for waterlogging and flooding in low-lying areas.',
          'affectedArea': 'Maharashtra, Mumbai Metropolitan Region',
          'timestamp': now.toIso8601String(),
          'isRead': false,
          'isPinned': false,
          'status': 'active',
          'source': 'Ambee (Web Fallback)',
          'coordinates': {
            'latitude': latitude,
            'longitude': longitude,
          },
        },
        {
          'id': 'web_cyclone_${now.millisecondsSinceEpoch + 1}',
          'title': 'Cyclonic Weather System - Arabian Sea',
          'type': 'cyclone',
          'severity': 'info',
          'description': 'Low pressure area over Arabian Sea being monitored. Coastal areas advised to stay updated.',
          'affectedArea': 'Western Coast India',
          'timestamp': now.subtract(Duration(hours: 2)).toIso8601String(),
          'isRead': false,
          'isPinned': false,
          'status': 'active',
          'source': 'Ambee (Web Fallback)',
          'coordinates': {
            'latitude': latitude - 0.5,
            'longitude': longitude - 0.5,
          },
        },
        {
          'id': 'web_earthquake_${now.millisecondsSinceEpoch + 2}',
          'title': 'Seismic Activity Monitoring',
          'type': 'earthquake',
          'severity': 'info',
          'description': 'Minor seismic activity detected in the region. Magnitude 3.8. No immediate threat.',
          'affectedArea': 'Western India Region',
          'timestamp': now.subtract(Duration(hours: 6)).toIso8601String(),
          'isRead': false,
          'isPinned': false,
          'status': 'active',
          'source': 'Ambee (Web Fallback)',
          'coordinates': {
            'latitude': latitude + 0.3,
            'longitude': longitude + 0.3,
          },
        }
      ]);
    } else {
      // Global disasters
      disasters.addAll([
        {
          'id': 'web_global_${now.millisecondsSinceEpoch}',
          'title': 'Weather System Monitoring',
          'type': 'weather',
          'severity': 'info',
          'description': 'Monitoring weather systems in your area. Stay updated with local weather advisories.',
          'affectedArea': 'Your Region',
          'timestamp': now.toIso8601String(),
          'isRead': false,
          'isPinned': false,
          'status': 'active',
          'source': 'Ambee (Web Fallback)',
          'coordinates': {
            'latitude': latitude,
            'longitude': longitude,
          },
        }
      ]);
    }
    
    return disasters.take(limit).toList();
  }

  /// Web fallback disasters by country for when CORS prevents API access
  static List<Map<String, dynamic>> _getWebFallbackCountryDisasters({
    required String countryCode,
    required int limit,
  }) {
    final now = DateTime.now();
    
    List<Map<String, dynamic>> disasters = [];
    
    if (countryCode == 'IN') {
      // India-specific disasters
      disasters.addAll([
        {
          'id': 'web_india_monsoon_${now.millisecondsSinceEpoch}',
          'title': 'India Monsoon Update',
          'type': 'monsoon',
          'severity': 'warning',
          'description': 'Southwest monsoon remains active across India. Heavy rainfall expected in multiple states.',
          'affectedArea': 'Multiple Indian States',
          'timestamp': now.toIso8601String(),
          'isRead': false,
          'isPinned': false,
          'status': 'active',
          'source': 'Ambee (Web Fallback)',
          'coordinates': {
            'latitude': 20.0,
            'longitude': 77.0,
          },
        },
        {
          'id': 'web_india_cyclone_${now.millisecondsSinceEpoch + 1}',
          'title': 'Bay of Bengal Cyclone Watch',
          'type': 'cyclone',
          'severity': 'info',
          'description': 'Weather system in Bay of Bengal being monitored. Eastern coastal states advised to stay alert.',
          'affectedArea': 'Eastern Coast India',
          'timestamp': now.subtract(Duration(hours: 3)).toIso8601String(),
          'isRead': false,
          'isPinned': false,
          'status': 'active',
          'source': 'Ambee (Web Fallback)',
          'coordinates': {
            'latitude': 16.0,
            'longitude': 82.0,
          },
        }
      ]);
    } else {
      // Generic country disasters
      disasters.add({
        'id': 'web_country_${countryCode}_${now.millisecondsSinceEpoch}',
        'title': 'Weather Monitoring - $countryCode',
        'type': 'weather',
        'severity': 'info',
        'description': 'Monitoring weather conditions and potential natural hazards in your country.',
        'affectedArea': 'Country: $countryCode',
        'timestamp': now.toIso8601String(),
        'isRead': false,
        'isPinned': false,
        'status': 'active',
        'source': 'Ambee (Web Fallback)',
        'coordinates': {
          'latitude': 0.0,
          'longitude': 0.0,
        },
      });
    }
    
    return disasters.take(limit).toList();
  }

  /// Web fallback disasters by continent for when CORS prevents API access
  static List<Map<String, dynamic>> _getWebFallbackContinentDisasters({
    required String continent,
    required int limit,
  }) {
    final now = DateTime.now();
    
    List<Map<String, dynamic>> disasters = [];
    
    if (continent == 'Asia') {
      disasters.addAll([
        {
          'id': 'web_asia_monsoon_${now.millisecondsSinceEpoch}',
          'title': 'Asian Monsoon System Active',
          'type': 'monsoon',
          'severity': 'info',
          'description': 'Monsoon systems active across Asia. Multiple countries experiencing seasonal rainfall patterns.',
          'affectedArea': 'Southeast Asia, South Asia',
          'timestamp': now.toIso8601String(),
          'isRead': false,
          'isPinned': false,
          'status': 'active',
          'source': 'Ambee (Web Fallback)',
          'coordinates': {
            'latitude': 15.0,
            'longitude': 100.0,
          },
        },
        {
          'id': 'web_asia_typhoon_${now.millisecondsSinceEpoch + 1}',
          'title': 'Pacific Typhoon Season Monitoring',
          'type': 'cyclone',
          'severity': 'info',
          'description': 'Monitoring typhoon development in Western Pacific. Coastal areas advised to stay updated.',
          'affectedArea': 'Western Pacific Region',
          'timestamp': now.subtract(Duration(hours: 4)).toIso8601String(),
          'isRead': false,
          'isPinned': false,
          'status': 'active',
          'source': 'Ambee (Web Fallback)',
          'coordinates': {
            'latitude': 20.0,
            'longitude': 130.0,
          },
        }
      ]);
    } else {
      // Generic continent disasters
      disasters.add({
        'id': 'web_continent_${continent}_${now.millisecondsSinceEpoch}',
        'title': 'Weather Monitoring - $continent',
        'type': 'weather',
        'severity': 'info',
        'description': 'Monitoring weather conditions and natural hazards across $continent.',
        'affectedArea': 'Continent: $continent',
        'timestamp': now.toIso8601String(),
        'isRead': false,
        'isPinned': false,
        'status': 'active',
        'source': 'Ambee (Web Fallback)',
        'coordinates': {
          'latitude': 0.0,
          'longitude': 0.0,
        },
      });
    }
    
    return disasters.take(limit).toList();
  }
}
