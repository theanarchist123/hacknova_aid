import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'indian_alerts_formatter.dart';
import 'india_alert_sources.dart';

/// Free disaster alerts service using CORS-safe APIs
/// Combines USGS (earthquakes) + NASA EONET (multi-hazard) + ReliefWeb (curated incidents)
/// Focuses on India and surrounding regions
class FreeAlertsService {
  static final FreeAlertsService instance = FreeAlertsService._();
  FreeAlertsService._();

  // India geographic boundaries (approximate bounding box)
  static const double _indiaMinLat = 6.5;    // Southern tip (near Kanyakumari)
  static const double _indiaMaxLat = 37.1;   // Northern tip (Kashmir/Ladakh)
  static const double _indiaMinLon = 68.0;   // Western border (Gujarat/Rajasthan)
  static const double _indiaMaxLon = 97.5;   // Eastern border (Arunachal Pradesh)
  
  // Extended boundaries for regional alerts (neighboring countries)
  static const double _regionMinLat = 4.0;   // Include Sri Lanka
  static const double _regionMaxLat = 40.0;  // Include parts of China/Pakistan
  static const double _regionMinLon = 60.0;  // Include parts of Iran/Afghanistan
  static const double _regionMaxLon = 100.0; // Include Myanmar/Bangladesh

  /// Fetch disaster alerts near a location from multiple free, CORS-safe sources
  /// Prioritizes alerts within India and filters out non-relevant foreign alerts
  /// Uses news-style headlines instead of technical coordinate descriptions
  Future<List<Map<String, dynamic>>> fetchAlertsNear({
    required double lat,
    required double lon,
    int days = 7,
    int radiusKm = 500,
  }) async {
    print('🇮🇳 Fetching India-focused disaster alerts with news headlines for ($lat, $lon)');
    
    final now = DateTime.now().toUtc();
    final startTime = now.subtract(Duration(days: days)).toIso8601String();

    // Check if user is in India for optimized search
    final isUserInIndia = IndianAlertsFormatter.isInIndia(lat, lon);
    final searchRadius = isUserInIndia ? radiusKm : min(radiusKm * 2, 800); // Expand if outside India
    
    // Fetch from India-specific sources first (highest priority)
    final indiaSourcesFutures = <Future<List<Map<String, dynamic>>>>[
      IndiaAlertSources.fetchReliefWebIndia(limit: 20)
          .catchError((e) {
            print('❌ ReliefWeb India reports failed: $e');
            return <Map<String, dynamic>>[];
          }),
      IndiaAlertSources.fetchReliefWebIndiaDisasters(limit: 15)
          .catchError((e) {
            print('❌ ReliefWeb India disasters failed: $e');
            return <Map<String, dynamic>>[];
          }),
      IndiaAlertSources.fetchGdacsIndia(days: days)
          .catchError((e) {
            print('❌ GDACS India failed: $e');
            return <Map<String, dynamic>>[];
          }),
    ];
    
    // Fetch from global sources with India filtering (secondary priority)
    final globalSourcesFutures = <Future<List<Map<String, dynamic>>>>[
      _fetchUSGSEarthquakesWithHeadlines(lat, lon, searchRadius, startTime)
          .catchError((e) {
            print('❌ USGS earthquakes failed: $e');
            return <Map<String, dynamic>>[];
          }),
      _fetchNASAEONETWithHeadlines(lat, lon, days)
          .catchError((e) {
            print('❌ NASA EONET failed: $e');
            return <Map<String, dynamic>>[];
          }),
    ];

    // Execute India sources first
    final indiaResults = await Future.wait(indiaSourcesFutures, eagerError: false);
    final globalResults = await Future.wait(globalSourcesFutures, eagerError: false);
    
    final allAlerts = <Map<String, dynamic>>[];
    
    // Add India-specific alerts first (highest priority)
    for (final alertList in indiaResults) {
      allAlerts.addAll(alertList);
    }
    
    // Add global alerts filtered for India relevance
    for (final alertList in globalResults) {
      allAlerts.addAll(alertList);
    }

    // Filter for India-relevant alerts only
    final indiaAlerts = _filterForIndiaRelevance(allAlerts, lat, lon);

    // Remove alerts without timestamps and deduplicate
    indiaAlerts.removeWhere((alert) => alert['timestamp'] == null);
    final deduplicated = _deduplicateAlerts(indiaAlerts);
    
    // Sort by relevance: India priority + distance + recency
    _sortByIndiaRelevance(deduplicated, lat, lon);

    print('✅ Found ${deduplicated.length} India-relevant alerts with news headlines');
    return deduplicated;
  }

  /// Fetch real-time earthquake data from USGS with news-style headlines
  Future<List<Map<String, dynamic>>> _fetchUSGSEarthquakesWithHeadlines(
    double lat,
    double lon,
    int radiusKm,
    String startTime,
  ) async {
    final url = Uri.parse(
      'https://earthquake.usgs.gov/fdsnws/event/1/query'
      '?format=geojson&latitude=$lat&longitude=$lon'
      '&maxradiuskm=$radiusKm&starttime=$startTime',
    );

    print('📡 Fetching USGS earthquakes with headlines: $url');
    
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    ).timeout(Duration(seconds: 15));

    if (response.statusCode != 200) {
      print('❌ USGS HTTP ${response.statusCode}');
      return [];
    }

    final data = json.decode(response.body);
    final features = (data['features'] as List?) ?? [];
    
    final earthquakes = <Map<String, dynamic>>[];
    
    for (final feature in features) {
      final properties = feature['properties'] ?? {};
      final coordinates = (feature['geometry']?['coordinates'] as List?) ?? [];
      
      if (coordinates.length < 2) continue;
      
      final eventLon = (coordinates[0] as num).toDouble();
      final eventLat = (coordinates[1] as num).toDouble();
      
      // Only include earthquakes in or near India
      if (!IndianAlertsFormatter.isInIndia(eventLat, eventLon)) {
        // Allow nearby earthquakes that might be felt in India
        final distance = IndianAlertsFormatter.calculateDistance(lat, lon, eventLat, eventLon);
        if (distance > 500) continue;
      }
      
      final magnitude = (properties['mag'] as num?)?.toDouble();
      final eventTime = properties['time'] as int?;
      final timestamp = eventTime != null 
          ? DateTime.fromMillisecondsSinceEpoch(eventTime, isUtc: true)
          : DateTime.now();
      
      // Create news-style headline
      final (title, description) = await IndianAlertsFormatter.buildHeadline(
        type: 'earthquake',
        time: timestamp,
        lat: eventLat,
        lon: eventLon,
        magnitude: magnitude,
        originalTitle: properties['title']?.toString(),
      );
      
      final distanceKm = IndianAlertsFormatter.calculateDistance(lat, lon, eventLat, eventLon);
      final (severity, severityLevel) = IndianAlertsFormatter.getEarthquakeSeverity(magnitude);
      
      earthquakes.add({
        'id': 'usgs_${properties['code'] ?? properties['time'] ?? DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'description': description,
        'type': 'earthquake',
        'category': 'geological',
        'severity': severity,
        'severityLevel': severityLevel,
        'source': 'USGS Earthquake Hazards Program',
        'sourceUrl': properties['url'],
        'lat': eventLat,
        'lon': eventLon,
        'timestamp': timestamp.toIso8601String(),
        'distance_km': distanceKm,
        'magnitude': magnitude,
        'depth': coordinates.length >= 3 ? (coordinates[2] as num?)?.toDouble() : null,
        'location': properties['place'],
        'status': properties['status'],
        'priority': IndianAlertsFormatter.isInIndia(eventLat, eventLon) ? 1 : 2,
        'isIndiaRelated': IndianAlertsFormatter.isInIndia(eventLat, eventLon),
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }

    print('🌍 USGS: Found ${earthquakes.length} earthquakes with headlines');
    return earthquakes;
  }

  /// Fetch multi-hazard events from NASA EONET with news-style headlines
  Future<List<Map<String, dynamic>>> _fetchNASAEONETWithHeadlines(
    double lat,
    double lon,
    int days,
  ) async {
    final url = Uri.parse('https://eonet.gsfc.nasa.gov/api/v3/events?status=open&days=$days');

    print('🛰️ Fetching NASA EONET events with headlines: $url');
    
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    ).timeout(Duration(seconds: 15));

    if (response.statusCode != 200) {
      print('❌ NASA EONET HTTP ${response.statusCode}');
      return [];
    }

    final data = json.decode(response.body);
    final events = (data['events'] as List?) ?? [];

    final disasters = <Map<String, dynamic>>[];
    
    for (final event in events) {
      final geometries = (event['geometry'] as List?) ?? [];
      if (geometries.isEmpty) continue;

      // Find the most recent geometry with point coordinates
      Map<String, dynamic>? bestGeometry;
      for (final geometry in geometries.reversed) {
        final coordinates = geometry['coordinates'];
        if (coordinates is List && coordinates.length >= 2 && 
            coordinates[0] is num && coordinates[1] is num) {
          bestGeometry = {
            'lon': (coordinates[0] as num).toDouble(),
            'lat': (coordinates[1] as num).toDouble(),
            'date': geometry['date'],
          };
          break;
        }
      }

      if (bestGeometry == null) continue;

      final eventLat = bestGeometry['lat'] as double;
      final eventLon = bestGeometry['lon'] as double;
      
      // Only include events in or near India
      if (!IndianAlertsFormatter.isInIndia(eventLat, eventLon)) {
        final distance = IndianAlertsFormatter.calculateDistance(lat, lon, eventLat, eventLon);
        if (distance > 800) continue;
      }

      final distanceKm = IndianAlertsFormatter.calculateDistance(lat, lon, eventLat, eventLon);

      // Get event category
      final categories = (event['categories'] as List?) ?? [];
      final primaryCategory = categories.isNotEmpty ? categories[0] : {};
      final categoryTitle = primaryCategory['title']?.toString().toLowerCase() ?? 'natural event';
      
      final eventTime = DateTime.tryParse(bestGeometry['date']) ?? DateTime.now();
      
      // Create news-style headline
      final (title, description) = await IndianAlertsFormatter.buildHeadline(
        type: _mapEONETCategory(categoryTitle),
        time: eventTime,
        lat: eventLat,
        lon: eventLon,
        originalTitle: event['title']?.toString(),
      );
      
      disasters.add({
        'id': 'eonet_${event['id'] ?? DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'description': description,
        'type': _mapEONETCategory(categoryTitle),
        'category': categoryTitle,
        'severity': _getEONETSeverity(categoryTitle),
        'severityLevel': _getEONETSeverityLevel(categoryTitle),
        'source': 'NASA Earth Observatory Natural Event Tracker',
        'sourceUrl': event['link'] ?? 'https://eonet.gsfc.nasa.gov/',
        'lat': eventLat,
        'lon': eventLon,
        'timestamp': bestGeometry['date'],
        'distance_km': distanceKm,
        'eonetId': event['id'],
        'priority': IndianAlertsFormatter.isInIndia(eventLat, eventLon) ? 1 : 2,
        'isIndiaRelated': IndianAlertsFormatter.isInIndia(eventLat, eventLon),
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }

    print('🛰️ NASA EONET: Found ${disasters.length} natural events with headlines');
    return disasters;
  }

  /// Fetch curated disaster information from ReliefWeb (UN OCHA)
  /// Prioritizes disasters in India and neighboring countries
  Future<List<Map<String, dynamic>>> _fetchReliefWebDisasters(
    double lat,
    double lon,
  ) async {
    // First try to get India-specific disasters
    var url = Uri.parse(
      'https://api.reliefweb.int/v1/disasters'
      '?appname=disaster-aid&limit=50&profile=lite&sort[]=date:desc'
      '&filter[field]=country.iso3&filter[value]=IND', // India ISO code
    );

    print('�🇳 Fetching ReliefWeb disasters for India: $url');
    
    var response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    ).timeout(Duration(seconds: 15));

    List<dynamic> allDisasters = [];
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      allDisasters.addAll((data['data'] as List?) ?? []);
      print('🇮🇳 Found ${allDisasters.length} India-specific disasters');
    }

    // Also get general recent disasters (may include neighboring countries affecting India)
    url = Uri.parse(
      'https://api.reliefweb.int/v1/disasters'
      '?appname=disaster-aid&limit=25&profile=lite&sort[]=date:desc',
    );

    print('🌏 Fetching additional ReliefWeb disasters: $url');
    
    response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    ).timeout(Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      allDisasters.addAll((data['data'] as List?) ?? []);
    }

    if (allDisasters.isEmpty) {
      print('❌ ReliefWeb: No disasters found');
      return [];
    }

    final disasters = allDisasters.map<Map<String, dynamic>>((item) {
      final fields = item['fields'] ?? {};
      final countries = (fields['country'] as List?) ?? [];
      final types = (fields['type'] as List?) ?? [];
      
      final countryName = countries.isNotEmpty ? countries[0]['name'] : 'Unknown';
      final disasterType = types.isNotEmpty ? types[0]['name'].toString().toLowerCase() : 'disaster';
      
      // Check if this is an India-related disaster
      final isIndiaRelated = countryName.toLowerCase().contains('india') ||
                           countries.any((c) => c['iso3'] == 'IND');
      
      return {
        'id': 'reliefweb_${item['id'] ?? DateTime.now().millisecondsSinceEpoch}',
        'title': fields['name'] ?? 'Disaster Event',
        'type': _mapReliefWebType(disasterType),
        'category': disasterType,
        'description': fields['description'] ?? fields['name'] ?? 'Disaster reported by UN OCHA',
        'severity': 'warning', // ReliefWeb events are typically significant
        'severityLevel': 3,
        'source': 'ReliefWeb (UN OCHA)',
        'sourceUrl': fields['url'] ?? 'https://reliefweb.int/',
        'lat': null, // ReliefWeb often doesn't provide precise coordinates
        'lon': null,
        'timestamp': fields['date']?['created'] ?? 
                    fields['date']?['event'] ?? 
                    fields['date']?['changed'] ?? 
                    DateTime.now().toIso8601String(),
        'distance_km': null,
        'country': countryName,
        'reliefwebId': item['id'],
        'isIndiaRelated': isIndiaRelated,
        'priority': isIndiaRelated ? 1 : 3,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }).toList();

    print('🆘 ReliefWeb: Found ${disasters.length} total disaster reports');
    return disasters;
  }

  /// Remove duplicate alerts based on similarity
  List<Map<String, dynamic>> _deduplicateAlerts(List<Map<String, dynamic>> alerts) {
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    
    for (final alert in alerts) {
      final key = '${alert['type']}_${alert['title']}_${alert['lat']}_${alert['lon']}';
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(alert);
      }
    }
    
    return unique;
  }

  /// Check if coordinates are within India's boundaries
  bool _isInIndia(double lat, double lon) {
    return lat >= _indiaMinLat && lat <= _indiaMaxLat &&
           lon >= _indiaMinLon && lon <= _indiaMaxLon;
  }

  /// Check if coordinates are within the extended region (India + neighboring areas)
  bool _isInRegion(double lat, double lon) {
    return lat >= _regionMinLat && lat <= _regionMaxLat &&
           lon >= _regionMinLon && lon <= _regionMaxLon;
  }

  /// Filter alerts to only include those relevant to India
  List<Map<String, dynamic>> _filterForIndiaRelevance(
    List<Map<String, dynamic>> alerts, 
    double userLat, 
    double userLon
  ) {
    final relevantAlerts = <Map<String, dynamic>>[];
    
    for (final alert in alerts) {
      final alertLat = alert['lat'] as double?;
      final alertLon = alert['lon'] as double?;
      
      // If no coordinates, check if it mentions India in the content
      if (alertLat == null || alertLon == null) {
        final title = alert['title']?.toString().toLowerCase() ?? '';
        final description = alert['description']?.toString().toLowerCase() ?? '';
        final location = alert['location']?.toString().toLowerCase() ?? '';
        final country = alert['country']?.toString().toLowerCase() ?? '';
        
        if (title.contains('india') || description.contains('india') || 
            location.contains('india') || country.contains('india') ||
            _containsIndianStates(title) || _containsIndianStates(description) ||
            _containsIndianStates(location)) {
          relevantAlerts.add(alert);
        }
        continue;
      }
      
      // Priority 1: Alerts within India
      if (_isInIndia(alertLat, alertLon)) {
        alert['priority'] = 1;
        relevantAlerts.add(alert);
        continue;
      }
      
      // Priority 2: Alerts in neighboring region that might affect India
      if (_isInRegion(alertLat, alertLon)) {
        final distanceKm = Geolocator.distanceBetween(userLat, userLon, alertLat, alertLon) / 1000;
        // Only include if reasonably close (could affect border areas)
        if (distanceKm <= 500) {
          alert['priority'] = 2;
          relevantAlerts.add(alert);
        }
      }
    }
    
    print('🇮🇳 Filtered to ${relevantAlerts.length} India-relevant alerts from ${alerts.length} total');
    return relevantAlerts;
  }

  /// Check if text contains Indian state or city names
  bool _containsIndianStates(String text) {
    final indianLocations = [
      'mumbai', 'delhi', 'bangalore', 'kolkata', 'chennai', 'hyderabad', 'pune', 'ahmedabad',
      'kerala', 'tamil nadu', 'karnataka', 'maharashtra', 'gujarat', 'rajasthan', 'punjab',
      'west bengal', 'odisha', 'bihar', 'uttar pradesh', 'madhya pradesh', 'haryana',
      'assam', 'jharkhand', 'kashmir', 'himachal pradesh', 'uttarakhand', 'goa',
      'andhra pradesh', 'telangana', 'manipur', 'meghalaya', 'nagaland', 'tripura',
      'arunachal pradesh', 'mizoram', 'sikkim', 'ladakh'
    ];
    
    return indianLocations.any((location) => text.contains(location));
  }

  /// Sort alerts by India relevance and proximity
  void _sortByIndiaRelevance(List<Map<String, dynamic>> alerts, double userLat, double userLon) {
    alerts.sort((a, b) {
      // First sort by priority (1 = within India, 2 = neighboring region)
      final priorityA = a['priority'] as int? ?? 3;
      final priorityB = b['priority'] as int? ?? 3;
      
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      
      // Then sort by distance from user
      final distanceA = a['distance_km'] as double? ?? double.infinity;
      final distanceB = b['distance_km'] as double? ?? double.infinity;
      
      if (distanceA != distanceB) {
        return distanceA.compareTo(distanceB);
      }
      
      // Finally sort by timestamp (newest first)
      final timeA = _parseDate(a['timestamp']);
      final timeB = _parseDate(b['timestamp']);
      return timeB.compareTo(timeA);
    });
  }

  /// Parse various date formats to DateTime
  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toUtc();
    }
    return DateTime.now().toUtc();
  }

  /// Get earthquake severity based on magnitude
  String _getEarthquakeSeverity(double? magnitude) {
    if (magnitude == null) return 'info';
    if (magnitude >= 7.0) return 'extreme';
    if (magnitude >= 6.0) return 'severe';
    if (magnitude >= 5.0) return 'moderate';
    if (magnitude >= 4.0) return 'minor';
    return 'info';
  }

  int _getEarthquakeSeverityLevel(double? magnitude) {
    if (magnitude == null) return 1;
    if (magnitude >= 7.0) return 5;
    if (magnitude >= 6.0) return 4;
    if (magnitude >= 5.0) return 3;
    if (magnitude >= 4.0) return 2;
    return 1;
  }

  /// Map EONET categories to standardized types
  String _mapEONETCategory(String category) {
    switch (category.toLowerCase()) {
      case 'wildfires':
        return 'wildfire';
      case 'severe storms':
        return 'storm';
      case 'volcanoes':
        return 'volcano';
      case 'floods':
        return 'flood';
      case 'drought':
        return 'drought';
      case 'dust and haze':
        return 'dust_storm';
      case 'snow':
        return 'snow';
      case 'temperature extremes':
        return 'extreme_temperature';
      case 'sea and lake ice':
        return 'ice';
      default:
        return 'natural_event';
    }
  }

  String _getEONETSeverity(String category) {
    switch (category.toLowerCase()) {
      case 'wildfires':
      case 'volcanoes':
        return 'severe';
      case 'severe storms':
      case 'floods':
        return 'moderate';
      case 'drought':
        return 'warning';
      default:
        return 'info';
    }
  }

  int _getEONETSeverityLevel(String category) {
    switch (category.toLowerCase()) {
      case 'wildfires':
      case 'volcanoes':
        return 4;
      case 'severe storms':
      case 'floods':
        return 3;
      case 'drought':
        return 2;
      default:
        return 1;
    }
  }

  /// Map ReliefWeb disaster types to standardized types  
  String _mapReliefWebType(String type) {
    switch (type.toLowerCase()) {
      case 'earthquake':
        return 'earthquake';
      case 'flood':
        return 'flood';
      case 'drought':
        return 'drought';
      case 'cyclone':
      case 'hurricane':
      case 'typhoon':
        return 'cyclone';
      case 'wildfire':
      case 'forest fire':
        return 'wildfire';
      case 'volcano':
        return 'volcano';
      case 'landslide':
        return 'landslide';
      case 'epidemic':
        return 'health_emergency';
      case 'conflict':
        return 'conflict';
      default:
        return 'disaster';
    }
  }

  /// Test connectivity to all services
  Future<Map<String, bool>> testConnectivity() async {
    final results = <String, bool>{};
    
    try {
      final usgsUrl = Uri.parse('https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&limit=1');
      final usgsResponse = await http.get(usgsUrl).timeout(Duration(seconds: 10));
      results['USGS'] = usgsResponse.statusCode == 200;
    } catch (e) {
      results['USGS'] = false;
    }

    try {
      final eonetUrl = Uri.parse('https://eonet.gsfc.nasa.gov/api/v3/events?limit=1');
      final eonetResponse = await http.get(eonetUrl).timeout(Duration(seconds: 10));
      results['NASA_EONET'] = eonetResponse.statusCode == 200;
    } catch (e) {
      results['NASA_EONET'] = false;
    }

    try {
      final reliefUrl = Uri.parse('https://api.reliefweb.int/v1/disasters?limit=1');
      final reliefResponse = await http.get(reliefUrl).timeout(Duration(seconds: 10));
      results['ReliefWeb'] = reliefResponse.statusCode == 200;
    } catch (e) {
      results['ReliefWeb'] = false;
    }

    print('🔗 Service connectivity: $results');
    return results;
  }
}
