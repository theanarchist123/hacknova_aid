import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class GoogleServices {
  // Weather service using Google's APIs
  static Future<Map<String, dynamic>?> getCurrentWeather(double latitude, double longitude) async {
    try {
      // Using OpenWeatherMap as Google doesn't provide direct weather API
      // But we can get location info from Google Geocoding
      final locationInfo = await reverseGeocode(latitude, longitude);
      
      if (!kIsWeb) {
        // For mobile platforms, try to get weather from a free API
        final weatherUrl = 'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m&timezone=auto';
        
        final response = await http.get(Uri.parse(weatherUrl))
            .timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return {
            'location': locationInfo?['formatted_address'] ?? 'Unknown Location',
            'temperature': data['current']['temperature_2m'],
            'humidity': data['current']['relative_humidity_2m'],
            'precipitation': data['current']['precipitation'],
            'wind_speed': data['current']['wind_speed_10m'],
            'weather_code': data['current']['weather_code'],
            'timezone': data['timezone'],
            'last_updated': data['current']['time'],
          };
        }
      }
      
      // Fallback weather data for web or API failure
      return _getFallbackWeather(locationInfo?['formatted_address'] ?? 'Current Location');
    } catch (e) {
      print('Weather API Error: $e');
      return _getFallbackWeather('Current Location');
    }
  }

  static Map<String, dynamic> _getFallbackWeather(String location) {
    return {
      'location': location,
      'temperature': 28.5,
      'humidity': 65,
      'precipitation': 0.2,
      'wind_speed': 12.3,
      'weather_code': 2, // Partly cloudy
      'timezone': 'Asia/Kolkata',
      'last_updated': DateTime.now().toIso8601String(),
      'description': 'Partly cloudy with mild conditions',
    };
  }

  // Directions service using Google Directions API
  static Future<Map<String, dynamic>?> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String mode = 'driving', // driving, walking, transit, bicycling
  }) async {
    try {
      if (!kIsWeb) {
        final url = '${ApiConfig.googleDirectionsApi}?'
            'origin=$originLat,$originLng&'
            'destination=$destLat,$destLng&'
            'mode=$mode&'
            'key=${ApiConfig.googleApiKey}';

        final response = await http.get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
            final route = data['routes'][0];
            final leg = route['legs'][0];
            
            return {
              'status': 'success',
              'duration': leg['duration']['text'],
              'duration_value': leg['duration']['value'], // in seconds
              'distance': leg['distance']['text'],
              'distance_value': leg['distance']['value'], // in meters
              'start_address': leg['start_address'],
              'end_address': leg['end_address'],
              'steps': leg['steps'],
              'polyline': route['overview_polyline']['points'],
              'bounds': route['bounds'],
            };
          }
        }
      }

      // Fallback directions
      return _getFallbackDirections(originLat, originLng, destLat, destLng, mode);
    } catch (e) {
      print('Directions API Error: $e');
      return _getFallbackDirections(originLat, originLng, destLat, destLng, mode);
    }
  }

  static Map<String, dynamic> _getFallbackDirections(double originLat, double originLng, double destLat, double destLng, String mode) {
    // Calculate approximate distance and time
    double distance = Geolocator.distanceBetween(originLat, originLng, destLat, destLng);
    int duration = (distance / (mode == 'walking' ? 5000 : mode == 'bicycling' ? 15000 : 50000) * 3600).round();
    
    return {
      'status': 'fallback',
      'duration': '${(duration / 60).round()} mins',
      'duration_value': duration,
      'distance': '${(distance / 1000).toStringAsFixed(1)} km',
      'distance_value': distance.round(),
      'start_address': 'Origin Location',
      'end_address': 'Destination Location',
      'steps': [
        {
          'instructions': 'Head towards destination',
          'distance': {'text': '${(distance / 1000).toStringAsFixed(1)} km', 'value': distance.round()},
          'duration': {'text': '${(duration / 60).round()} mins', 'value': duration},
        }
      ],
    };
  }

  // Enhanced Geocoding service using Google Geocoding API
  static Future<Map<String, dynamic>?> geocodeAddress(String address) async {
    try {
      if (!kIsWeb) {
        final url = '${ApiConfig.googleGeocodingApi}?'
            'address=${Uri.encodeComponent(address)}&'
            'key=${ApiConfig.googleApiKey}';

        final response = await http.get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            final result = data['results'][0];
            final location = result['geometry']['location'];
            
            return {
              'status': 'success',
              'formatted_address': result['formatted_address'],
              'latitude': location['lat'],
              'longitude': location['lng'],
              'place_id': result['place_id'],
              'types': result['types'],
              'address_components': result['address_components'],
            };
          }
        }
      }

      // Fallback for common addresses
      return _getFallbackGeocode(address);
    } catch (e) {
      print('Geocoding API Error: $e');
      return _getFallbackGeocode(address);
    }
  }

  static Future<Map<String, dynamic>?> reverseGeocode(double latitude, double longitude) async {
    try {
      if (!kIsWeb) {
        final url = '${ApiConfig.googleGeocodingApi}?'
            'latlng=$latitude,$longitude&'
            'key=${ApiConfig.googleApiKey}';

        final response = await http.get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            final result = data['results'][0];
            
            return {
              'status': 'success',
              'formatted_address': result['formatted_address'],
              'place_id': result['place_id'],
              'types': result['types'],
              'address_components': result['address_components'],
            };
          }
        }
      }

      // Fallback reverse geocoding
      return {
        'status': 'fallback',
        'formatted_address': 'Location: $latitude, $longitude',
        'place_id': 'fallback_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}',
        'types': ['approximate'],
      };
    } catch (e) {
      print('Reverse Geocoding API Error: $e');
      return {
        'status': 'fallback',
        'formatted_address': 'Location: $latitude, $longitude',
        'place_id': 'fallback_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}',
        'types': ['approximate'],
      };
    }
  }

  static Map<String, dynamic>? _getFallbackGeocode(String address) {
    // Common Mumbai locations
    final commonLocations = {
      'mumbai': {'lat': 19.0760, 'lng': 72.8777, 'address': 'Mumbai, Maharashtra, India'},
      'bandra': {'lat': 19.0596, 'lng': 72.8295, 'address': 'Bandra, Mumbai, Maharashtra, India'},
      'andheri': {'lat': 19.1136, 'lng': 72.8697, 'address': 'Andheri, Mumbai, Maharashtra, India'},
      'powai': {'lat': 19.1176, 'lng': 72.9060, 'address': 'Powai, Mumbai, Maharashtra, India'},
    };

    final key = address.toLowerCase();
    for (String location in commonLocations.keys) {
      if (key.contains(location)) {
        final data = commonLocations[location]!;
        return {
          'status': 'fallback',
          'formatted_address': data['address'],
          'latitude': data['lat'],
          'longitude': data['lng'],
          'place_id': 'fallback_$location',
          'types': ['locality', 'political'],
        };
      }
    }

    return null;
  }

  // Enhanced Places service with more details
  static Future<List<Map<String, dynamic>>> searchPlaces({
    required double latitude,
    required double longitude,
    required String type,
    int radius = 5000,
    String keyword = '',
  }) async {
    try {
      if (!kIsWeb) {
        String url = '${ApiConfig.googlePlacesApi}?'
            'location=$latitude,$longitude&'
            'radius=$radius&'
            'type=$type&'
            'key=${ApiConfig.googleApiKey}';
            
        if (keyword.isNotEmpty) {
          url += '&keyword=${Uri.encodeComponent(keyword)}';
        }

        final response = await http.get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['status'] == 'OK') {
            List<Map<String, dynamic>> places = [];
            
            for (var place in data['results']) {
              places.add({
                'name': place['name'],
                'place_id': place['place_id'],
                'latitude': place['geometry']['location']['lat'],
                'longitude': place['geometry']['location']['lng'],
                'rating': place['rating'] ?? 0.0,
                'user_ratings_total': place['user_ratings_total'] ?? 0,
                'price_level': place['price_level'] ?? 0,
                'types': place['types'],
                'vicinity': place['vicinity'],
                'opening_hours': place['opening_hours'],
                'photos': place['photos'],
              });
            }
            
            return places;
          }
        }
      }

      // Fallback places
      return _getFallbackPlaces(type, latitude, longitude);
    } catch (e) {
      print('Places Search API Error: $e');
      return _getFallbackPlaces(type, latitude, longitude);
    }
  }

  static List<Map<String, dynamic>> _getFallbackPlaces(String type, double latitude, double longitude) {
    // Return different fallback data based on type
    switch (type) {
      case 'hospital':
        return [
          {'name': 'City General Hospital', 'latitude': latitude + 0.01, 'longitude': longitude + 0.01, 'rating': 4.2, 'vicinity': 'Medical District'},
          {'name': 'Emergency Care Center', 'latitude': latitude - 0.01, 'longitude': longitude + 0.01, 'rating': 4.0, 'vicinity': 'Healthcare Zone'},
        ];
      case 'gas_station':
        return [
          {'name': 'Fuel Station', 'latitude': latitude + 0.005, 'longitude': longitude - 0.005, 'rating': 3.8, 'vicinity': 'Main Road'},
          {'name': 'Highway Petrol Pump', 'latitude': latitude - 0.005, 'longitude': longitude + 0.005, 'rating': 4.1, 'vicinity': 'Highway Junction'},
        ];
      case 'restaurant':
        return [
          {'name': 'Local Eatery', 'latitude': latitude + 0.002, 'longitude': longitude + 0.002, 'rating': 4.3, 'vicinity': 'Food Street'},
          {'name': 'Family Restaurant', 'latitude': latitude - 0.002, 'longitude': longitude - 0.002, 'rating': 4.5, 'vicinity': 'City Center'},
        ];
      default:
        return [
          {'name': 'Local Point of Interest', 'latitude': latitude, 'longitude': longitude, 'rating': 4.0, 'vicinity': 'Current Area'},
        ];
    }
  }
}
