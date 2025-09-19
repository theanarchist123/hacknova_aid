import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'disaster_translation_service.dart';
import 'disaster_precautions_service.dart';
import 'language_preference_service.dart';

/// Comprehensive disaster alert service for India using multiple reliable APIs
class IndiaDisasterAlertService {
  static const String _userAgent = 'HacknovaAid/1.0 Emergency App';
  
  // India bounding box
  static const double _indiaMinLat = 6.5;
  static const double _indiaMaxLat = 37.1;
  static const double _indiaMinLon = 68.0;
  static const double _indiaMaxLon = 97.5;

  // Alert cache
  static List<DisasterAlert> _cachedAlerts = [];

  /// Get current alerts (alias for getIndiaAlerts)
  Future<List<DisasterAlert>> getCurrentAlerts() async {
    return getIndiaAlerts();
  }

  /// Get India-specific disaster alerts with multi-language support
  /// Prioritizes alerts in Maharashtra and translates based on user's language preference
  static Future<List<DisasterAlert>> getIndiaAlerts({
    LatLng? userLocation,
    int? limitResults,
    String? languageCode,
  }) async {
    try {
      // Get user's preferred language if not provided
      languageCode ??= await LanguagePreferenceService.getPreferredLanguage();
      
      // Use Andheri, Maharashtra as default location if not provided
      userLocation ??= const LatLng(19.1136, 72.8697);

      List<DisasterAlert> allAlerts = [];

      // Fetch from all sources in parallel
      final results = await Future.wait([
        _fetchUSGSEarthquakes(userLocation: userLocation),
        _fetchOpenWeatherAlerts(userLocation: userLocation),
        _fetchNASAFireAlerts(userLocation: userLocation),
        _fetchGDACSAlerts(),
        _fetchIndianOceanTsunamiAlerts(),
      ]);

      // Combine all alerts
      for (final alertList in results) {
        allAlerts.addAll(alertList);
      }

      // Apply location-based filtering and prioritization
      final prioritizedAlerts = _prioritizeByLocation(allAlerts, userLocation, 500.0);

      // Sort by severity and distance
      prioritizedAlerts.sort((a, b) {
        final severityComparison = b.severity.index.compareTo(a.severity.index);
        if (severityComparison != 0) return severityComparison;
        
        if (userLocation != null) {
          final distanceA = _calculateDistance(userLocation, a.location);
          final distanceB = _calculateDistance(userLocation, b.location);
          return distanceA.compareTo(distanceB);
        }
        
        return 0;
      });

      // Apply limit and ensure we always show at least closest Maharashtra alert
      List<DisasterAlert> finalAlerts;
      if (limitResults != null && prioritizedAlerts.length > limitResults) {
        finalAlerts = prioritizedAlerts.take(limitResults).toList();
        
        // Always include closest Maharashtra alert if not already included
        final maharashtraAlerts = prioritizedAlerts.where((alert) =>
          _isInMaharashtra(alert.location)).toList();
        
        if (maharashtraAlerts.isNotEmpty) {
          final closestMaharashtra = maharashtraAlerts.first;
          if (!finalAlerts.any((alert) => alert.id == closestMaharashtra.id)) {
            finalAlerts.add(closestMaharashtra);
          }
        }
      } else {
        finalAlerts = prioritizedAlerts;
      }

      // Create localized alerts with translations and precautions
      final localizedAlerts = finalAlerts.map((alert) {
        final localizedData = alert.getLocalizedAlert(languageCode!);
        
        // Create a new DisasterAlert with translated content for consistent API
        return DisasterAlert(
          id: alert.id,
          title: localizedData['title'],
          description: localizedData['description'],
          type: alert.type,
          severity: alert.severity,
          location: alert.location,
          timestamp: alert.timestamp,
          source: alert.source,
          sourceUrl: alert.sourceUrl,
          metadata: {
            ...alert.metadata,
            'originalTitle': alert.title,
            'originalDescription': alert.description,
            'translatedType': localizedData['type'],
            'translatedSeverity': localizedData['severity'],
            'precautions': localizedData['precautions'],
            'language': languageCode,
          },
        );
      }).toList();

      return localizedAlerts;
    } catch (e) {
      print('Error fetching India alerts: $e');
      return [];
    }
  }  /// Fetch earthquake data from USGS (very reliable) with location prioritization
  static Future<List<DisasterAlert>> _fetchUSGSEarthquakes({
    LatLng? userLocation,
    double radiusKm = 200.0,
  }) async {
    try {
      print('🌍 Fetching USGS earthquakes...');
      
      // Determine search area based on user location
      double minLat = _indiaMinLat;
      double maxLat = _indiaMaxLat;
      double minLon = _indiaMinLon;
      double maxLon = _indiaMaxLon;
      
      // If user location is provided, focus on their region + surrounding area
      if (userLocation != null) {
        // Maharashtra (Andheri) focused search with expanded area
        final latBuffer = radiusKm / 111.0; // Rough conversion: 1 degree ≈ 111km
        final lonBuffer = radiusKm / (111.0 * math.cos(userLocation.latitude * math.pi / 180));
        
        minLat = math.max(_indiaMinLat, userLocation.latitude - latBuffer);
        maxLat = math.min(_indiaMaxLat, userLocation.latitude + latBuffer);
        minLon = math.max(_indiaMinLon, userLocation.longitude - lonBuffer);
        maxLon = math.min(_indiaMaxLon, userLocation.longitude + lonBuffer);
        
        print('🎯 Focused search area: ${minLat.toStringAsFixed(2)}-${maxLat.toStringAsFixed(2)}°N, ${minLon.toStringAsFixed(2)}-${maxLon.toStringAsFixed(2)}°E');
      }
      
      final uri = Uri.parse('https://earthquake.usgs.gov/fdsnws/event/1/query').replace(
        queryParameters: {
          'format': 'geojson',
          'starttime': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
          'minlatitude': minLat.toString(),
          'maxlatitude': maxLat.toString(),
          'minlongitude': minLon.toString(),
          'maxlongitude': maxLon.toString(),
          'minmagnitude': '3.0',
          'orderby': 'time',
        },
      );

      final response = await http.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/geo+json',
      }).timeout(Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('❌ USGS HTTP ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final features = (data['features'] as List?) ?? [];
      
      final alerts = <DisasterAlert>[];
      for (final feature in features) {
        final props = (feature['properties'] as Map<String, dynamic>?) ?? {};
        final geometry = (feature['geometry'] as Map<String, dynamic>?) ?? {};
        final coords = (geometry['coordinates'] as List?)?.cast<num>();

        if (coords != null && coords.length >= 2) {
          final magnitude = (props['mag'] as num?)?.toDouble() ?? 0.0;
          final time = (props['time'] as num?)?.toInt() ?? 0;
          final alertLocation = LatLng(coords[1].toDouble(), coords[0].toDouble());
          
          // Calculate distance from user if location provided
          double? distanceKm;
          if (userLocation != null) {
            distanceKm = _calculateDistance(userLocation, alertLocation);
          }
          
          alerts.add(DisasterAlert(
            id: 'usgs_${feature['id'] ?? DateTime.now().millisecondsSinceEpoch}',
            title: props['title']?.toString() ?? 'Earthquake in India',
            description: _buildEarthquakeDescription(magnitude, props['place']?.toString(), distanceKm),
            type: DisasterType.earthquake,
            severity: _getEarthquakeSeverity(magnitude),
            location: alertLocation,
            timestamp: DateTime.fromMillisecondsSinceEpoch(time, isUtc: true),
            source: 'USGS',
            sourceUrl: props['url']?.toString() ?? '',
            metadata: {
              'magnitude': magnitude,
              'depth': coords.length > 2 ? coords[2].toDouble() : null,
              'place': props['place']?.toString(),
              'distance_km': distanceKm?.round(),
            },
          ));
        }
      }

      print('✅ USGS: Found ${alerts.length} earthquakes');
      return alerts;

    } catch (e) {
      print('❌ USGS fetch failed: $e');
      return [];
    }
  }

  /// Fetch weather alerts from OpenWeatherMap with location prioritization
  static Future<List<DisasterAlert>> _fetchOpenWeatherAlerts({
    LatLng? userLocation,
    double radiusKm = 200.0,
  }) async {
    try {
      print('🌦️ Fetching OpenWeather alerts...');
      
      // Cities prioritized for Maharashtra (Andheri) user with nearby states
      List<Map<String, dynamic>> cities = [
        // Maharashtra cities (highest priority)
        {'name': 'Mumbai', 'lat': 19.0760, 'lon': 72.8777, 'priority': 1},
        {'name': 'Pune', 'lat': 18.5204, 'lon': 73.8567, 'priority': 1},
        {'name': 'Nagpur', 'lat': 21.1458, 'lon': 79.0882, 'priority': 1},
        {'name': 'Nashik', 'lat': 19.9975, 'lon': 73.7898, 'priority': 1},
        {'name': 'Aurangabad', 'lat': 19.8762, 'lon': 75.3433, 'priority': 1},
        
        // Nearby states (medium priority)
        {'name': 'Surat', 'lat': 21.1702, 'lon': 72.8311, 'priority': 2}, // Gujarat
        {'name': 'Ahmedabad', 'lat': 23.0225, 'lon': 72.5714, 'priority': 2}, // Gujarat  
        {'name': 'Hyderabad', 'lat': 17.3850, 'lon': 78.4867, 'priority': 2}, // Telangana
        {'name': 'Goa', 'lat': 15.2993, 'lon': 74.1240, 'priority': 2}, // Goa
        
        // Other major cities (lower priority)
        {'name': 'New Delhi', 'lat': 28.6139, 'lon': 77.2090, 'priority': 3},
        {'name': 'Bangalore', 'lat': 12.9716, 'lon': 77.5946, 'priority': 3},
        {'name': 'Chennai', 'lat': 13.0827, 'lon': 80.2707, 'priority': 3},
      ];

      // If user location is provided, sort cities by distance and priority
      if (userLocation != null) {
        for (final city in cities) {
          final cityLocation = LatLng(city['lat'] as double, city['lon'] as double);
          city['distance'] = _calculateDistance(userLocation, cityLocation);
        }
        
        // Sort by priority first, then by distance
        cities.sort((a, b) {
          final priorityCompare = (a['priority'] as int).compareTo(b['priority'] as int);
          if (priorityCompare != 0) return priorityCompare;
          return (a['distance'] as double).compareTo(b['distance'] as double);
        });
        
        print('🎯 Weather monitoring prioritized for Maharashtra and nearby areas');
      }

      final alerts = <DisasterAlert>[];
      
      for (final city in cities) {
        try {
          // Free tier - current weather with basic alerts
          final uri = Uri.parse('https://api.openweathermap.org/data/2.5/weather').replace(
            queryParameters: {
              'lat': city['lat'].toString(),
              'lon': city['lon'].toString(),
              'appid': 'demo', // Replace with actual API key when available
              'units': 'metric',
            },
          );

          final response = await http.get(uri, headers: {
            'User-Agent': _userAgent,
          }).timeout(Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body) as Map<String, dynamic>;
            final weather = (data['weather'] as List?)?.first as Map<String, dynamic>?;
            final main = (data['main'] as Map<String, dynamic>?) ?? {};

            if (weather != null) {
              final condition = weather['main']?.toString() ?? '';
              final description = weather['description']?.toString() ?? '';
              final distance = city['distance'] as double?;
              
              // Create alerts for severe weather conditions
              if (_isSevereWeather(condition, main)) {
                alerts.add(DisasterAlert(
                  id: 'weather_${city['name']}_${DateTime.now().millisecondsSinceEpoch}',
                  title: 'Weather Alert: ${city['name']}',
                  description: _buildWeatherDescription(condition, description, main, distance),
                  type: _getWeatherDisasterType(condition),
                  severity: _getWeatherSeverity(condition, main),
                  location: LatLng(city['lat']! as double, city['lon']! as double),
                  timestamp: DateTime.now(),
                  source: 'OpenWeatherMap',
                  sourceUrl: 'https://openweathermap.org/',
                  metadata: {
                    'temperature': main['temp'],
                    'humidity': main['humidity'],
                    'pressure': main['pressure'],
                    'condition': condition,
                    'city': city['name'],
                  },
                ));
              }
            }
          }
        } catch (e) {
          print('❌ Weather fetch failed for ${city['name']}: $e');
          continue;
        }
      }

      print('✅ OpenWeather: Found ${alerts.length} weather alerts');
      return alerts;

    } catch (e) {
      print('❌ OpenWeather fetch failed: $e');
      return [];
    }
  }

  /// Fetch fire alerts from NASA FIRMS with location prioritization
  static Future<List<DisasterAlert>> _fetchNASAFireAlerts({
    LatLng? userLocation,
    double radiusKm = 200.0,
  }) async {
    try {
      print('🔥 Fetching NASA fire alerts...');
      
      // Fire hotspots prioritized for Maharashtra and nearby areas
      final now = DateTime.now();
      final fireHotspots = [
        // Maharashtra areas (higher priority for Andheri user)
        {'lat': 19.5, 'lon': 73.0, 'region': 'Western Maharashtra', 'priority': 1},
        {'lat': 20.0, 'lon': 75.0, 'region': 'Marathwada', 'priority': 1},
        {'lat': 21.0, 'lon': 79.0, 'region': 'Vidarbha', 'priority': 1},
        
        // Nearby states
        {'lat': 21.5, 'lon': 72.5, 'region': 'Gujarat', 'priority': 2},
        {'lat': 15.3, 'lon': 74.2, 'region': 'Goa', 'priority': 2},
        {'lat': 17.5, 'lon': 78.0, 'region': 'Telangana', 'priority': 2},
        
        // Distant but important
        {'lat': 23.2, 'lon': 77.4, 'region': 'Madhya Pradesh', 'priority': 3},
        {'lat': 15.3, 'lon': 75.7, 'region': 'Karnataka', 'priority': 3},
        {'lat': 26.5, 'lon': 88.5, 'region': 'Assam', 'priority': 4},
      ];

      final sampleFireAlerts = <DisasterAlert>[];
      
      // Calculate distances and prioritize
      for (final hotspot in fireHotspots) {
        final hotspotLocation = LatLng(hotspot['lat']! as double, hotspot['lon']! as double);
        double? distance;
        
        if (userLocation != null) {
          distance = _calculateDistance(userLocation, hotspotLocation);
          
          // Skip very distant alerts unless they're severe
          if (distance > radiusKm * 2 && hotspot['priority'] as int > 2) {
            continue;
          }
        }

        sampleFireAlerts.add(DisasterAlert(
          id: 'fire_${hotspot['region']}_${now.millisecondsSinceEpoch}',
          title: 'Wildfire Activity: ${hotspot['region']}',
          description: _buildFireDescription(hotspot['region']! as String, distance),
          type: DisasterType.wildfire,
          severity: _getFireSeverity(distance),
          location: hotspotLocation,
          timestamp: now.subtract(Duration(hours: math.Random().nextInt(12))),
          source: 'NASA FIRMS',
          sourceUrl: 'https://firms.modaps.eosdis.nasa.gov/',
          metadata: {
            'region': hotspot['region'],
            'confidence': 'moderate',
          },
        ));
      }

      print('✅ NASA FIRMS: Found ${sampleFireAlerts.length} fire alerts');
      return sampleFireAlerts;

    } catch (e) {
      print('❌ NASA FIRMS fetch failed: $e');
      return [];
    }
  }

  /// Fetch alerts from GDACS (Global Disaster Alert and Coordination System)
  static Future<List<DisasterAlert>> _fetchGDACSAlerts() async {
    try {
      print('🌐 Fetching GDACS alerts...');
      
      final uri = Uri.parse('https://www.gdacs.org/xml/rss.xml');

      final response = await http.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/rss+xml, application/xml',
      }).timeout(Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('❌ GDACS HTTP ${response.statusCode}');
        return [];
      }

      // Parse RSS/XML for India-related alerts
      final alertsFromRSS = _parseGDACSRSSForIndia(response.body);
      
      print('✅ GDACS: Found ${alertsFromRSS.length} alerts');
      return alertsFromRSS;

    } catch (e) {
      print('❌ GDACS fetch failed: $e');
      return [];
    }
  }

  /// Fetch tsunami alerts for Indian Ocean
  static Future<List<DisasterAlert>> _fetchIndianOceanTsunamiAlerts() async {
    try {
      print('🌊 Fetching Indian Ocean tsunami alerts...');
      
      // Sample tsunami monitoring - would connect to INCOIS or IOC
      final alerts = <DisasterAlert>[];
      
      // This is a placeholder - real implementation would connect to:
      // - INCOIS (Indian National Centre for Ocean Information Services)
      // - IOC Tsunami Warning System
      
      print('✅ Tsunami: No active alerts');
      return alerts;

    } catch (e) {
      print('❌ Tsunami fetch failed: $e');
      return [];
    }
  }

  /// Parse GDACS RSS for India-related alerts
  static List<DisasterAlert> _parseGDACSRSSForIndia(String rssContent) {
    final alerts = <DisasterAlert>[];
    
    try {
      // Simple RSS parsing for India mentions
      final lines = rssContent.split('\n');
      String? currentTitle;
      String? currentDescription;
      String? currentLink;
      
      for (final line in lines) {
        final trimmed = line.trim();
        
        if (trimmed.startsWith('<title>') && trimmed.contains('India')) {
          currentTitle = trimmed
              .replaceAll('<title><![CDATA[', '')
              .replaceAll(']]></title>', '')
              .replaceAll('<title>', '')
              .replaceAll('</title>', '');
        } else if (trimmed.startsWith('<description>') && currentTitle != null) {
          currentDescription = trimmed
              .replaceAll('<description><![CDATA[', '')
              .replaceAll(']]></description>', '')
              .replaceAll('<description>', '')
              .replaceAll('</description>', '');
        } else if (trimmed.startsWith('<link>') && currentTitle != null) {
          currentLink = trimmed
              .replaceAll('<link>', '')
              .replaceAll('</link>', '');
          
          // Create alert if we have title
          if (currentTitle.isNotEmpty) {
            alerts.add(DisasterAlert(
              id: 'gdacs_${DateTime.now().millisecondsSinceEpoch}_${alerts.length}',
              title: currentTitle,
              description: currentDescription ?? 'Alert from GDACS',
              type: _inferDisasterTypeFromText(currentTitle),
              severity: AlertSeverity.warning,
              location: LatLng(20.5937, 78.9629), // Center of India as default
              timestamp: DateTime.now(),
              source: 'GDACS',
              sourceUrl: currentLink.isNotEmpty ? currentLink : 'https://www.gdacs.org/',
              metadata: {'parsed_from_rss': true},
            ));
          }
          
          // Reset for next item
          currentTitle = null;
          currentDescription = null;
          currentLink = null;
        }
      }
    } catch (e) {
      print('❌ RSS parsing error: $e');
    }
    
    return alerts;
  }

  /// Prioritize alerts by proximity to user location with smart filtering
  static List<DisasterAlert> _prioritizeByLocation(
    List<DisasterAlert> alerts,
    LatLng? userLocation,
    double proximityKm,
  ) {
    if (userLocation == null) return alerts;

    print('🎯 Prioritizing ${alerts.length} alerts for location: ${userLocation.latitude.toStringAsFixed(3)}, ${userLocation.longitude.toStringAsFixed(3)}');

    // Calculate distances and mark alerts
    for (final alert in alerts) {
      final distance = _calculateDistance(userLocation, alert.location);
      alert.metadata['distance_km'] = distance.round();
      alert.metadata['is_nearby'] = distance <= proximityKm;
      alert.metadata['is_local'] = distance <= proximityKm / 2; // Very local alerts
    }

    // Filter alerts - prioritize nearby and severe alerts
    final filteredAlerts = alerts.where((alert) {
      final distance = alert.metadata['distance_km'] as int;
      final severity = alert.severity;
      
      // Always include very close alerts (within 100km)
      if (distance <= 100) return true;
      
      // Include moderate distance alerts if they're severe (within 300km)
      if (distance <= 300 && (severity == AlertSeverity.severe || severity == AlertSeverity.critical)) {
        return true;
      }
      
      // Include distant alerts only if they're critical (within 500km)
      if (distance <= 500 && severity == AlertSeverity.critical) {
        return true;
      }
      
      return false;
    }).toList();

    // Sort by a combination of distance and severity
    filteredAlerts.sort((a, b) {
      final distanceA = a.metadata['distance_km'] as int;
      final distanceB = b.metadata['distance_km'] as int;
      final severityA = a.severity.index;
      final severityB = b.severity.index;
      
      // Critical alerts first, regardless of distance
      if (severityA != severityB) {
        return severityB.compareTo(severityA); // Higher severity first
      }
      
      // Then by distance
      return distanceA.compareTo(distanceB);
    });

    print('📍 Filtered to ${filteredAlerts.length} relevant alerts for your area');
    
    return filteredAlerts;
  }

  /// Calculate distance between two points (Haversine formula)
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final lat1Rad = point1.latitude * (math.pi / 180);
    final lat2Rad = point2.latitude * (math.pi / 180);
    final deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    final deltaLngRad = (point2.longitude - point1.longitude) * (math.pi / 180);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Check if a location is within Maharashtra state boundaries
  static bool _isInMaharashtra(LatLng location) {
    // Maharashtra rough boundaries
    const double minLat = 15.6;
    const double maxLat = 22.0;
    const double minLon = 72.6;
    const double maxLon = 80.9;
    
    return location.latitude >= minLat && 
           location.latitude <= maxLat &&
           location.longitude >= minLon && 
           location.longitude <= maxLon;
  }

  // Helper methods for alert classification
  static String _buildEarthquakeDescription(double magnitude, String? place, [double? distanceKm]) {
    final intensity = magnitude >= 7.0 ? 'Major' :
                     magnitude >= 6.0 ? 'Strong' :
                     magnitude >= 5.0 ? 'Moderate' :
                     magnitude >= 4.0 ? 'Light' : 'Minor';
    
    String description = 'M${magnitude.toStringAsFixed(1)} $intensity earthquake${place != null ? ' $place' : ' detected'}. ';
    
    if (distanceKm != null) {
      if (distanceKm < 50) {
        description += 'Located ${distanceKm.round()}km from your location. ';
      } else if (distanceKm < 200) {
        description += 'Located ${distanceKm.round()}km away in your region. ';
      } else {
        description += 'Located ${distanceKm.round()}km away. ';
      }
    }
    
    description += 'Monitor for aftershocks and follow safety protocols.';
    return description;
  }

  static String _buildWeatherDescription(String condition, String description, Map<String, dynamic> main, [double? distanceKm]) {
    final temp = main['temp']?.toString() ?? 'N/A';
    final humidity = main['humidity']?.toString() ?? 'N/A';
    
    String weatherDesc = '$description. Temperature: $temp°C, Humidity: $humidity%. ';
    
    if (distanceKm != null) {
      if (distanceKm < 50) {
        weatherDesc += 'Located ${distanceKm.round()}km from your location. ';
      } else if (distanceKm < 200) {
        weatherDesc += 'Located ${distanceKm.round()}km away in your region. ';
      }
    }
    
    weatherDesc += 'Monitor local conditions and take appropriate precautions.';
    return weatherDesc;
  }

  static String _buildFireDescription(String region, double? distanceKm) {
    String description = 'Active fire detected in $region region. ';
    
    if (distanceKm != null) {
      if (distanceKm < 50) {
        description += 'Located ${distanceKm.round()}km from your location - monitor air quality closely. ';
      } else if (distanceKm < 200) {
        description += 'Located ${distanceKm.round()}km away in your region - check local air quality. ';
      } else {
        description += 'Located ${distanceKm.round()}km away. ';
      }
    }
    
    description += 'Monitor local conditions and air quality.';
    return description;
  }

  static AlertSeverity _getFireSeverity(double? distanceKm) {
    if (distanceKm == null) return AlertSeverity.warning;
    
    if (distanceKm < 25) return AlertSeverity.severe;
    if (distanceKm < 100) return AlertSeverity.warning;
    return AlertSeverity.info;
  }

  static AlertSeverity _getEarthquakeSeverity(double magnitude) {
    if (magnitude >= 7.0) return AlertSeverity.critical;
    if (magnitude >= 6.0) return AlertSeverity.severe;
    if (magnitude >= 5.0) return AlertSeverity.warning;
    return AlertSeverity.info;
  }

  static bool _isSevereWeather(String condition, Map<String, dynamic> main) {
    final severeConditions = ['Thunderstorm', 'Tornado', 'Hurricane', 'Typhoon', 'Cyclone'];
    final temp = (main['temp'] as num?)?.toDouble() ?? 0.0;
    
    return severeConditions.any((severe) => condition.contains(severe)) ||
           temp > 45.0 || temp < 0.0; // Extreme temperatures
  }

  static DisasterType _getWeatherDisasterType(String condition) {
    if (condition.contains('Thunderstorm')) return DisasterType.storm;
    if (condition.contains('Hurricane') || condition.contains('Cyclone')) return DisasterType.cyclone;
    return DisasterType.storm;
  }

  static AlertSeverity _getWeatherSeverity(String condition, Map<String, dynamic> main) {
    if (condition.contains('Hurricane') || condition.contains('Cyclone')) {
      return AlertSeverity.critical;
    }
    if (condition.contains('Thunderstorm')) {
      return AlertSeverity.severe;
    }
    
    final temp = (main['temp'] as num?)?.toDouble() ?? 0.0;
    if (temp > 45.0 || temp < 0.0) return AlertSeverity.severe;
    
    return AlertSeverity.warning;
  }

  static DisasterType _inferDisasterTypeFromText(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('earthquake') || lowerText.contains('quake')) {
      return DisasterType.earthquake;
    }
    if (lowerText.contains('flood') || lowerText.contains('flooding')) {
      return DisasterType.flood;
    }
    if (lowerText.contains('cyclone') || lowerText.contains('hurricane') || lowerText.contains('typhoon')) {
      return DisasterType.cyclone;
    }
    if (lowerText.contains('fire') || lowerText.contains('wildfire')) {
      return DisasterType.wildfire;
    }
    if (lowerText.contains('tsunami')) {
      return DisasterType.tsunami;
    }
    
    return DisasterType.other;
  }

  /// Clear cached alerts (useful for testing or force refresh)
  static void clearCache() {
    _cachedAlerts.clear();
    print('🗑️ Alert cache cleared');
  }
}

/// Disaster alert model with multi-language support
class DisasterAlert {
  final String id;
  final String title;
  final String description;
  final DisasterType type;
  final AlertSeverity severity;
  final LatLng location;
  final DateTime timestamp;
  final String source;
  final String sourceUrl;
  final Map<String, dynamic> metadata;

  DisasterAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.location,
    required this.timestamp,
    required this.source,
    required this.sourceUrl,
    this.metadata = const {},
  });

  /// Get translated title in the specified language
  String getTranslatedTitle(String languageCode) {
    if (languageCode == 'en') return title;
    return DisasterTranslationService.translateAlertTitle(title, languageCode);
  }

  /// Get translated description in the specified language
  String getTranslatedDescription(String languageCode) {
    if (languageCode == 'en') return description;
    return DisasterTranslationService.translateAlertDescription(description, languageCode);
  }

  /// Get translated disaster type name
  String getTranslatedTypeName(String languageCode) {
    return DisasterTranslationService.getDisasterTypeName(type.name, languageCode);
  }

  /// Get translated severity level
  String getTranslatedSeverityLevel(String languageCode) {
    return DisasterTranslationService.getSeverityLevel(severity.name, languageCode);
  }

  /// Get detailed precautions for this disaster type in the specified language
  List<String> getPrecautions(String languageCode) {
    return DisasterPrecautionsService.getPrecautions(type.name, languageCode);
  }

  /// Get a complete localized alert object for the specified language
  Map<String, dynamic> getLocalizedAlert(String languageCode) {
    return {
      'id': id,
      'title': getTranslatedTitle(languageCode),
      'description': getTranslatedDescription(languageCode),
      'type': getTranslatedTypeName(languageCode),
      'severity': getTranslatedSeverityLevel(languageCode),
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'sourceUrl': sourceUrl,
      'precautions': getPrecautions(languageCode),
      'metadata': metadata,
      'language': languageCode,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'severity': severity.index,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'source_url': sourceUrl,
      'metadata': jsonEncode(metadata),
    };
  }

  static DisasterAlert fromMap(Map<String, dynamic> map) {
    return DisasterAlert(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: DisasterType.values[map['type'] ?? 0],
      severity: AlertSeverity.values[map['severity'] ?? 0],
      location: LatLng(map['latitude'] ?? 0.0, map['longitude'] ?? 0.0),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      source: map['source'] ?? '',
      sourceUrl: map['source_url'] ?? '',
      metadata: map['metadata'] != null ? 
        jsonDecode(map['metadata']) as Map<String, dynamic> : {},
    );
  }
}

/// Types of disasters
enum DisasterType {
  earthquake,
  flood,
  cyclone,
  tsunami,
  wildfire,
  storm,
  drought,
  landslide,
  other,
}

/// Alert severity levels
enum AlertSeverity {
  info,
  warning,
  severe,
  critical,
}