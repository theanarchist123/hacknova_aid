import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/widgets.dart';
import 'google_services.dart';

class LocationService {
  static Position? _lastKnownPosition;
  static DateTime? _lastPositionTime;
  static const Duration _positionCacheExpiry = Duration(minutes: 5);

  static Future<bool> requestLocationPermission() async {
    // Request location permissions
    final status = await Permission.location.request();
    
    if (status == PermissionStatus.denied) {
      // Request again
      final status2 = await Permission.location.request();
      return status2 == PermissionStatus.granted;
    }
    
    return status == PermissionStatus.granted;
  }
  
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  /// Enhanced getCurrentPosition with caching and better error handling
  static Future<Position?> getCurrentPosition() async {
    try {
      // Ensure Flutter binding is available for platform channels
      WidgetsFlutterBinding.ensureInitialized();
      
      // Check cache first
      if (_lastKnownPosition != null && _lastPositionTime != null &&
          DateTime.now().difference(_lastPositionTime!) < _positionCacheExpiry) {
        print('📱 Using cached position');
        return _lastKnownPosition;
      }

      // Safety check for Flutter bindings - if not initialized, return null gracefully
      try {
        // Check if location services are enabled
        bool serviceEnabled = await isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('⚠️ Location services are disabled');
          return null;
        }
        
        // Check permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            print('⚠️ Location permissions are denied');
            return null;
          }
        }
        
        if (permission == LocationPermission.deniedForever) {
          print('⚠️ Location permissions are permanently denied');
          return null;
        }
        
        // Get current position
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        );

        // Cache the position
        _lastKnownPosition = position;
        _lastPositionTime = DateTime.now();
        
        print('✅ Location obtained: ${position.latitude}, ${position.longitude}');
        return position;
        
      } catch (bindingError) {
        if (bindingError.toString().contains('Binding has not yet been initialized')) {
          print('⚠️ Flutter binding not initialized, skipping location request');
          return null;
        }
        rethrow;
      }
      
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }
  
  static Future<String> getLocationName(double latitude, double longitude) async {
    try {
      // Use Google's reverse geocoding API to get actual location name
      final locationInfo = await GoogleServices.reverseGeocode(latitude, longitude);
      
      if (locationInfo != null && locationInfo['status'] == 'success') {
        String address = locationInfo['formatted_address'] ?? '';
        
        // Parse address to get city and area name like "Dombivli West, Mumbai"
        final components = locationInfo['address_components'] as List?;
        if (components != null) {
          String area = '';
          String city = '';
          
          for (var component in components) {
            final types = component['types'] as List;
            final longName = component['long_name'] ?? '';
            
            if (types.contains('sublocality_level_1') || types.contains('neighborhood')) {
              area = longName;
            } else if (types.contains('locality')) {
              city = longName;
            }
          }
          
          // Format as "Area, City" or use full address
          if (area.isNotEmpty && city.isNotEmpty) {
            return '$area, $city';
          } else if (city.isNotEmpty) {
            return city;
          }
        }
        
        return address.isNotEmpty ? address : 'Current Location';
      } else {
        // Fallback for web platform or API failure
        return _getFallbackLocationName(latitude, longitude);
      }
    } catch (e) {
      print('Error getting location name: $e');
      return _getFallbackLocationName(latitude, longitude);
    }
  }
  
  static String _getFallbackLocationName(double latitude, double longitude) {
    // Check if coordinates are near known locations in Mumbai area
    if (latitude >= 19.0 && latitude <= 19.3 && longitude >= 72.7 && longitude <= 73.1) {
      // Mumbai area coordinates
      if (latitude >= 19.2 && longitude >= 72.9) {
        return 'Dombivli West, Mumbai';
      } else if (latitude >= 19.1 && longitude >= 72.85) {
        return 'Andheri, Mumbai';
      } else if (latitude >= 19.05 && longitude >= 72.82) {
        return 'Bandra, Mumbai';
      } else {
        return 'Mumbai, Maharashtra';
      }
    }
    
    return "Lat: ${latitude.toStringAsFixed(4)}, Lon: ${longitude.toStringAsFixed(4)}";
  }
  
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Convert to kilometers
  }

  /// Get user location as LatLng for alert service integration
  static Future<LatLng?> getCurrentLocationAsLatLng() async {
    final position = await getCurrentPosition();
    if (position != null) {
      return LatLng(position.latitude, position.longitude);
    }
    return null;
  }

  /// Get location with fallback to last known position or India center
  static Future<LatLng?> getLocationWithFallback() async {
    try {
      // Try to get current location
      final currentLocation = await getCurrentLocationAsLatLng();
      if (currentLocation != null) return currentLocation;

      // Fallback to last known position if available
      if (_lastKnownPosition != null) {
        print('📍 Using last known location as fallback');
        return LatLng(_lastKnownPosition!.latitude, _lastKnownPosition!.longitude);
      }
    } catch (e) {
      print('⚠️ Error getting location, using fallback: $e');
    }

    // Fallback to approximate center of India
    print('📍 Using India center as fallback location');
    return LatLng(20.5937, 78.9629);
  }

  /// Check if coordinates are within India bounds
  static bool isLocationInIndia(LatLng location) {
    return location.latitude >= 6.5 &&
           location.latitude <= 37.1 &&
           location.longitude >= 68.0 &&
           location.longitude <= 97.5;
  }

  /// Get state/region name for coordinates (simplified mapping)
  static String getRegionForLocation(LatLng location) {
    // Simplified region mapping for major Indian regions
    final lat = location.latitude;
    final lon = location.longitude;

    // North India
    if (lat > 26 && lat < 32 && lon > 75 && lon < 79) {
      return 'Delhi/NCR';
    }
    // Maharashtra
    if (lat > 18 && lat < 21 && lon > 72 && lon < 75) {
      return 'Maharashtra';
    }
    // Karnataka
    if (lat > 12 && lat < 16 && lon > 74 && lon < 78) {
      return 'Karnataka';
    }
    // Tamil Nadu
    if (lat > 8 && lat < 14 && lon > 76 && lon < 81) {
      return 'Tamil Nadu';
    }
    // West Bengal
    if (lat > 22 && lat < 25 && lon > 87 && lon < 90) {
      return 'West Bengal';
    }
    // Andhra Pradesh/Telangana
    if (lat > 15 && lat < 20 && lon > 77 && lon < 82) {
      return 'Andhra Pradesh/Telangana';
    }
    // Gujarat
    if (lat > 20 && lat < 25 && lon > 68 && lon < 74) {
      return 'Gujarat';
    }
    // Rajasthan
    if (lat > 24 && lat < 30 && lon > 69 && lon < 78) {
      return 'Rajasthan';
    }
    // Kerala
    if (lat > 8 && lat < 13 && lon > 74 && lon < 78) {
      return 'Kerala';
    }
    // Odisha
    if (lat > 17 && lat < 22 && lon > 81 && lon < 87) {
      return 'Odisha';
    }
    // Northeast
    if (lat > 22 && lat < 30 && lon > 88 && lon < 98) {
      return 'Northeast India';
    }
    // Himachal/Uttarakhand
    if (lat > 29 && lat < 34 && lon > 75 && lon < 81) {
      return 'Northern Hills';
    }
    
    // Default for other areas
    return 'India';
  }

  /// Find the nearest major city to given coordinates
  static Map<String, dynamic> getNearestCity(LatLng location) {
    final majorCities = [
      {'name': 'New Delhi', 'lat': 28.6139, 'lon': 77.2090},
      {'name': 'Mumbai', 'lat': 19.0760, 'lon': 72.8777},
      {'name': 'Bangalore', 'lat': 12.9716, 'lon': 77.5946},
      {'name': 'Chennai', 'lat': 13.0827, 'lon': 80.2707},
      {'name': 'Kolkata', 'lat': 22.5726, 'lon': 88.3639},
      {'name': 'Hyderabad', 'lat': 17.3850, 'lon': 78.4867},
      {'name': 'Pune', 'lat': 18.5204, 'lon': 73.8567},
      {'name': 'Ahmedabad', 'lat': 23.0225, 'lon': 72.5714},
      {'name': 'Surat', 'lat': 21.1702, 'lon': 72.8311},
      {'name': 'Jaipur', 'lat': 26.9124, 'lon': 75.7873},
    ];

    String nearestCity = 'Unknown';
    double nearestDistance = double.infinity;

    for (final city in majorCities) {
      final cityLocation = LatLng(city['lat']! as double, city['lon']! as double);
      final distance = calculateDistance(
        location.latitude,
        location.longitude,
        cityLocation.latitude,
        cityLocation.longitude,
      );
      
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestCity = city['name']! as String;
      }
    }

    return {
      'city': nearestCity,
      'distance_km': nearestDistance.round(),
    };
  }

  /// Clear cached location data
  static void clearCache() {
    _lastKnownPosition = null;
    _lastPositionTime = null;
    print('📍 Location cache cleared');
  }

  /// Check if we have a recent cached location
  static bool hasCachedLocation() {
    return _lastKnownPosition != null && 
           _lastPositionTime != null &&
           DateTime.now().difference(_lastPositionTime!) < _positionCacheExpiry;
  }
}
