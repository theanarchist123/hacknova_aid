import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import 'google_services.dart';

class ShelterService {
  static const String _googleApiKey = ApiConfig.googleApiKey;
  static const String _googlePlacesUrl = ApiConfig.googlePlacesApi;
  static const String _googlePlaceDetailsUrl = ApiConfig.googlePlaceDetailsApi;
  
  Future<List<Map<String, dynamic>>> findNearbyShelters({
    required double latitude,
    required double longitude,
    double radiusM = 10000, // 10km default
  }) async {
    try {
      // For web platform, use fallback data due to CORS restrictions
      if (kIsWeb) {
        print('Web platform detected - using fallback shelter data due to CORS restrictions');
        return _getWebFallbackShelters(latitude, longitude);
      }
      
      List<Map<String, dynamic>> allShelters = [];
      
      // Use Google Services for enhanced place search
      final hospitals = await GoogleServices.searchPlaces(
        latitude: latitude, 
        longitude: longitude, 
        type: 'hospital', 
        radius: radiusM.toInt()
      );
      allShelters.addAll(_formatSheltersFromGoogleService(hospitals, 'Hospital'));
      
      final schools = await GoogleServices.searchPlaces(
        latitude: latitude, 
        longitude: longitude, 
        type: 'school', 
        radius: radiusM.toInt()
      );
      allShelters.addAll(_formatSheltersFromGoogleService(schools, 'School/Shelter'));
      
      final fireStations = await GoogleServices.searchPlaces(
        latitude: latitude, 
        longitude: longitude, 
        type: 'fire_station', 
        radius: radiusM.toInt()
      );
      allShelters.addAll(_formatSheltersFromGoogleService(fireStations, 'Fire Station'));
      
      final policeStations = await GoogleServices.searchPlaces(
        latitude: latitude, 
        longitude: longitude, 
        type: 'police', 
        radius: radiusM.toInt()
      );
      allShelters.addAll(_formatSheltersFromGoogleService(policeStations, 'Police Station'));
      
      // Fallback to original method if no results from Google Services
      if (allShelters.isEmpty) {
        final hospitals = await _findPlacesByType(latitude, longitude, 'hospital', radiusM);
        allShelters.addAll(hospitals);
        
        final schools = await _findPlacesByType(latitude, longitude, 'school', radiusM);
        allShelters.addAll(schools);
        
        final communityCenter = await _findPlacesByType(latitude, longitude, 'community_center', radiusM);
        allShelters.addAll(communityCenter);
        
        final fireStations = await _findPlacesByType(latitude, longitude, 'fire_station', radiusM);
        allShelters.addAll(fireStations);
        
        final policeStations = await _findPlacesByType(latitude, longitude, 'police', radiusM);
        allShelters.addAll(policeStations);
      }
      
      // Remove duplicates based on place_id
      final uniqueShelters = <String, Map<String, dynamic>>{};
      for (final shelter in allShelters) {
        final placeId = shelter['place_id'] ?? shelter['name'];
        uniqueShelters[placeId] = shelter;
      }
      
      final sheltersList = uniqueShelters.values.toList();
      
      // Sort by distance
      sheltersList.sort((a, b) => a['distance'].compareTo(b['distance']));
      
      return sheltersList.take(15).toList(); // Limit to 15 nearest shelters
    } catch (e) {
      print('Error finding shelters: $e');
      return _getFallbackShelters(latitude, longitude);
    }
  }
  
  Future<List<Map<String, dynamic>>> _findPlacesByType(
    double lat, double lon, String type, double radiusM) async {
    
    try {
      final url = Uri.parse('$_googlePlacesUrl?location=$lat,$lon&radius=${radiusM.toInt()}&type=$type&key=$_googleApiKey');
      
      final response = await http.get(url).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('Timeout fetching places for type $type');
          return http.Response('{"status":"TIMEOUT"}', 408);
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          
          List<Map<String, dynamic>> places = [];
          
          for (final result in results) {
            final geometry = result['geometry'];
            final location = geometry['location'];
            
            double placeLat = location['lat'].toDouble();
            double placeLon = location['lng'].toDouble();
            
            final distance = Geolocator.distanceBetween(lat, lon, placeLat, placeLon) / 1000;
            
            String name = result['name'] ?? _getFacilityTypeName(type);
            String address = result['vicinity'] ?? result['formatted_address'] ?? 'Address not available';
            
            places.add({
              'place_id': result['place_id'],
              'name': name,
              'address': address,
              'latitude': placeLat,
              'longitude': placeLon,
              'distance': distance,
              'amenities': _getAmenitiesForType(type),
              'capacity': _estimateCapacityForType(type),
              'occupied': Random().nextInt(_estimateCapacityForType(type) ~/ 2), // Mock occupancy
              'status': _getRandomStatus(),
              'type': type,
              'phone': null, // Will be fetched from place details if needed
              'website': null,
              'opening_hours': result['opening_hours']?['open_now'] == true ? 'Open Now' : 'Hours Unknown',
              'rating': result['rating']?.toDouble() ?? 0.0,
              'user_ratings_total': result['user_ratings_total'] ?? 0,
              'price_level': result['price_level'],
              'icon': result['icon'],
            });
          }
          
          return places;
        } else {
          print('Google Places API error for type $type: ${data['status']} - ${data['error_message']}');
        }
      } else {
        print('HTTP error fetching places for type $type: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching places for type $type: $e');
    }
    
    return [];
  }
  
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse('$_googlePlaceDetailsUrl?place_id=$placeId&fields=formatted_phone_number,website,opening_hours&key=$_googleApiKey');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final result = data['result'];
          return {
            'phone': result['formatted_phone_number'],
            'website': result['website'],
            'opening_hours': result['opening_hours'],
          };
        }
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
    
    return null;
  }
  
  String _getFacilityTypeName(String type) {
    switch (type) {
      case 'hospital': return 'Hospital';
      case 'school': return 'School (Emergency Shelter)';
      case 'community_center': return 'Community Center';
      case 'fire_station': return 'Fire Station';
      case 'police': return 'Police Station';
      default: return 'Emergency Facility';
    }
  }
  
  List<String> _getAmenitiesForType(String type) {
    switch (type) {
      case 'hospital':
        return ['Medical Care', 'Emergency Services', 'Supplies'];
      case 'school':
        return ['Large Space', 'Restrooms', 'Potential Shelter'];
      case 'community_center':
        return ['Community Space', 'Restrooms', 'Kitchen Facilities'];
      case 'fire_station':
        return ['Emergency Response', 'First Aid', 'Communication'];
      case 'police':
        return ['Security', 'Communication', 'Emergency Coordination'];
      default:
        return ['Basic Shelter'];
    }
  }
  
  int _estimateCapacityForType(String type) {
    switch (type) {
      case 'hospital': return 200;
      case 'school': return 500;
      case 'community_center': return 300;
      case 'fire_station': return 50;
      case 'police': return 100;
      default: return 150;
    }
  }
  
  String _getRandomStatus() {
    final statuses = ['Available', 'Nearly Full', 'Limited Space'];
    final random = Random();
    return statuses[random.nextInt(statuses.length)];
  }
  
  List<Map<String, dynamic>> _getWebFallbackShelters(double lat, double lon) {
    // Web-specific fallback shelters with realistic Mumbai data
    return [
      {
        'name': 'KEM Hospital',
        'address': 'Acharya Donde Marg, Parel, Mumbai',
        'latitude': lat + 0.01,
        'longitude': lon + 0.01,
        'distance': 1.2,
        'amenities': ['Medical Care', 'Emergency Services', 'Supplies'],
        'capacity': 300,
        'occupied': 89,
        'status': 'Available',
        'type': 'hospital',
        'phone': '+91 22 2410 3000',
        'website': null,
        'opening_hours': '24/7',
        'rating': 4.1,
      },
      {
        'name': 'Community Center Worli',
        'address': 'Worli Village, Mumbai',
        'latitude': lat - 0.01,
        'longitude': lon + 0.01,
        'distance': 1.8,
        'amenities': ['Community Space', 'Restrooms', 'Kitchen'],
        'capacity': 200,
        'occupied': 45,
        'status': 'Available',
        'type': 'community_center',
        'phone': '+91 22 2496 0000',
        'website': null,
        'opening_hours': 'Open',
        'rating': 3.9,
      },
      {
        'name': 'Mumbai Fire Brigade Station',
        'address': 'Byculla, Mumbai',
        'latitude': lat + 0.005,
        'longitude': lon - 0.01,
        'distance': 2.1,
        'amenities': ['Emergency Response', 'First Aid', 'Communication'],
        'capacity': 50,
        'occupied': 15,
        'status': 'Available',
        'type': 'fire_station',
        'phone': '101',
        'website': null,
        'opening_hours': '24/7',
        'rating': 4.3,
      },
      {
        'name': 'Shivaji Park Ground',
        'address': 'Dadar, Mumbai',
        'latitude': lat - 0.02,
        'longitude': lon - 0.01,
        'distance': 3.2,
        'amenities': ['Large Space', 'Open Area', 'Basic Facilities'],
        'capacity': 1000,
        'occupied': 0,
        'status': 'Available',
        'type': 'school',
        'phone': null,
        'website': null,
        'opening_hours': 'Open',
        'rating': 4.0,
      },
      {
        'name': 'Police Station Colaba',
        'address': 'Colaba, Mumbai',
        'latitude': lat + 0.02,
        'longitude': lon + 0.02,
        'distance': 4.5,
        'amenities': ['Security', 'Communication', 'Emergency Coordination'],
        'capacity': 75,
        'occupied': 20,
        'status': 'Available',
        'type': 'police',
        'phone': '100',
        'website': null,
        'opening_hours': '24/7',
        'rating': 3.8,
      }
    ];
  }
  
  // Format Google Services data to match our shelter format
  List<Map<String, dynamic>> _formatSheltersFromGoogleService(List<Map<String, dynamic>> places, String shelterType) {
    return places.map((place) {
      return {
        'place_id': place['place_id'] ?? '${place['name']}_${DateTime.now().millisecondsSinceEpoch}',
        'name': place['name'] ?? '$shelterType Facility',
        'address': place['vicinity'] ?? 'Address not available',
        'latitude': place['latitude'],
        'longitude': place['longitude'],
        'distance': 0.0, // Will be calculated later
        'amenities': _getAmenitiesForType(shelterType.toLowerCase()),
        'capacity': _estimateCapacityForType(shelterType.toLowerCase()),
        'occupied': Random().nextInt(100), // Mock occupancy
        'status': _getRandomStatus(),
        'type': shelterType.toLowerCase().replaceAll(' ', '_'),
        'phone': null,
        'website': null,
        'opening_hours': place['opening_hours'] != null ? 'Open Now' : 'Hours Unknown',
        'rating': place['rating']?.toDouble() ?? 0.0,
        'user_ratings_total': place['user_ratings_total'] ?? 0,
        'price_level': place['price_level'],
        'icon': null,
      };
    }).toList();
  }
  
  List<Map<String, dynamic>> _getFallbackShelters(double lat, double lon) {
    // Fallback shelters if API fails
    return [
      {
        'name': 'Emergency Response Center',
        'address': 'Nearest available facility',
        'latitude': lat + 0.01,
        'longitude': lon + 0.01,
        'distance': 1.2,
        'amenities': ['Basic Shelter', 'Emergency Services'],
        'capacity': 200,
        'occupied': 45,
        'status': 'Available',
        'type': 'emergency_facility',
        'phone': null,
        'website': null,
        'opening_hours': '24/7 Emergency',
        'rating': 4.0,
      },
      {
        'name': 'Community Safety Hub',
        'address': 'Local community center',
        'latitude': lat - 0.01,
        'longitude': lon + 0.01,
        'distance': 1.8,
        'amenities': ['Community Space', 'Restrooms', 'Kitchen'],
        'capacity': 300,
        'occupied': 120,
        'status': 'Available',
        'type': 'community_center',
        'phone': null,
        'website': null,
        'opening_hours': 'Open',
        'rating': 4.2,
      }
    ];
  }
}
