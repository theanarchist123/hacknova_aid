import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'google_services.dart';

class LocationService {
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
  
  static Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
      
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }
      
      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
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
}
