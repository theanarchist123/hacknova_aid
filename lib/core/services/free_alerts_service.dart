import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Free disaster alerts service using CORS-safe APIs
/// Combines USGS (earthquakes) + NASA EONET (multi-hazard) + ReliefWeb (curated incidents)
class FreeAlertsService {
  static final FreeAlertsService instance = FreeAlertsService._();
  FreeAlertsService._();

  /// Fetch disaster alerts near a location from multiple free, CORS-safe sources
  Future<List<Map<String, dynamic>>> fetchAlertsNear({
    required double lat,
    required double lon,
    int days = 7,
    int radiusKm = 500,
  }) async {
    print('🚨 Fetching disaster alerts for ($lat, $lon) within ${radiusKm}km, last $days days');
    
    final now = DateTime.now().toUtc();
    final startTime = now.subtract(Duration(days: days)).toIso8601String();

    // Fetch from all sources in parallel
    final futures = <Future<List<Map<String, dynamic>>>>[
      _fetchUSGSEarthquakes(lat, lon, radiusKm, startTime)
          .catchError((e) {
            print('❌ USGS failed: $e');
            return <Map<String, dynamic>>[];
          }),
      _fetchNASAEONET(lat, lon, days)
          .catchError((e) {
            print('❌ NASA EONET failed: $e');
            return <Map<String, dynamic>>[];
          }),
      _fetchReliefWebDisasters(lat, lon)
          .catchError((e) {
            print('❌ ReliefWeb failed: $e');
            return <Map<String, dynamic>>[];
          }),
    ];

    final results = await Future.wait(futures, eagerError: false);
    final allAlerts = <Map<String, dynamic>>[];
    
    // Combine results from all sources
    for (final alertList in results) {
      allAlerts.addAll(alertList);
    }

    // Remove alerts without timestamps and deduplicate
    allAlerts.removeWhere((alert) => alert['timestamp'] == null);
    final deduplicated = _deduplicateAlerts(allAlerts);
    
    // Sort by timestamp (newest first)
    deduplicated.sort((a, b) {
      final timeA = _parseDate(a['timestamp']);
      final timeB = _parseDate(b['timestamp']);
      return timeB.compareTo(timeA);
    });

    print('✅ Found ${deduplicated.length} total alerts from all sources');
    return deduplicated;
  }

  /// Fetch real-time earthquake data from USGS (global coverage, no API key)
  Future<List<Map<String, dynamic>>> _fetchUSGSEarthquakes(
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

    print('📡 Fetching USGS earthquakes: $url');
    
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
    
    final earthquakes = features.map<Map<String, dynamic>>((feature) {
      final properties = feature['properties'] ?? {};
      final coordinates = (feature['geometry']?['coordinates'] as List?) ?? [];
      
      final magnitude = (properties['mag'] as num?)?.toDouble();
      final eventTime = properties['time'] as int?;
      final timestamp = eventTime != null 
          ? DateTime.fromMillisecondsSinceEpoch(eventTime, isUtc: true).toIso8601String()
          : null;
      
      // Calculate distance if coordinates available
      double? distanceKm;
      if (coordinates.length >= 2) {
        final eventLon = (coordinates[0] as num).toDouble();
        final eventLat = (coordinates[1] as num).toDouble();
        distanceKm = Geolocator.distanceBetween(lat, lon, eventLat, eventLon) / 1000;
      }
      
      return {
        'id': 'usgs_${properties['code'] ?? properties['time'] ?? DateTime.now().millisecondsSinceEpoch}',
        'title': 'Earthquake M${magnitude?.toStringAsFixed(1) ?? '?'} - ${properties['place'] ?? 'Unknown location'}',
        'type': 'earthquake',
        'category': 'geological',
        'description': properties['title'] ?? 'Earthquake detected',
        'severity': _getEarthquakeSeverity(magnitude),
        'severityLevel': _getEarthquakeSeverityLevel(magnitude),
        'source': 'USGS Earthquake Hazards Program',
        'sourceUrl': properties['url'],
        'lat': coordinates.length >= 2 ? (coordinates[1] as num).toDouble() : null,
        'lon': coordinates.length >= 2 ? (coordinates[0] as num).toDouble() : null,
        'timestamp': timestamp,
        'distance_km': distanceKm,
        'magnitude': magnitude,
        'depth': coordinates.length >= 3 ? (coordinates[2] as num?)?.toDouble() : null,
        'location': properties['place'],
        'status': properties['status'],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }).toList();

    print('🌍 USGS: Found ${earthquakes.length} earthquakes');
    return earthquakes;
  }

  /// Fetch multi-hazard events from NASA EONET (wildfires, storms, volcanoes, etc.)
  Future<List<Map<String, dynamic>>> _fetchNASAEONET(
    double lat,
    double lon,
    int days,
  ) async {
    final url = Uri.parse('https://eonet.gsfc.nasa.gov/api/v3/events?status=open&days=$days');

    print('🛰️ Fetching NASA EONET events: $url');
    
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
      final distanceKm = Geolocator.distanceBetween(lat, lon, eventLat, eventLon) / 1000;

      // Get event category
      final categories = (event['categories'] as List?) ?? [];
      final primaryCategory = categories.isNotEmpty ? categories[0] : {};
      final categoryTitle = primaryCategory['title']?.toString().toLowerCase() ?? 'natural event';
      
      disasters.add({
        'id': 'eonet_${event['id'] ?? DateTime.now().millisecondsSinceEpoch}',
        'title': event['title'] ?? 'Natural Event',
        'type': _mapEONETCategory(categoryTitle),
        'category': categoryTitle,
        'description': event['description'] ?? event['title'] ?? 'Natural disaster event',
        'severity': _getEONETSeverity(categoryTitle),
        'severityLevel': _getEONETSeverityLevel(categoryTitle),
        'source': 'NASA Earth Observatory Natural Event Tracker',
        'sourceUrl': event['link'] ?? 'https://eonet.gsfc.nasa.gov/',
        'lat': eventLat,
        'lon': eventLon,
        'timestamp': bestGeometry['date'],
        'distance_km': distanceKm,
        'eonetId': event['id'],
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }

    print('🛰️ NASA EONET: Found ${disasters.length} natural events');
    return disasters;
  }

  /// Fetch curated disaster information from ReliefWeb (UN OCHA)
  Future<List<Map<String, dynamic>>> _fetchReliefWebDisasters(
    double lat,
    double lon,
  ) async {
    final url = Uri.parse(
      'https://api.reliefweb.int/v1/disasters'
      '?appname=disaster-aid&limit=25&profile=lite&sort[]=date:desc',
    );

    print('🆘 Fetching ReliefWeb disasters: $url');
    
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    ).timeout(Duration(seconds: 15));

    if (response.statusCode != 200) {
      print('❌ ReliefWeb HTTP ${response.statusCode}');
      return [];
    }

    final data = json.decode(response.body);
    final disasters = ((data['data'] as List?) ?? []).map<Map<String, dynamic>>((item) {
      final fields = item['fields'] ?? {};
      final countries = (fields['country'] as List?) ?? [];
      final types = (fields['type'] as List?) ?? [];
      
      final countryName = countries.isNotEmpty ? countries[0]['name'] : 'Unknown';
      final disasterType = types.isNotEmpty ? types[0]['name'].toString().toLowerCase() : 'disaster';
      
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
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }).toList();

    print('🆘 ReliefWeb: Found ${disasters.length} disaster reports');
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
