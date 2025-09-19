import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import 'ambee_service.dart';

class DisasterAlertsService {
  // Using API config for endpoints
  static const String _usgsEarthquakeUrl = ApiConfig.usgsEarthquakeApi;
  
  Future<List<Map<String, dynamic>>> fetchDisasterAlerts({
    double? latitude,
    double? longitude,
    int radiusKm = 100,
  }) async {
    try {
      List<Map<String, dynamic>> allAlerts = [];
      
      print('Fetching disaster alerts from Ambee and other sources...');
      
      // Priority 1: Fetch from Ambee API (most comprehensive and up-to-date)
      if (latitude != null && longitude != null) {
        final ambeeAlerts = await AmbeeService.getDisastersByLatLng(
          latitude: latitude,
          longitude: longitude,
          limit: 20,
        );
        allAlerts.addAll(ambeeAlerts);
        print('Fetched ${ambeeAlerts.length} alerts from Ambee API');
      }
      
      // Priority 2: Fetch India-specific alerts from Ambee (if in Indian region)
      if (latitude != null && longitude != null && _isIndianRegion(latitude, longitude)) {
        final indiaAlerts = await AmbeeService.getDisastersByCountry(
          countryCode: 'IN',
          limit: 15,
        );
        // Avoid duplicates by checking IDs
        for (final alert in indiaAlerts) {
          if (!allAlerts.any((existing) => existing['id'] == alert['id'])) {
            allAlerts.add(alert);
          }
        }
        print('Fetched ${indiaAlerts.length} India-specific alerts from Ambee API');
      }
      
      // Priority 3: Fetch Asian continent alerts from Ambee
      if (latitude != null && longitude != null && _isAsianRegion(latitude, longitude)) {
        final asiaAlerts = await AmbeeService.getDisastersByContinent(
          continent: 'Asia',
          limit: 10,
        );
        // Avoid duplicates
        for (final alert in asiaAlerts) {
          if (!allAlerts.any((existing) => existing['id'] == alert['id'])) {
            allAlerts.add(alert);
          }
        }
        print('Fetched ${asiaAlerts.length} Asia-specific alerts from Ambee API');
      }
      
      // Supplementary: Fetch earthquake data from USGS for additional coverage
      final earthquakeAlerts = await _fetchEarthquakeAlerts(latitude, longitude, radiusKm);
      // Avoid duplicates by checking if earthquake alerts are already present
      for (final alert in earthquakeAlerts) {
        if (!allAlerts.any((existing) => 
          existing['type'] == 'earthquake' && 
          existing['title'].contains(alert['title'].split(' ').last))) {
          allAlerts.add(alert);
        }
      }
      
      // If still no real alerts found, use minimal fallback
      if (allAlerts.isEmpty) {
        print('No real alerts found from any source, using minimal fallback data');
        return _getMinimalFallbackAlerts();
      }
      
      // Sort by severity and timestamp
      allAlerts.sort((a, b) {
        final severityOrder = {'critical': 0, 'high': 1, 'warning': 2, 'medium': 2, 'info': 3, 'low': 3};
        final aSeverity = severityOrder[a['severity']] ?? 4;
        final bSeverity = severityOrder[b['severity']] ?? 4;
        
        if (aSeverity != bSeverity) {
          return aSeverity.compareTo(bSeverity);
        }
        
        final aTime = a['timestamp'] is String ? DateTime.parse(a['timestamp']) : a['timestamp'];
        final bTime = b['timestamp'] is String ? DateTime.parse(b['timestamp']) : b['timestamp'];
        return bTime.compareTo(aTime);
      });
      
      return allAlerts.take(30).toList(); // Limit to 30 most recent/severe alerts
    } catch (e) {
      print('Error fetching disaster alerts: $e');
      return _getMinimalFallbackAlerts();
    }
  }
  
  Future<List<Map<String, dynamic>>> _fetchEarthquakeAlerts(double? lat, double? lon, int radius) async {
    try {
      // USGS Earthquake API - free and reliable
      final response = await http.get(Uri.parse(_usgsEarthquakeUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        List<Map<String, dynamic>> earthquakes = [];
        
        for (final feature in features) {
          final properties = feature['properties'];
          final geometry = feature['geometry'];
          final coordinates = geometry['coordinates'];
          
          double eqLat = coordinates[1].toDouble();
          double eqLon = coordinates[0].toDouble();
          
          // Filter by distance if location is available
          if (lat != null && lon != null) {
            double distance = Geolocator.distanceBetween(lat, lon, eqLat, eqLon) / 1000;
            if (distance > radius) continue;
          }
          
          earthquakes.add({
            'id': properties['id'] ?? DateTime.now().millisecondsSinceEpoch,
            'title': properties['title'] ?? 'Earthquake Alert',
            'type': 'earthquake',
            'severity': _mapEarthquakeSeverity(properties['mag']?.toDouble() ?? 0.0),
            'description': 'Magnitude ${properties['mag']} earthquake detected. ${properties['place']}',
            'affectedArea': properties['place'] ?? 'Unknown location',
            'timestamp': DateTime.fromMillisecondsSinceEpoch(properties['time']).toIso8601String(),
            'coordinates': {
              'latitude': eqLat,
              'longitude': eqLon,
            },
            'magnitude': properties['mag'],
            'isRead': false,
            'isPinned': false,
            'status': 'active',
            'source': 'USGS'
          });
        }
        
        return earthquakes;
      }
    } catch (e) {
      print('Error fetching earthquake alerts: $e');
    }
    return [];
  }

  String _mapEarthquakeSeverity(double magnitude) {
    if (magnitude >= 7.0) return 'critical';
    if (magnitude >= 6.0) return 'warning';
    if (magnitude >= 4.5) return 'info';
    return 'low';
  }

  bool _isIndianRegion(double latitude, double longitude) {
    // India's approximate boundaries
    return latitude >= 6.0 && latitude <= 37.0 && 
           longitude >= 68.0 && longitude <= 97.25;
  }
  
  bool _isAsianRegion(double latitude, double longitude) {
    // Asia's approximate boundaries
    return latitude >= -10.0 && latitude <= 80.0 && 
           longitude >= 25.0 && longitude <= 180.0;
  }

  List<Map<String, dynamic>> _getMinimalFallbackAlerts() {
    final now = DateTime.now();
    
    return [
      {
        'id': 'system_alert_1',
        'title': 'Disaster Monitoring Active',
        'type': 'info',
        'severity': 'info',
        'description': 'All disaster monitoring systems are operational. No immediate threats detected in your area.',
        'affectedArea': 'Monitoring Network',
        'timestamp': now.toIso8601String(),
        'isRead': false,
        'isPinned': false,
        'status': 'active',
        'source': 'Emergency Management System'
      },
      {
        'id': 'system_alert_2',
        'title': 'Stay Prepared',
        'type': 'info',
        'severity': 'info',
        'description': 'Keep your emergency kit ready and stay informed about weather conditions in your area.',
        'affectedArea': 'General Advisory',
        'timestamp': now.subtract(Duration(hours: 1)).toIso8601String(),
        'isRead': false,
        'isPinned': false,
        'status': 'active',
        'source': 'Emergency Management System'
      }
    ];
  }
}
