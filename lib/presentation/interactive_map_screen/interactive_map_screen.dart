import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/disaster_alert_marker_sheet.dart';
import './widgets/emergency_mode_banner.dart';
import './widgets/map_filter_bottom_sheet.dart';
import './widgets/map_floating_controls.dart';
import './widgets/map_search_bar.dart';

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

  final List<Map<String, dynamic>> _hospitals = [
    {
      'id': 1,
      'name': 'City General Hospital',
      'type': 'hospital',
      'latitude': 28.6400,
      'longitude': 77.2000,
      'emergency': true,
      'beds_available': 45,
    },
    {
      'id': 2,
      'name': 'Emergency Medical Center',
      'type': 'hospital',
      'latitude': 28.5900,
      'longitude': 77.2300,
      'emergency': true,
      'beds_available': 12,
    },
  ];

  final List<Map<String, dynamic>> _foodCenters = [
    {
      'id': 1,
      'name': 'Relief Food Distribution',
      'type': 'food_center',
      'latitude': 28.6100,
      'longitude': 77.2200,
      'operating_hours': '6:00 AM - 10:00 PM',
      'supplies': ['Rice', 'Water', 'Medicine'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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

  void _showCustomPinDialog(LatLng point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Pin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Latitude: ${point.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${point.longitude.toStringAsFixed(6)}'),
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
              Navigator.pop(context);
              Navigator.pushNamed(context, '/incident-reporting-screen');
            },
            child: const Text('Report Incident'),
          ),
        ],
      ),
    );
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
      for (final shelter in _shelters) {
        markers.add(
          Marker(
            point: LatLng(
                shelter['latitude'] as double, shelter['longitude'] as double),
            width: 40,
            height: 40,
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
        );
      }
    }

    // Hospital markers
    if (_filterStates['hospitals'] == true) {
      for (final hospital in _hospitals) {
        markers.add(
          Marker(
            point: LatLng(hospital['latitude'] as double,
                hospital['longitude'] as double),
            width: 40,
            height: 40,
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
        );
      }
    }

    // Food center markers
    if (_filterStates['food_centers'] == true) {
      for (final foodCenter in _foodCenters) {
        markers.add(
          Marker(
            point: LatLng(foodCenter['latitude'] as double,
                foodCenter['longitude'] as double),
            width: 40,
            height: 40,
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
              ],
            ),

            // Search bar
            Positioned(
              top: 1.h,
              left: 0,
              right: 0,
              child: MapSearchBar(
                onSearch: (query) {
                  // Handle search functionality
                  if (query.isNotEmpty) {
                    // In a real app, this would search for locations
                    print('Searching for: $query');
                  }
                },
                onFilterTap: _showFilterBottomSheet,
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
}
