import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';

class DisasterAlertsService {
  // Using API config for endpoints
  static const String _usgsEarthquakeUrl = ApiConfig.usgsEarthquakeApi;
  static const String _gdacsUrl = ApiConfig.gdacsApi;
  
  Future<List<Map<String, dynamic>>> fetchDisasterAlerts({
    double? latitude,
    double? longitude,
    int radiusKm = 100,
  }) async {
    try {
      List<Map<String, dynamic>> allAlerts = [];
      
      // For web platform, use enhanced mock data due to CORS restrictions
      if (kIsWeb) {
        print('Web platform detected - using enhanced mock data for disaster alerts');
        return _getEnhancedWebAlerts(latitude, longitude);
      }
      
      // Fetch earthquake data
      final earthquakeAlerts = await _fetchEarthquakeAlerts(latitude, longitude, radiusKm);
      allAlerts.addAll(earthquakeAlerts);
      
      // Fetch GDACS alerts (Global Disaster Alert and Coordination System)
      final gdacsAlerts = await _fetchGDACSAlerts(latitude, longitude);
      allAlerts.addAll(gdacsAlerts);
      
      // Fetch NASA fire data
      final fireAlerts = await _fetchFireAlerts(latitude, longitude);
      allAlerts.addAll(fireAlerts);
      
      // Add mock weather alerts until you get OpenWeatherMap API key
      final weatherAlerts = _getMockWeatherAlerts(latitude, longitude);
      allAlerts.addAll(weatherAlerts);
      
      // Sort by severity and timestamp
      allAlerts.sort((a, b) {
        final severityOrder = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
        final aSeverity = severityOrder[a['severity']] ?? 4;
        final bSeverity = severityOrder[b['severity']] ?? 4;
        
        if (aSeverity != bSeverity) {
          return aSeverity.compareTo(bSeverity);
        }
        
        return DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp']));
      });
      
      return allAlerts.take(20).toList(); // Limit to 20 most recent/severe alerts
    } catch (e) {
      print('Error fetching disaster alerts: $e');
      return _getFallbackAlerts(latitude, longitude);
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
            'latitude': eqLat,
            'longitude': eqLon,
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
  
  Future<List<Map<String, dynamic>>> _fetchGDACSAlerts(double? lat, double? lon) async {
    try {
      // GDACS API - free global disaster alerts
      final response = await http.get(Uri.parse(_gdacsUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['features'] != null) {
          final features = data['features'] as List;
          
          List<Map<String, dynamic>> disasters = [];
          
          for (final feature in features) {
            final properties = feature['properties'];
            
            disasters.add({
              'id': properties['eventid'] ?? DateTime.now().millisecondsSinceEpoch,
              'title': properties['name'] ?? 'Disaster Alert',
              'type': _mapGDACSEventType(properties['eventtype'] ?? 'disaster'),
              'severity': _mapGDACSSeverity(properties['alertlevel'] ?? 'Green'),
              'description': properties['description'] ?? 'Disaster event detected in the region.',
              'affectedArea': properties['country'] ?? 'Multiple regions',
              'timestamp': _parseGDACSDate(properties['fromdate']),
              'isRead': false,
              'isPinned': false,
              'status': 'active',
              'source': 'GDACS'
            });
          }
          
          return disasters;
        }
      }
    } catch (e) {
      print('Error fetching GDACS alerts: $e');
    }
    return [];
  }
  
  Future<List<Map<String, dynamic>>> _fetchFireAlerts(double? lat, double? lon) async {
    try {
      // NASA FIRMS API - free fire/hotspot data
      // For demo, using mock data. You can get free NASA FIRMS API key
      return _getMockFireAlerts(lat, lon);
    } catch (e) {
      print('Error fetching fire alerts: $e');
      return [];
    }
  }
  
  List<Map<String, dynamic>> _getMockWeatherAlerts(double? lat, double? lon) {
    // Mock weather alerts until you get OpenWeatherMap API key
    final now = DateTime.now();
    
    return [
      {
        'id': 'weather_${now.millisecondsSinceEpoch}',
        'title': 'Flash Flood Warning',
        'type': 'flood',
        'severity': 'critical',
        'description': 'Heavy rainfall expected in your area. Stay indoors and avoid low-lying areas.',
        'affectedArea': lat != null && lon != null ? 'Your Current Area' : 'Mumbai, Maharashtra',
        'timestamp': now.toIso8601String(),
        'isRead': false,
        'isPinned': false,
        'status': 'active',
        'source': 'Weather Service'
      }
    ];
  }
  
  List<Map<String, dynamic>> _getMockFireAlerts(double? lat, double? lon) {
    final now = DateTime.now();
    
    return [
      {
        'id': 'fire_${now.millisecondsSinceEpoch}',
        'title': 'Wildfire Alert',
        'type': 'fire',
        'severity': 'high',
        'description': 'Active wildfire detected. Evacuate if advised by authorities.',
        'affectedArea': lat != null && lon != null ? '25km from your location' : 'Forest Area',
        'timestamp': now.subtract(Duration(hours: 1)).toIso8601String(),
        'isRead': false,
        'isPinned': false,
        'status': 'active',
        'source': 'NASA FIRMS'
      }
    ];
  }
  
  String _mapEarthquakeSeverity(double magnitude) {
    if (magnitude >= 7.0) return 'critical';
    if (magnitude >= 6.0) return 'high';
    if (magnitude >= 4.5) return 'medium';
    return 'low';
  }
  
  String _mapGDACSEventType(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'fl': case 'flood': return 'flood';
      case 'tc': case 'cyclone': return 'cyclone';
      case 'eq': case 'earthquake': return 'earthquake';
      case 'ts': case 'tsunami': return 'tsunami';
      case 'vo': case 'volcano': return 'volcano';
      case 'dr': case 'drought': return 'drought';
      case 'wf': case 'wildfire': return 'fire';
      default: return 'disaster';
    }
  }
  
  String _mapGDACSSeverity(String alertLevel) {
    switch (alertLevel.toLowerCase()) {
      case 'red': return 'critical';
      case 'orange': return 'high';
      case 'yellow': return 'medium';
      case 'green': return 'low';
      default: return 'medium';
    }
  }
  
  String _parseGDACSDate(String? dateString) {
    if (dateString == null) return DateTime.now().toIso8601String();
    
    try {
      // Parse various GDACS date formats
      final date = DateTime.parse(dateString);
      return date.toIso8601String();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }
  
  List<Map<String, dynamic>> _getFallbackAlerts(double? lat, double? lon) {
    // Fallback alerts if all APIs fail
    final now = DateTime.now();
    
    return [
      {
        'id': 'fallback_1',
        'title': 'System Alert',
        'type': 'info',
        'severity': 'low',
        'description': 'Unable to fetch live alerts. Please check your internet connection.',
        'affectedArea': 'System',
        'timestamp': now.toIso8601String(),
        'isRead': false,
        'isPinned': false,
        'status': 'active',
        'source': 'System'
      }
    ];
  }
  
  List<Map<String, dynamic>> _getEnhancedWebAlerts(double? lat, double? lon) {
    // Enhanced web alerts with realistic disaster scenarios for Mumbai area
    final now = DateTime.now();
    
    return [
      {
        'id': 'web_monsoon_1',
        'title': 'Heavy Monsoon Rainfall Alert',
        'type': 'flood',
        'severity': 'critical',
        'description': 'Mumbai Metropolitan Region expects heavy to very heavy rainfall in next 24 hours. Waterlogging likely in low-lying areas. Avoid unnecessary travel.',
        'affectedArea': lat != null ? 'Mumbai Metropolitan Region' : 'Your Area',
        'timestamp': now.subtract(Duration(minutes: 30)).toIso8601String(),
        'isRead': false,
        'isPinned': false,
        'status': 'active',
        'source': 'IMD Mumbai'
      },
      {
        'id': 'web_cyclone_1',
        'title': 'Cyclonic Weather System',
        'type': 'cyclone',
        'severity': 'high',
        'description': 'Low pressure area over Arabian Sea likely to intensify. Coastal areas advised to stay alert. Wind speeds may reach 60-70 kmph.',
        'affectedArea': 'Western Coast Maharashtra',
        'timestamp': now.subtract(Duration(hours: 2)).toIso8601String(),
        'isRead': false,
        'isPinned': false,
        'status': 'active',
        'source': 'Cyclone Warning Center'
      },
      {
        'id': 'web_earthquake_1',
        'title': 'Seismic Activity Detected',
        'type': 'earthquake',
        'severity': 'medium',
        'description': 'Magnitude 4.2 earthquake detected 150km from Mumbai. No immediate threat but monitoring continues.',
        'affectedArea': 'Maharashtra Region',
        'timestamp': now.subtract(Duration(hours: 4)).toIso8601String(),
        'isRead': false,
        'isPinned': false,
        'status': 'active',
        'source': 'National Seismology Center'
      },
      {
        'id': 'web_heatwave_1',
        'title': 'Heat Wave Conditions',
        'type': 'weather',
        'severity': 'medium',
        'description': 'Temperatures expected to rise 2-4 degrees above normal. Stay hydrated and avoid outdoor activities during peak hours.',
        'affectedArea': 'Mumbai and adjoining areas',
        'timestamp': now.subtract(Duration(hours: 8)).toIso8601String(),
        'isRead': false,
        'isPinned': false,
        'status': 'active',
        'source': 'Weather Department'
      },
      {
        'id': 'web_fire_1',
        'title': 'Fire Incident Report',
        'type': 'fire',
        'severity': 'low',
        'description': 'Small fire incident reported and controlled. No casualties. Emergency services on standby.',
        'affectedArea': 'Industrial Area Andheri',
        'timestamp': now.subtract(Duration(hours: 12)).toIso8601String(),
        'isRead': false,
        'isPinned': false,
        'status': 'resolved',
        'source': 'Mumbai Fire Brigade'
      }
    ];
  }
}
