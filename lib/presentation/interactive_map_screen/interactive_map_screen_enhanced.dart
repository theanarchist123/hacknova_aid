import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/services/shelter_service.dart';
import '../../core/services/google_services.dart';
import '../../core/models/community_pin.dart';
import '../../core/services/community_pin_store.dart';
import '../incident_reporting_screen/incident_reporting_screen.dart';
import './widgets/disaster_alert_marker_sheet.dart';
import './widgets/emergency_mode_banner.dart';
import './widgets/map_filter_bottom_sheet.dart';
import './widgets/map_floating_controls.dart';
import './widgets/map_search_bar.dart';
import './widgets/pin_creation_bottom_sheet.dart';
import './widgets/community_pin_map_overlay.dart';
import './widgets/pin_details_popup.dart';
import './widgets/pin_filter_bottom_sheet.dart';
import './widgets/pin_search_bar.dart';

class InteractiveMapScreen extends StatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Map state
  LatLng _currentLocation = const LatLng(28.6139, 77.2090); // Default to Delhi
  bool _isLocationLoading = false;
  String _currentMapType = 'normal';
  bool _isEmergencyMode = false;

  // Filter states
  Map<String, bool> _filterStates = {
    'shelters': true,
    'hospitals': true,
    'food_centers': false,
    'evacuation_routes': false,
    'disaster_zones': true,
    'safe_zones': false,
  };

  // Real-time data lists
  List<Map<String, dynamic>> _realShelters = [];
  List<Map<String, dynamic>> _realHospitals = [];
  List<Map<String, dynamic>> _realFoodCenters = [];
  bool _isLoadingMarkers = false;

  // Community pins state
  List<CommunityPin> _communityPins = [];
  List<CommunityPin> _filteredPins = [];
  CommunityPinStore? _pinDatabase;
  bool _isLoadingPins = false;
  CommunityPin? _selectedPin;
  bool _showCommunityPins = true;
  PinFilterOptions _filterOptions = PinFilterOptions.defaultFilters();
  bool _showPinSearch = false;

  // Mock data
  final List<Map<String, dynamic>> _disasterAlerts = [
    {
      'id': 1,
      'type': 'flood',
      'title': 'Flash Flood Warning',
      'description':
          'Heavy rainfall has caused flash flooding in low-lying areas. Residents are advised to move to higher ground immediately.',
      'location': 'Yamuna River Basin',
      'latitude': 28.6500,
      'longitude': 77.2300,
      'severity': 'high',
      'radius': 8,
      'status': 'Active',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': 2,
      'type': 'cyclone',
      'title': 'Cyclone Alert',
      'description':
          'Tropical cyclone approaching coastal areas. Wind speeds expected to reach 120 km/h.',
      'location': 'Coastal Region',
      'latitude': 28.5800,
      'longitude': 77.1900,
      'severity': 'critical',
      'radius': 15,
      'status': 'Active',
      'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
    },
    {
      'id': 3,
      'type': 'outbreak',
      'title': 'Disease Outbreak',
      'description':
          'Confirmed cases of waterborne disease reported. Boil water before consumption.',
      'location': 'Central District',
      'latitude': 28.6200,
      'longitude': 77.2200,
      'severity': 'medium',
      'radius': 5,
      'status': 'Monitoring',
      'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
    },
  ];

  final List<Map<String, dynamic>> _shelters = [
    {
      'id': 1,
      'name': 'Community Center Shelter',
      'type': 'shelter',
      'latitude': 28.6300,
      'longitude': 77.2100,
      'capacity': 500,
      'occupied': 120,
      'facilities': ['Food', 'Medical', 'Sanitation'],
    },
    {
      'id': 2,
      'name': 'School Emergency Shelter',
      'type': 'shelter',
      'latitude': 28.6000,
      'longitude': 77.2400,
      'capacity': 300,
      'occupied': 80,
      'facilities': ['Food', 'Sanitation'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadRealTimeMarkers();
    _initializePinDatabase();
  }
  
  Future<void> _loadRealTimeMarkers() async {
    if (mounted) {
      setState(() {
        _isLoadingMarkers = true;
      });
    }
    
    try {
      // Load real shelters
      final shelterService = ShelterService();
      _realShelters = await shelterService.findNearbyShelters(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        radiusM: 15000,
      );
      
      // Load real hospitals using Google Services
      _realHospitals = await GoogleServices.searchPlaces(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        type: 'hospital',
        radius: 15000,
      );
      
      // Load real food centers and relief points
      final foodCenterResults = await GoogleServices.searchPlaces(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        type: 'food',
        radius: 10000,
      );
      
      final reliefCenterResults = await _searchReliefCenters();
      
      _realFoodCenters = [...foodCenterResults, ...reliefCenterResults];
      
      if (mounted) {
        setState(() {
          _isLoadingMarkers = false;
        });
      }
      
      print('Loaded ${_realShelters.length} shelters, ${_realHospitals.length} hospitals, ${_realFoodCenters.length} food centers');
      
    } catch (e) {
      print('Error loading real-time markers: $e');
      if (mounted) {
        setState(() {
          _isLoadingMarkers = false;
        });
      }
    }
  }
  
  Future<List<Map<String, dynamic>>> _searchReliefCenters() async {
    try {
      const String apiKey = 'AIzaSyAxASAVnfdE_c9Axulg_dG0TBcTWGaN79I';
      final keywords = ['food bank', 'relief center', 'food distribution', 'humanitarian aid'];
      List<Map<String, dynamic>> allResults = [];
      
      for (final keyword in keywords) {
        try {
          final encodedKeyword = Uri.encodeComponent(keyword);
          final url = Uri.parse(
            'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$encodedKeyword+near+${_currentLocation.latitude},${_currentLocation.longitude}&radius=10000&key=$apiKey'
          );
          
          print('Searching for: $keyword at ${_currentLocation.latitude}, ${_currentLocation.longitude}');
          
          final response = await http.get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'DisasterApp/1.0',
            },
          ).timeout(const Duration(seconds: 10));
          
          print('Response status for $keyword: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            
            // Check for API errors
            if (data['status'] == 'REQUEST_DENIED') {
              print('API request denied: ${data['error_message'] ?? 'Unknown reason'}');
              continue;
            }
            
            if (data['status'] == 'OVER_QUERY_LIMIT') {
              print('API quota exceeded, skipping $keyword');
              continue;
            }
            
            if (data['results'] != null && data['results'].isNotEmpty) {
              print('Found ${data['results'].length} results for $keyword');
              
              for (final result in data['results']) {
                if (result['geometry'] != null && result['geometry']['location'] != null) {
                  final location = result['geometry']['location'];
                  allResults.add({
                    'place_id': result['place_id'] ?? '',
                    'name': result['name'] ?? 'Unknown Relief Center',
                    'address': result['formatted_address'] ?? 'Address not available',
                    'latitude': location['lat']?.toDouble() ?? 0.0,
                    'longitude': location['lng']?.toDouble() ?? 0.0,
                    'rating': result['rating']?.toDouble() ?? 0.0,
                    'type': 'food_center',
                  });
                }
              }
            } else {
              print('No results found for $keyword');
            }
          } else {
            print('HTTP error for $keyword: ${response.statusCode} - ${response.body}');
          }
          
          // Add delay between requests to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 500));
          
        } catch (e) {
          print('Error searching for $keyword: $e');
          // Continue with next keyword instead of failing completely
          continue;
        }
      }
      
      print('Total relief centers found: ${allResults.length}');
      return allResults;
    } catch (e) {
      print('Error searching relief centers: $e');
      // Return mock data as fallback
      return _getMockReliefCenters();
    }
  }

  List<Map<String, dynamic>> _getMockReliefCenters() {
    // Provide mock relief centers as fallback when API fails
    final lat = _currentLocation.latitude;
    final lng = _currentLocation.longitude;
    
    return [
      {
        'place_id': 'mock_relief_1',
        'name': 'Emergency Food Distribution Center',
        'address': '1.5 km from current location',
        'latitude': lat + 0.01,
        'longitude': lng + 0.01,
        'rating': 4.2,
        'type': 'food_center',
      },
      {
        'place_id': 'mock_relief_2',
        'name': 'Community Relief Hub',
        'address': '2.2 km from current location',
        'latitude': lat - 0.015,
        'longitude': lng + 0.005,
        'rating': 4.5,
        'type': 'food_center',
      },
      {
        'place_id': 'mock_relief_3',
        'name': 'Disaster Response Center',
        'address': '1.8 km from current location',
        'latitude': lat + 0.008,
        'longitude': lng - 0.012,
        'rating': 4.0,
        'type': 'food_center',
      },
    ];
  }

  // Community Pin Methods
  Future<void> _initializePinDatabase() async {
    try {
      // Initialize CommunityPinStore
      print('🔧 InteractiveMapScreen: Initializing database...');
      CommunityPinStore.initialize();
      _pinDatabase = CommunityPinStore.instance;
      print('✅ Pin database initialized and accessible in interactive map');
      
      await _loadCommunityPins();
    } catch (e) {
      print('Error initializing pin database: $e');
      // Retry one more time
      try {
        print('🔧 InteractiveMapScreen: Retrying with CommunityPinStore.initialize()...');
        CommunityPinStore.initialize();
        _pinDatabase = CommunityPinStore.instance;
        await _loadCommunityPins();
        print('✅ Pin database initialized on retry');
      } catch (retryError) {
        print('❌ Failed to initialize pin database even on retry: $retryError');
        _pinDatabase = null;
      }
    }
  }

  Future<void> _loadCommunityPins() async {
    print('🔧 _loadCommunityPins called');
    if (_pinDatabase == null) {
      print('🔧 Pin database is null in _loadCommunityPins');
      return;
    }

    setState(() {
      _isLoadingPins = true;
    });

    try {
      print('🔧 Getting all pins from database...');
      final pins = await _pinDatabase!.getAllPins();
      print('🔧 Got ${pins.length} pins from database');
      setState(() {
        _communityPins = pins;
        _applyFilters();
        _isLoadingPins = false;
      });
      print('🔧 Applied filters, filtered pins: ${_filteredPins.length}');
    } catch (e) {
      print('Error loading community pins: $e');
      setState(() {
        _isLoadingPins = false;
      });
    }
  }

  void _applyFilters() {
    print('🔧 _applyFilters called with ${_communityPins.length} total pins');
    print('🔧 _showCommunityPins: $_showCommunityPins');
    setState(() {
      _filteredPins = _communityPins.where((pin) {
        // Calculate distance from current location if needed
        double? distanceKm;
        if (_filterOptions.maxDistanceKm != null) {
          distanceKm = _calculateDistance(
            _currentLocation.latitude,
            _currentLocation.longitude,
            pin.location.latitude,
            pin.location.longitude,
          );
        }
        
        return _filterOptions.shouldShowPin(pin, distanceFromUserKm: distanceKm);
      }).toList();
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  void _showPinFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinFilterBottomSheet(
        currentFilters: _filterOptions,
        onFiltersChanged: (newFilters) {
          setState(() {
            _filterOptions = newFilters;
            _applyFilters();
          });
        },
      ),
    );
  }

  void _togglePinSearch() {
    setState(() {
      _showPinSearch = !_showPinSearch;
    });
  }

  void _onPinSearchResults(List<CommunityPin> results) {
    // Highlight search results on map
    setState(() {
      _filteredPins = results;
    });
  }

  void _onPinSearchSelected(CommunityPin pin) {
    // Navigate to pin and show details
    _mapController.move(pin.location, 16.0);
    _onPinTapped(pin);
  }

  Future<void> _createCommunityPin(LatLng location) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinCreationBottomSheet(
        location: location,
        onPinCreated: _onPinCreated,
      ),
    );
  }

  Future<void> _onPinCreated(CommunityPin pin) async {
    print('🔧 _onPinCreated called with pin: ${pin.title}');
    print('🔧 Pin database is null: ${_pinDatabase == null}');
    
    if (_pinDatabase == null) {
      print('🔧 Pin database is null, attempting to initialize...');
      await _initializePinDatabase();
      if (_pinDatabase == null) {
        print('❌ Failed to initialize pin database');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initialize database for pin creation'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      print('🔧 Inserting pin into database...');
      await _pinDatabase!.insertPin(pin);
      print('🔧 Pin inserted successfully, refreshing pins...');
      await _loadCommunityPins(); // Refresh the pins list
      print('🔧 Pins refreshed. Current pin count: ${_communityPins.length}');
      print('🔧 Filtered pins count: ${_filteredPins.length}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Community pin created: ${pin.title}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error creating pin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create pin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onPinTapped(CommunityPin pin) {
    setState(() {
      _selectedPin = pin;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinDetailsPopup(
        pin: pin,
        onEdit: () => _editPin(pin),
        onDelete: () => _deletePin(pin),
        onVerify: () => _verifyPin(pin),
        onNavigate: () => _navigateToPin(pin),
        onShare: () => _sharePin(pin),
      ),
    );
  }

  Future<void> _editPin(CommunityPin pin) async {
    Navigator.pop(context); // Close details popup
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinCreationBottomSheet(
        location: pin.location,
        onPinCreated: (updatedPin) => _updatePin(pin.id, updatedPin),
      ),
    );
  }

  Future<void> _updatePin(String pinId, CommunityPin updatedPin) async {
    if (_pinDatabase == null) return;

    try {
      final newPin = updatedPin.copyWith(
        id: pinId,
        updatedAt: DateTime.now(),
      );
      await _pinDatabase!.updatePin(newPin);
      await _loadCommunityPins();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pin updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating pin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update pin'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePin(CommunityPin pin) async {
    Navigator.pop(context); // Close details popup
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pin'),
        content: Text('Are you sure you want to delete "${pin.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _pinDatabase != null) {
      try {
        await _pinDatabase!.deletePin(pin.id);
        await _loadCommunityPins();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pin deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error deleting pin: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete pin'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyPin(CommunityPin pin) async {
    Navigator.pop(context); // Close details popup
    
    if (_pinDatabase == null) return;

    try {
      // Add current user to verified list (mock implementation)
      final deviceId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final updatedVerifiedBy = [...pin.verifiedBy];
      
      if (!updatedVerifiedBy.contains(deviceId)) {
        updatedVerifiedBy.add(deviceId);
        
        final updatedPin = pin.copyWith(
          verifiedBy: updatedVerifiedBy,
          updatedAt: DateTime.now(),
        );
        
        await _pinDatabase!.updatePin(updatedPin);
        await _loadCommunityPins();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pin verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already verified this pin'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error verifying pin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to verify pin'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToPin(CommunityPin pin) {
    Navigator.pop(context); // Close details popup
    _mapController.move(pin.location, 16.0);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to ${pin.title}'),
        action: SnackBarAction(
          label: 'Open Maps',
          onPressed: () {
            // TODO: Open external navigation app
          },
        ),
      ),
    );
  }

  void _sharePin(CommunityPin pin) {
    Navigator.pop(context); // Close details popup
    
    final shareText = '''
Community Alert: ${pin.title}

Type: ${pin.type.displayName}
Priority: ${pin.priority.name}
Description: ${pin.description}

Location: ${pin.location.latitude.toStringAsFixed(6)}, ${pin.location.longitude.toStringAsFixed(6)}

Shared via HackNova Aid Emergency App
''';

    print('📋 Sharing pin: $shareText');
    
    // TODO: Implement actual sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pin information copied: ${pin.title}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      if (!kIsWeb) {
        final permission = await Permission.location.request();
        if (!permission.isGranted) {
          setState(() {
            _isLocationLoading = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLocationLoading = false;
      });

      _mapController.move(_currentLocation, 13.0);
    } catch (e) {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // Handle map tap for custom pin dropping
    _showCustomPinDialog(point);
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) {
    // Handle long press for community pin creation
    _createCommunityPin(point);
  }

  Future<String> _getLocationName(LatLng point) async {
    // Try multiple approaches to get location name
    print('Getting location name for: ${point.latitude}, ${point.longitude}');
    
    // First try: Google Geocoding API
    try {
      const String apiKey = 'AIzaSyAxASAVnfdE_c9Axulg_dG0TBcTWGaN79I';
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${point.latitude},${point.longitude}&key=$apiKey';
      
      print('Attempting Google Geocoding API call...');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'DisasterApp/1.0',
        },
      ).timeout(const Duration(seconds: 15));
      
      print('Geocoding response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Geocoding response: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}...');
        
        if (data['results'] != null && data['results'].isNotEmpty) {
          final address = data['results'][0]['formatted_address'] as String;
          print('✅ Geocoded address: $address');
          return address;
        } else if (data['error_message'] != null) {
          print('❌ Geocoding API error: ${data['error_message']}');
        } else {
          print('❌ No geocoding results found');
        }
      } else {
        print('❌ Geocoding API HTTP error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error with Google Geocoding API: $e');
    }
    
    // Second try: Alternative OpenStreetMap Nominatim API (free, no API key needed)
    try {
      print('Attempting OpenStreetMap Nominatim API call...');
      final osmUrl = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&addressdetails=1';
      
      final osmResponse = await http.get(
        Uri.parse(osmUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DisasterApp/1.0 (Emergency Response App)',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('OSM Nominatim response status: ${osmResponse.statusCode}');
      
      if (osmResponse.statusCode == 200) {
        final osmData = json.decode(osmResponse.body);
        if (osmData['display_name'] != null) {
          final address = osmData['display_name'] as String;
          print('✅ OSM Nominatim address: $address');
          return address;
        }
      }
    } catch (e) {
      print('❌ Error with OSM Nominatim API: $e');
    }
    
    // Third try: Generate a descriptive location based on coordinates
    try {
      print('Generating descriptive location from coordinates...');
      final cityName = _getCityFromCoordinates(point.latitude, point.longitude);
      if (cityName.isNotEmpty) {
        final descriptiveLocation = '$cityName (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
        print('✅ Using descriptive location: $descriptiveLocation');
        return descriptiveLocation;
      }
    } catch (e) {
      print('❌ Error generating descriptive location: $e');
    }
    
    // Final fallback: Coordinates with better formatting
    final fallbackLocation = 'Location: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
    print('🔄 Using coordinate fallback: $fallbackLocation');
    return fallbackLocation;
  }

  String _getCityFromCoordinates(double lat, double lng) {
    // Basic city detection for major Indian cities (can be expanded)
    final cityRanges = {
      'Mumbai': {'lat': [18.9, 19.3], 'lng': [72.7, 73.1]},
      'Delhi': {'lat': [28.4, 28.8], 'lng': [76.8, 77.4]},
      'Bangalore': {'lat': [12.8, 13.2], 'lng': [77.4, 77.8]},
      'Chennai': {'lat': [12.8, 13.3], 'lng': [80.1, 80.4]},
      'Kolkata': {'lat': [22.4, 22.7], 'lng': [88.2, 88.5]},
      'Hyderabad': {'lat': [17.2, 17.6], 'lng': [78.2, 78.7]},
      'Pune': {'lat': [18.4, 18.7], 'lng': [73.7, 74.0]},
      'Ahmedabad': {'lat': [22.9, 23.2], 'lng': [72.4, 72.8]},
    };
    
    for (final entry in cityRanges.entries) {
      final cityName = entry.key;
      final ranges = entry.value;
      final latRange = ranges['lat']!;
      final lngRange = ranges['lng']!;
      
      if (lat >= latRange[0] && lat <= latRange[1] && 
          lng >= lngRange[0] && lng <= lngRange[1]) {
        return cityName;
      }
    }
    
    // Return general region if no specific city found
    if (lat >= 8.0 && lat <= 37.0 && lng >= 68.0 && lng <= 97.0) {
      return 'India';
    }
    
    return '';
  }

  void _showCustomPinDialog(LatLng point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Pin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<String>(
              future: _getLocationName(point),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Getting location...'),
                    ],
                  );
                }
                return Text(
                  snapshot.data ?? 'Location unavailable',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
                'Would you like to report an incident at this location?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              print('Report Incident button pressed');
              _handleReportIncident(point);
            },
            child: const Text('Report Incident'),
          ),
        ],
      ),
    );
  }

  void _handleReportIncident(LatLng point) {
    // Close the dialog first
    Navigator.pop(context);
    
    // Schedule the navigation for the next frame to avoid widget tree issues
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      // Get location name with fallback
      String locationName;
      try {
        print('Getting location name for: ${point.latitude}, ${point.longitude}');
        locationName = await _getLocationName(point);
        print('Got location name: $locationName');
      } catch (e) {
        locationName = 'Lat: ${point.latitude.toStringAsFixed(6)}, Lng: ${point.longitude.toStringAsFixed(6)}';
        print('Error getting location name: $e');
      }
      
      // Navigate to incident reporting screen
      if (mounted) {
        print('Attempting navigation with data: location=$locationName, lat=${point.latitude}, lng=${point.longitude}');
        try {
          await Navigator.pushNamed(
            context, 
            '/incident-reporting-screen',
            arguments: {
              'location': locationName,
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          );
          print('Navigation completed successfully');
        } catch (error) {
          print('Navigation error: $error');
          // Fallback navigation using direct route
          if (mounted) {
            print('Using fallback navigation');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IncidentReportingScreen(
                  initialLocation: locationName,
                  initialLatitude: point.latitude,
                  initialLongitude: point.longitude,
                ),
              ),
            );
          }
        }
      }
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MapFilterBottomSheet(
        filterStates: _filterStates,
        onFiltersChanged: (newFilters) {
          setState(() {
            _filterStates = newFilters;
          });
          // Reload markers when filters change to show real data
          _loadRealTimeMarkers();
        },
      ),
    );
  }

  void _showAlertDetails(Map<String, dynamic> alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DisasterAlertMarkerSheet(alertData: alert),
    );
  }

  void _toggleMapType() {
    setState(() {
      switch (_currentMapType) {
        case 'normal':
          _currentMapType = 'satellite';
          break;
        case 'satellite':
          _currentMapType = 'terrain';
          break;
        case 'terrain':
          _currentMapType = 'hybrid';
          break;
        default:
          _currentMapType = 'normal';
      }
    });
  }

  void _toggleEmergencyMode() {
    setState(() {
      _isEmergencyMode = !_isEmergencyMode;
      if (_isEmergencyMode) {
        // Auto-enable emergency-relevant filters
        _filterStates['shelters'] = true;
        _filterStates['hospitals'] = true;
        _filterStates['evacuation_routes'] = true;
        _filterStates['disaster_zones'] = true;
      }
    });
  }

  String? _getNearestShelter() {
    if (_shelters.isEmpty) return null;
    return _shelters.first['name'] as String;
  }

  double? _getDistanceToNearestShelter() {
    if (_shelters.isEmpty) return null;
    final shelter = _shelters.first;
    final distance = Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      shelter['latitude'] as double,
      shelter['longitude'] as double,
    );
    return distance / 1000; // Convert to kilometers
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Current location marker
    markers.add(
      Marker(
        point: _currentLocation,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CustomIconWidget(
            iconName: 'person',
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );

    // Disaster alert markers
    if (_filterStates['disaster_zones'] == true) {
      for (final alert in _disasterAlerts) {
        final severity = alert['severity'] as String;
        Color markerColor;
        switch (severity) {
          case 'critical':
          case 'high':
            markerColor = const Color(0xFFD32F2F);
            break;
          case 'medium':
            markerColor = const Color(0xFFFFA000);
            break;
          default:
            markerColor = const Color(0xFF388E3C);
        }

        markers.add(
          Marker(
            point: LatLng(
                alert['latitude'] as double, alert['longitude'] as double),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _showAlertDetails(alert),
              child: Container(
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: markerColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CustomIconWidget(
                  iconName: 'warning',
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      }
    }

    // Shelter markers
    if (_filterStates['shelters'] == true) {
      for (final shelter in _realShelters) {
        markers.add(
          Marker(
            point: LatLng(
                shelter['latitude'] as double, shelter['longitude'] as double),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showShelterDetails(shelter),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CustomIconWidget(
                  iconName: 'local_hotel',
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
    }

    // Hospital markers
    if (_filterStates['hospitals'] == true) {
      for (final hospital in _realHospitals) {
        markers.add(
          Marker(
            point: LatLng(hospital['latitude'] as double,
                hospital['longitude'] as double),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showHospitalDetails(hospital),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CustomIconWidget(
                  iconName: 'local_hospital',
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
    }

    // Food center markers
    if (_filterStates['food_centers'] == true) {
      for (final foodCenter in _realFoodCenters) {
        markers.add(
          Marker(
            point: LatLng(foodCenter['latitude'] as double,
                foodCenter['longitude'] as double),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showFoodCenterDetails(foodCenter),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CustomIconWidget(
                  iconName: 'restaurant',
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  String _getMapUrl() {
    switch (_currentMapType) {
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'terrain':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Physical_Map/MapServer/tile/{z}/{y}/{x}';
      case 'hybrid':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 13.0,
                minZoom: 5.0,
                maxZoom: 18.0,
                onTap: _onMapTap,
                onLongPress: _onMapLongPress,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _getMapUrl(),
                  userAgentPackageName: 'com.example.hacknova_aid',
                  maxZoom: 18,
                ),
                MarkerLayer(
                  markers: _buildMarkers(),
                ),
                // Community pins overlay
                if (_showCommunityPins && _filteredPins.isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      print('🔧 Rendering CommunityPinMapOverlay with ${_filteredPins.length} pins');
                      return CommunityPinMapOverlay(
                        pins: _filteredPins,
                        onPinTap: _onPinTapped,
                        onPinLongPress: (pin) => _onPinTapped(pin),
                        selectedPinLocation: _selectedPin?.location,
                      );
                    },
                  ),
                ] else
                  Builder(
                    builder: (context) {
                      print('🔧 Not rendering overlay: showPins=$_showCommunityPins, pinCount=${_filteredPins.length}');
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),

            // Search bar
            Positioned(
              top: 1.h,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  if (!_showPinSearch)
                    MapSearchBar(
                      onSearch: (query) {
                        // Handle search functionality
                        if (query.isNotEmpty) {
                          // In a real app, this would search for locations
                          print('Searching for: $query');
                        }
                      },
                      onLocationSelected: (lat, lng, name) {
                        // Move camera to selected location
                        _mapController.move(LatLng(lat, lng), 15.0);
                        // Show custom pin dialog for the selected location
                        _showCustomPinDialog(LatLng(lat, lng));
                        print('Selected location: $name at $lat, $lng');
                      },
                      onFilterTap: _showFilterBottomSheet,
                    ),
                  
                  if (_showPinSearch)
                    PinSearchBar(
                      allPins: _communityPins,
                      onSearchResults: _onPinSearchResults,
                      onPinSelected: _onPinSearchSelected,
                      onFilterTap: _showPinFilters,
                    ),
                ],
              ),
            ),

            // Emergency mode banner
            EmergencyModeBanner(
              isEmergencyMode: _isEmergencyMode,
              onEmergencyModeToggle: _toggleEmergencyMode,
              nearestShelter: _getNearestShelter(),
              distanceToShelter: _getDistanceToNearestShelter(),
            ),

            // Floating controls
            MapFloatingControls(
              onLocationPressed: _getCurrentLocation,
              onMapTypePressed: _toggleMapType,
              onLayersPressed: _showFilterBottomSheet,
              isLocationLoading: _isLocationLoading,
              currentMapType: _currentMapType,
            ),

            // Emergency mode toggle button
            Positioned(
              left: 4.w,
              bottom: 20.h,
              child: Container(
                decoration: BoxDecoration(
                  color: _isEmergencyMode
                      ? const Color(0xFFD32F2F)
                      : AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleEmergencyMode,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 4.w, vertical: 1.5.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'emergency',
                            color: _isEmergencyMode
                                ? Colors.white
                                : const Color(0xFFD32F2F),
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            _isEmergencyMode ? 'EXIT' : 'EMERGENCY',
                            style: AppTheme.lightTheme.textTheme.labelLarge
                                ?.copyWith(
                              color: _isEmergencyMode
                                  ? Colors.white
                                  : const Color(0xFFD32F2F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Pin search toggle button
            Positioned(
              right: 4.w,
              bottom: 20.h,
              child: Container(
                decoration: BoxDecoration(
                  color: _showPinSearch
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _togglePinSearch,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 4.w, vertical: 1.5.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search,
                            color: _showPinSearch
                                ? Colors.white
                                : AppTheme.lightTheme.colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'SEARCH',
                            style: AppTheme.lightTheme.textTheme.labelLarge
                                ?.copyWith(
                              color: _showPinSearch
                                  ? Colors.white
                                  : AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom navigation
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                            'Home', 'home', false, '/home-dashboard-screen'),
                        _buildNavItem(
                            'Map', 'map', true, '/interactive-map-screen'),
                        _buildNavItem('Reports', 'report', false,
                            '/disaster-alerts-screen'),
                        _buildNavItem('Settings', 'settings', false,
                            '/emergency-response-screen'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      String label, String iconName, bool isActive, String route) {
    return GestureDetector(
      onTap: isActive ? null : () => Navigator.pushNamed(context, route),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: isActive
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
              size: 24,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: isActive
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShelterDetails(Map<String, dynamic> shelter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shelter['name'] ?? 'Emergency Shelter',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(shelter['address'] ?? 'Address not available'),
            const SizedBox(height: 16),
            Text('Type: ${shelter['type']}'),
            Text('Capacity: ${shelter['capacity'] ?? 'Unknown'}'),
            Text('Current Occupancy: ${shelter['occupied'] ?? 0}'),
            Text('Status: ${shelter['status'] ?? 'Unknown'}'),
            const SizedBox(height: 16),
            if (shelter['amenities'] != null)
              Text('Amenities: ${(shelter['amenities'] as List).join(', ')}'),
          ],
        ),
      ),
    );
  }

  void _showHospitalDetails(Map<String, dynamic> hospital) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hospital['name'] ?? 'Medical Facility',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(hospital['address'] ?? 'Address not available'),
            const SizedBox(height: 16),
            Text('Rating: ${hospital['rating'] ?? 'Not rated'}/5'),
            if (hospital['opening_hours'] != null)
              Text('Hours: ${hospital['opening_hours']}'),
          ],
        ),
      ),
    );
  }

  void _showFoodCenterDetails(Map<String, dynamic> foodCenter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              foodCenter['name'] ?? 'Food Distribution Center',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(foodCenter['address'] ?? 'Address not available'),
            const SizedBox(height: 16),
            Text('Rating: ${foodCenter['rating'] ?? 'Not rated'}/5'),
            Text('Type: Food Distribution / Relief Center'),
          ],
        ),
      ),
    );
  }
}
