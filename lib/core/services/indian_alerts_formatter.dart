import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class PlaceCacheEntry {
  final String name;
  final String state;
  final String country;
  final DateTime timestamp;
  
  PlaceCacheEntry(this.name, this.state, this.country, this.timestamp);
}

/// Formatter for India-specific disaster alerts with news-style headlines
/// Uses OpenStreetMap Nominatim for reverse geocoding (free, no API key required)
class IndianAlertsFormatter {
  // India bounding box coordinates
  static const double minLat = 6.5;   // Southern tip
  static const double maxLat = 37.1;  // Northern tip
  static const double minLon = 68.0;  // Western border
  static const double maxLon = 97.5;  // Eastern border

  // Simple in-memory cache for reverse geocoding to avoid repeated API calls
  static final Map<String, PlaceCacheEntry> _placeCache = {};
  static const String _userAgent = 'DisasterReliefApp/1.0 (emergency.relief.app@gmail.com)';

  /// Check if coordinates are within India's boundaries
  static bool isInIndia(double lat, double lon) {
    return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
  }

  /// Get Indian place name from coordinates using OpenStreetMap Nominatim
  /// Returns (placeName, stateName) tuple
  static Future<(String place, String state)> reverseGeocode(double lat, double lon) async {
    // Create cache key with reduced precision to improve cache hits
    final key = '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
    final cached = _placeCache[key];
    
    // Use cached result if less than 24 hours old
    if (cached != null && DateTime.now().difference(cached.timestamp).inHours < 24) {
      return (cached.name, cached.state);
    }

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lon&format=json&zoom=12&addressdetails=1&accept-language=en',
      );
      
      // Respect Nominatim usage policy: max 1 request per second
      await Future.delayed(Duration(milliseconds: 1100));
      
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = (data['address'] ?? {}) as Map<String, dynamic>;
        
        // Extract place name with priority: city > town > village > suburb > county
        final String place = (address['city'] ??
                address['town'] ??
                address['village'] ??
                address['suburb'] ??
                address['county'] ??
                address['state_district'] ??
                address['state'] ??
                'Unknown Location') as String;
        
        final String state = (address['state'] ?? address['state_district'] ?? '') as String;
        final String country = (address['country'] ?? '') as String;
        
        // Cache the result
        _placeCache[key] = PlaceCacheEntry(place, state, country, DateTime.now());
        
        print('🗺️ Reverse geocoded: ($lat, $lon) -> $place, $state');
        return (place, state);
      }
    } catch (e) {
      print('❌ Reverse geocoding failed for ($lat, $lon): $e');
    }
    
    return ('Unknown Location', '');
  }

  /// Build news-style headline and description from generic disaster data
  static Future<(String title, String description)> buildHeadline({
    required String type,
    required DateTime time,
    required double lat,
    required double lon,
    double? magnitude,
    String? originalTitle,
    Map<String, dynamic>? extraData,
  }) async {
    final (place, state) = await reverseGeocode(lat, lon);
    final localTime = time.toLocal();
    final timeString = '${localTime.hour.toString().padLeft(2, "0")}:${localTime.minute.toString().padLeft(2, "0")}';
    final dateString = '${localTime.day}/${localTime.month}/${localTime.year}';
    
    final stateText = state.isNotEmpty ? ', $state' : '';
    final locationText = '$place$stateText';
    
    switch (type.toLowerCase()) {
      case 'earthquake':
        final magText = magnitude != null ? 'M${magnitude.toStringAsFixed(1)} ' : '';
        final title = '${magText}Earthquake hits $locationText';
        final description = 'At $timeString on $dateString, ${magnitude != null ? "a magnitude ${magnitude.toStringAsFixed(1)} " : "an "}earthquake occurred near $locationText. '
            'Residents are advised to stay alert for aftershocks and follow safety protocols. Check with local authorities for damage reports.';
        return (title, description);

      case 'flood':
      case 'flooding':
        final title = 'Flooding reported in $locationText';
        final description = 'Heavy flooding has been reported in $locationText at $timeString on $dateString. '
            'Residents are advised to avoid low-lying areas, stay indoors if possible, and follow evacuation orders from local authorities. '
            'Emergency services are responding to the situation.';
        return (title, description);

      case 'cyclone':
      case 'storm':
      case 'severe storms':
        final title = 'Severe weather alert for $locationText';
        final description = 'Severe weather conditions with strong winds and heavy rainfall reported in $locationText at $timeString on $dateString. '
            'Residents should secure loose objects, avoid travel if possible, and monitor Indian Meteorological Department (IMD) updates for further advisories.';
        return (title, description);

      case 'landslide':
        final title = 'Landslide reported near $locationText';
        final description = 'A landslide has been reported near $locationText on $dateString. '
            'People in hilly and mountainous areas should avoid unstable slopes and follow local safety advisories. '
            'Emergency rescue teams are assessing the situation.';
        return (title, description);

      case 'wildfire':
      case 'wildfires':
        final title = 'Wildfire detected near $locationText';
        final description = 'Forest fire activity has been detected near $locationText at $timeString on $dateString. '
            'Residents in affected areas should be prepared for possible evacuation and follow instructions from forest department officials.';
        return (title, description);

      case 'drought':
        final title = 'Drought conditions reported in $locationText';
        final description = 'Drought conditions have been reported in $locationText. '
            'Local authorities are monitoring water levels and agricultural impact. Residents are advised to conserve water resources.';
        return (title, description);

      case 'tsunami':
        final title = 'Tsunami alert for coastal areas near $locationText';
        final description = 'A tsunami alert has been issued for coastal areas near $locationText at $timeString on $dateString. '
            'Coastal residents should immediately move to higher ground and follow evacuation instructions from local authorities.';
        return (title, description);

      default:
        // Use original title if available, otherwise create generic headline
        final title = originalTitle?.isNotEmpty == true 
            ? originalTitle!
            : '${type.substring(0, 1).toUpperCase()}${type.substring(1)} reported in $locationText';
        final description = 'A ${type.toLowerCase()} event has been reported in $locationText at $timeString on $dateString. '
            'Local authorities are monitoring the situation. Stay tuned to official channels for updates.';
        return (title, description);
    }
  }

  /// Build description for alerts without coordinates (e.g., from ReliefWeb)
  static String buildRegionalDescription(String originalDescription, String region) {
    if (originalDescription.isNotEmpty) {
      return '$originalDescription\n\nStay updated with local authorities and emergency services for the latest information.';
    }
    return 'Disaster event reported in $region. Local authorities are responding to the situation. '
        'Follow official channels and emergency services for updates and safety instructions.';
  }

  /// Extract severity level from earthquake magnitude
  static (String severity, int level) getEarthquakeSeverity(double? magnitude) {
    if (magnitude == null) return ('info', 1);
    if (magnitude >= 7.0) return ('extreme', 5);
    if (magnitude >= 6.0) return ('severe', 4);
    if (magnitude >= 5.0) return ('moderate', 3);
    if (magnitude >= 4.0) return ('warning', 2);
    return ('info', 1);
  }

  /// Extract Indian state from place name for better categorization
  static String extractState(String placeName, String stateName) {
    if (stateName.isNotEmpty) return stateName;
    
    // Common Indian state abbreviations and variations
    final stateKeywords = {
      'maharashtra': 'Maharashtra',
      'mumbai': 'Maharashtra', 
      'pune': 'Maharashtra',
      'karnataka': 'Karnataka',
      'bangalore': 'Karnataka',
      'bengaluru': 'Karnataka',
      'tamil nadu': 'Tamil Nadu',
      'chennai': 'Tamil Nadu',
      'kerala': 'Kerala',
      'kochi': 'Kerala',
      'thiruvananthapuram': 'Kerala',
      'delhi': 'Delhi',
      'new delhi': 'Delhi',
      'gujarat': 'Gujarat',
      'ahmedabad': 'Gujarat',
      'surat': 'Gujarat',
      'rajasthan': 'Rajasthan',
      'jaipur': 'Rajasthan',
      'west bengal': 'West Bengal',
      'kolkata': 'West Bengal',
      'uttar pradesh': 'Uttar Pradesh',
      'lucknow': 'Uttar Pradesh',
      'bihar': 'Bihar',
      'patna': 'Bihar',
      'odisha': 'Odisha',
      'bhubaneswar': 'Odisha',
      'jharkhand': 'Jharkhand',
      'ranchi': 'Jharkhand',
      'chhattisgarh': 'Chhattisgarh',
      'raipur': 'Chhattisgarh',
      'madhya pradesh': 'Madhya Pradesh',
      'bhopal': 'Madhya Pradesh',
      'haryana': 'Haryana',
      'chandigarh': 'Chandigarh',
      'punjab': 'Punjab',
      'himachal pradesh': 'Himachal Pradesh',
      'shimla': 'Himachal Pradesh',
      'uttarakhand': 'Uttarakhand',
      'dehradun': 'Uttarakhand',
      'jammu and kashmir': 'Jammu and Kashmir',
      'srinagar': 'Jammu and Kashmir',
      'ladakh': 'Ladakh',
      'leh': 'Ladakh',
      'assam': 'Assam',
      'guwahati': 'Assam',
      'meghalaya': 'Meghalaya',
      'shillong': 'Meghalaya',
      'manipur': 'Manipur',
      'imphal': 'Manipur',
      'nagaland': 'Nagaland',
      'kohima': 'Nagaland',
      'tripura': 'Tripura',
      'agartala': 'Tripura',
      'mizoram': 'Mizoram',
      'aizawl': 'Mizoram',
      'arunachal pradesh': 'Arunachal Pradesh',
      'itanagar': 'Arunachal Pradesh',
      'sikkim': 'Sikkim',
      'gangtok': 'Sikkim',
      'goa': 'Goa',
      'panaji': 'Goa',
      'andhra pradesh': 'Andhra Pradesh',
      'hyderabad': 'Telangana',
      'telangana': 'Telangana',
    };
    
    final lowerPlace = placeName.toLowerCase();
    for (final entry in stateKeywords.entries) {
      if (lowerPlace.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return '';
  }

  /// Calculate distance between two points using Haversine formula
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // Earth's radius in kilometers
    
    final double dLat = (lat2 - lat1) * pi / 180.0;
    final double dLon = (lon2 - lon1) * pi / 180.0;
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
}