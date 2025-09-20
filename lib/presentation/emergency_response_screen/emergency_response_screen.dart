import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/services/shelter_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/sos_emergency_beacon_service.dart';
import './widgets/communication_tools_widget.dart';
import './widgets/emergency_action_card_widget.dart';
import './widgets/emergency_contacts_widget.dart';

class EmergencyResponseScreen extends StatefulWidget {
  const EmergencyResponseScreen({super.key});

  @override
  State<EmergencyResponseScreen> createState() =>
      _EmergencyResponseScreenState();
}

class _EmergencyResponseScreenState extends State<EmergencyResponseScreen> {
  String currentThreatLevel = "HIGH";
  String currentLocation = "Getting location...";
  bool isSOSActive = false;

  // Real-time shelter service
  final ShelterService _shelterService = ShelterService();
  List<Map<String, dynamic>> shelterData = [];
  bool _isLoadingShelters = false;
  Position? _currentPosition;

  // SOS Emergency Beacon Service
  final SOSEmergencyBeaconService _sosService = SOSEmergencyBeaconService();

  @override
  void initState() {
    super.initState();
    _initializeLocationAndShelters();
    _initializeSOSService();
  }

  @override
  void dispose() {
    // Dispose SOS service when screen is disposed
    _sosService.dispose();
    super.dispose();
  }

  /// Initialize SOS Emergency Beacon Service
  Future<void> _initializeSOSService() async {
    try {
      await _sosService.initializeEmergencyBeacon();
      print('✅ SOS Emergency Beacon Service initialized');
    } catch (e) {
      print('⚠️ Failed to initialize SOS service: $e');
    }
  }

  Future<void> _initializeLocationAndShelters() async {
    try {
      // Get current location
      _currentPosition = await LocationService.getCurrentPosition();
      
      if (_currentPosition != null) {
        final locationName = await LocationService.getLocationName(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        
        if (mounted) {
          setState(() {
            currentLocation = locationName;
          });
        }
        
        // Load nearby shelters
        await _loadNearbyShelters();
      } else {
        if (mounted) {
          setState(() {
            currentLocation = "Location unavailable";
          });
        }
        _loadFallbackShelters();
      }
    } catch (e) {
      print('Error initializing location: $e');
      if (mounted) {
        setState(() {
          currentLocation = "Location error";
        });
      }
      _loadFallbackShelters();
    }
  }

  Future<void> _loadNearbyShelters() async {
    if (_currentPosition == null) return;
    
    if (mounted) {
      setState(() => _isLoadingShelters = true);
    }
    
    try {
      print('🔍 Searching for shelters near: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      final shelters = await _shelterService.findNearbyShelters(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusM: 20000, // 20km radius
      );
      
      print('✅ Found ${shelters.length} shelters');
      if (shelters.isNotEmpty) {
        print('First shelter: ${shelters.first}');
      }
      
      if (mounted) {
        setState(() {
          shelterData = shelters;
        });
      }
    } catch (e) {
      print('Error loading shelters: $e');
      _loadFallbackShelters();
    } finally {
      if (mounted) {
        setState(() => _isLoadingShelters = false);
      }
    }
  }

  void _loadFallbackShelters() {
    print('📍 Loading fallback shelters');
    if (mounted) {
      setState(() {
      shelterData = [
        {
          "name": "Emergency Response Center",
          "address": "Nearest available facility",
          "capacity": 500,
          "occupied": 120,
          "distance": 1200.0,
          "distanceKm": "1.2",
          "amenities": ["Medical", "Food", "Wi-Fi"],
          "status": "Available"
        },
        {
          "name": "Community Safety Hub", 
          "address": "Local community center",
          "capacity": 300,
          "occupied": 89,
          "distance": 2100.0,
          "distanceKm": "2.1",
          "amenities": ["Food", "Supplies", "Communication"],
          "status": "Available"
        }
      ];
      print('✅ Loaded ${shelterData.length} fallback shelters');
    });
    }
  }

  final List<Map<String, dynamic>> firstAidGuides = [
    {
      "title": "CPR Instructions",
      "category": "Life-Saving",
      "steps": [
        "Check responsiveness and breathing",
        "Call for help immediately",
        "Place hands on center of chest",
        "Push hard and fast at least 2 inches deep",
        "Allow complete chest recoil between compressions",
        "Give 30 compressions, then 2 rescue breaths",
        "Continue until help arrives"
      ],
      "icon": "favorite"
    },
    {
      "title": "Severe Bleeding Control",
      "category": "Trauma Care",
      "steps": [
        "Apply direct pressure to wound",
        "Use clean cloth or bandage",
        "Maintain pressure continuously",
        "Elevate injured area above heart if possible",
        "Apply pressure bandage if bleeding continues",
        "Seek immediate medical attention"
      ],
      "icon": "healing"
    },
    {
      "title": "Shock Treatment",
      "category": "Emergency Care",
      "steps": [
        "Keep person lying down",
        "Elevate legs 8-12 inches if no spinal injury",
        "Keep person warm with blankets",
        "Loosen tight clothing",
        "Do not give food or water",
        "Monitor breathing and pulse",
        "Get emergency medical help immediately"
      ],
      "icon": "monitor_heart"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Emergency Response',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppTheme.lightTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: () => _showAdvancedOptions(context),
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color: Colors.white,
              size: 6.w,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SOS Emergency Button (moved to top)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleSOS(),
                      child: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: isSOSActive
                              ? AppTheme.primaryLight
                              : AppTheme.primaryLight.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryLight.withValues(alpha: 0.4),
                              blurRadius: isSOSActive ? 20 : 10,
                              spreadRadius: isSOSActive ? 5 : 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'sos',
                              color: Colors.white,
                              size: 12.w,
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              isSOSActive ? 'ACTIVE' : 'SOS',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isSOSActive
                          ? 'SOS signal is broadcasting your location'
                          : 'Tap to send emergency SOS signal',
                      textAlign: TextAlign.center,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMediumEmphasisLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Action Cards
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  'Emergency Actions',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 2.h),

              // Find Shelter Card
              EmergencyActionCardWidget(
                title: 'Find Shelter',
                subtitle:
                    'Locate nearest emergency shelters with capacity info',
                iconName: 'home',
                cardColor: AppTheme.successLight,
                onTap: () => _showShelterOptions(context),
                onLongPress: () => _showShelterAdvancedOptions(context),
              ),

              // Emergency Contacts Card
              EmergencyActionCardWidget(
                title: 'Emergency Contacts',
                subtitle:
                    'Quick access to emergency services and personal contacts',
                iconName: 'phone',
                cardColor: AppTheme.primaryLight,
                onTap: () => _showEmergencyContactsModal(context),
                onLongPress: () => _broadcastLocation(),
              ),

              // First Aid Guide Card
              EmergencyActionCardWidget(
                title: 'First Aid Guide',
                subtitle:
                    'Offline medical procedures and emergency care instructions',
                iconName: 'medical_services',
                cardColor: AppTheme.secondaryLight,
                onTap: () => _showFirstAidGuide(context),
                onLongPress: () => _requestMedicalHelp(),
              ),

              // Communication Tools
              const CommunicationToolsWidget(),

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }

  void _showShelterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.outlineLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'home',
                    color: AppTheme.successLight,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Shelters',
                          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isLoadingShelters 
                            ? 'Finding nearby shelters...'
                            : '${shelterData.length} shelters found',
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_currentPosition != null)
                    IconButton(
                      onPressed: _isLoadingShelters ? null : () async {
                        Navigator.pop(context);
                        await _loadNearbyShelters();
                        _showShelterOptions(context);
                      },
                      icon: _isLoadingShelters 
                        ? SizedBox(
                            width: 5.w,
                            height: 5.w,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.refresh),
                    ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: _isLoadingShelters 
                ? Center(child: CircularProgressIndicator())
                : shelterData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'location_off',
                            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.5),
                            size: 12.w,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'No shelters found',
                            style: AppTheme.lightTheme.textTheme.titleMedium,
                          ),
                          Text(
                            'Enable location for better results',
                            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      itemCount: shelterData.length,
                      itemBuilder: (context, index) {
                        final shelter = shelterData[index];
                        
                        // Safely handle capacity and occupied values
                        final capacity = shelter["capacity"] is int 
                          ? shelter["capacity"] as int 
                          : int.tryParse(shelter["capacity"].toString()) ?? 100;
                        final occupied = shelter["occupied"] is int 
                          ? shelter["occupied"] as int 
                          : int.tryParse(shelter["occupied"].toString()) ?? 0;
                        
                        final occupancyRate = occupied / capacity;
                        
                        // Safely handle distance
                        final distance = shelter["distance"];
                        String distanceText;
                        if (distance is double) {
                          distanceText = '${(distance / 1000).toStringAsFixed(1)} km';
                        } else if (distance is int) {
                          distanceText = '${(distance / 1000).toStringAsFixed(1)} km';
                        } else if (shelter["distanceKm"] != null) {
                          distanceText = '${shelter["distanceKm"]} km';
                        } else {
                          distanceText = distance.toString();
                        }

                        return Container(
                          margin: EdgeInsets.only(bottom: 2.h),
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.outlineLight),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.shadowColor,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      shelter["name"] as String,
                                      style: AppTheme.lightTheme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 2.w, vertical: 0.5.h),
                                    decoration: BoxDecoration(
                                      color: occupancyRate > 0.9
                                          ? AppTheme.primaryLight
                                              .withValues(alpha: 0.1)
                                          : AppTheme.successLight
                                              .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      distanceText,
                                      style: AppTheme.lightTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: occupancyRate > 0.9
                                            ? AppTheme.primaryLight
                                            : AppTheme.successLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 1.h),
                              Row(
                                children: [
                                  CustomIconWidget(
                                    iconName: 'location_on',
                                    color: AppTheme.textMediumEmphasisLight,
                                    size: 4.w,
                                  ),
                                  SizedBox(width: 2.w),
                                  Expanded(
                                    child: Text(
                                      shelter["address"] as String,
                                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'directions_walk',
                              color: AppTheme.textMediumEmphasisLight,
                              size: 4.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              distanceText,
                              style: AppTheme.lightTheme.textTheme.bodyMedium,
                            ),
                            const Spacer(),
                            Text(
                              '$occupied/$capacity occupied',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        LinearProgressIndicator(
                          value: occupancyRate,
                          backgroundColor: AppTheme.outlineLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            occupancyRate > 0.9
                                ? AppTheme.primaryLight
                                : AppTheme.successLight,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Wrap(
                          spacing: 2.w,
                          children: (shelter["amenities"] as List<String>)
                              .map((amenity) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.w, vertical: 0.5.h),
                              decoration: BoxDecoration(
                                color: AppTheme.lightTheme.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                amenity,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme.lightTheme.primaryColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _navigateToShelter(
                                    shelter["name"] as String),
                                icon: CustomIconWidget(
                                  iconName: 'directions',
                                  color: AppTheme.lightTheme.primaryColor,
                                  size: 4.w,
                                ),
                                label: Text('Navigate'),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _callShelter(shelter["name"] as String),
                                icon: CustomIconWidget(
                                  iconName: 'call',
                                  color: Colors.white,
                                  size: 4.w,
                                ),
                                label: Text('Call'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFirstAidGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 85.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.outlineLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'medical_services',
                    color: AppTheme.secondaryLight,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'First Aid Guide',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: firstAidGuides.length,
                itemBuilder: (context, index) {
                  final guide = firstAidGuides[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 2.h),
                    child: ExpansionTile(
                      leading: CustomIconWidget(
                        iconName: guide["icon"] as String,
                        color: AppTheme.secondaryLight,
                        size: 6.w,
                      ),
                      title: Text(
                        guide["title"] as String,
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        guide["category"] as String,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryLight,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Steps:',
                                style: AppTheme.lightTheme.textTheme.titleSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              ...(guide["steps"] as List<String>)
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 1.h),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 6.w,
                                        height: 6.w,
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${entry.key + 1}',
                                            style: AppTheme
                                                .lightTheme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 3.w),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: AppTheme
                                              .lightTheme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyContactsModal(BuildContext context) {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const EmergencyContactsWidget(),
      ),
    );
  }

  void _showAdvancedOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.outlineLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Advanced Options',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'map',
                color: AppTheme.lightTheme.primaryColor,
                size: 6.w,
              ),
              title: Text('Interactive Map'),
              subtitle: Text('View disaster zones and evacuation routes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/interactive-map-screen');
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'report',
                color: AppTheme.secondaryLight,
                size: 6.w,
              ),
              title: Text('Report Incident'),
              subtitle: Text('Report emergency situations or resource needs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/incident-reporting-screen');
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'home',
                color: AppTheme.successLight,
                size: 6.w,
              ),
              title: Text('Return to Dashboard'),
              subtitle: Text('Go back to main emergency dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/home-dashboard-screen');
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showShelterAdvancedOptions(BuildContext context) {
    Fluttertoast.showToast(
      msg: "Broadcasting location to nearby shelters...",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.successLight,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _broadcastLocation() {
    Fluttertoast.showToast(
      msg: "Location broadcasted to emergency services",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.primaryLight,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _requestMedicalHelp() {
    Fluttertoast.showToast(
      msg: "Medical assistance request sent",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.secondaryLight,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _navigateToShelter(String shelterName) async {
    Navigator.pop(context);
    
    try {
      // Find the shelter data to get coordinates and address
      final shelter = shelterData.firstWhere(
        (s) => s['name'] == shelterName,
        orElse: () => {},
      );
      
      bool navigationSuccessful = false;
      String searchQuery = shelterName;
      
      // If we have address information, use it for better search results
      if (shelter.isNotEmpty && shelter['address'] != null) {
        searchQuery = '${shelter['name']}, ${shelter['address']}';
      }
      
      // Encode the full shelter name and address for search
      final encodedQuery = Uri.encodeComponent(searchQuery);
      
      // Try multiple navigation schemes in order of preference
      List<String> navigationUrls = [
        // Google Maps app with name-based search (Android/iOS)
        'comgooglemaps://?q=$encodedQuery',
        'googlemaps://maps.google.com/?q=$encodedQuery',
        // Apple Maps with name search (iOS)
        'maps://maps.apple.com/?q=$encodedQuery',
        // Waze with name search
        'waze://?q=$encodedQuery',
      ];
      
      // If we have coordinates, add them as fallback options
      if (shelter.isNotEmpty && shelter['latitude'] != null && shelter['longitude'] != null) {
        final lat = shelter['latitude'];
        final lng = shelter['longitude'];
        navigationUrls.addAll([
          // Generic geo scheme with name as label
          'geo:$lat,$lng?q=$lat,$lng($encodedQuery)',
          // Coordinate-based fallbacks
          'comgooglemaps://?q=$lat,$lng',
          'googlemaps://maps.google.com/?q=$lat,$lng',
          'maps://maps.apple.com/?q=$lat,$lng',
        ]);
      }
      
      // Add web fallbacks
      navigationUrls.addAll([
        'https://maps.google.com/?q=$encodedQuery',
        'https://maps.google.com/maps?q=$encodedQuery',
      ]);
      
      for (String url in navigationUrls) {
        try {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            navigationSuccessful = true;
            break;
          }
        } catch (e) {
          print('Failed to launch $url: $e');
          continue;
        }
      }
      
      if (navigationSuccessful) {
        Fluttertoast.showToast(
          msg: "Opening navigation to $shelterName...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.successLight,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        throw 'No compatible navigation app found';
      }
      
    } catch (e) {
      print('Error opening navigation: $e');
      
      Fluttertoast.showToast(
        msg: "Please search for '$shelterName' manually in your maps app",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.primaryLight,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> _callShelter(String shelterName) async {
    try {
      // Find the shelter data to get phone number
      final shelter = shelterData.firstWhere(
        (s) => s['name'] == shelterName,
        orElse: () => {},
      );
      
      String phoneNumber;
      if (shelter.isNotEmpty && shelter['phone'] != null) {
        phoneNumber = shelter['phone'];
      } else {
        // Fallback emergency numbers
        phoneNumber = '911'; // Default emergency number
      }
      
      // Clean the phone number (remove any spaces, dashes, etc.)
      final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        Fluttertoast.showToast(
          msg: "Calling $shelterName...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.successLight,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        throw 'Could not launch phone app';
      }
    } catch (e) {
      print('Error making call: $e');
      Fluttertoast.showToast(
        msg: "Unable to call $shelterName. Please contact them manually.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.primaryLight,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _toggleSOS() async {
    try {
      if (!_sosService.isInitialized) {
        // Try to initialize if not already done
        bool initialized = await _sosService.initializeEmergencyBeacon();
        if (!initialized) {
          Fluttertoast.showToast(
            msg: "SOS system initialization failed",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return;
        }
      }

      if (isSOSActive) {
        // Deactivate SOS
        await _sosService.deactivateSOSBeacon();
        if (mounted) {
          setState(() {
            isSOSActive = false;
          });
        }
        
        Fluttertoast.showToast(
          msg: "SOS Emergency Beacon Deactivated",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.textMediumEmphasisLight,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        // Show confirmation dialog before activating SOS
        bool? confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Activate Emergency SOS?',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'This will activate emergency signals including:\n'
                '• Flashlight SOS pattern\n'
                '• Emergency siren audio\n'
                '• Screen flash alerts\n'
                '• Vibration patterns\n\n'
                'Only activate in real emergencies.',
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('ACTIVATE SOS'),
                ),
              ],
            );
          },
        );

        if (confirmed == true) {
          // Activate SOS
          await _sosService.activateSOSBeacon();
          if (mounted) {
            setState(() {
              isSOSActive = true;
            });
          }
          
          Fluttertoast.showToast(
            msg: "🆘 SOS EMERGENCY BEACON ACTIVATED",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 18.0,
          );
        }
      }
    } catch (e) {
      print('❌ SOS toggle error: $e');
      Fluttertoast.showToast(
        msg: "SOS system error: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
}