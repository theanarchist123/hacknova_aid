import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/services/shelter_service.dart';
import '../../core/services/location_service.dart';
import './widgets/communication_tools_widget.dart';
import './widgets/emergency_action_card_widget.dart';
import './widgets/emergency_contacts_widget.dart';
import './widgets/emergency_status_widget.dart';

class EmergencyResponseScreen extends StatefulWidget {
  const EmergencyResponseScreen({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _initializeLocationAndShelters();
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
        
        setState(() {
          currentLocation = locationName;
        });
        
        // Load nearby shelters
        await _loadNearbyShelters();
      } else {
        setState(() {
          currentLocation = "Location unavailable";
        });
        _loadFallbackShelters();
      }
    } catch (e) {
      print('Error initializing location: $e');
      setState(() {
        currentLocation = "Location error";
      });
      _loadFallbackShelters();
    }
  }

  Future<void> _loadNearbyShelters() async {
    if (_currentPosition == null) return;
    
    setState(() => _isLoadingShelters = true);
    
    try {
      final shelters = await _shelterService.findNearbyShelters(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusM: 20000, // 20km radius
      );
      
      setState(() {
        shelterData = shelters;
      });
    } catch (e) {
      print('Error loading shelters: $e');
      _loadFallbackShelters();
    } finally {
      setState(() => _isLoadingShelters = false);
    }
  }

  void _loadFallbackShelters() {
    setState(() {
      shelterData = [
        {
          "name": "Emergency Response Center",
          "address": "Nearest available facility",
          "capacity": 500,
          "occupied": 120,
          "distance": 1.2,
          "amenities": ["Medical", "Food", "Wi-Fi"],
          "status": "Available"
        },
        {
          "name": "Community Safety Hub", 
          "address": "Local community center",
          "capacity": 300,
          "occupied": 89,
          "distance": 2.1,
          "amenities": ["Food", "Supplies", "Communication"],
          "status": "Available"
        }
      ];
    });
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
              // Emergency Status Indicator
              EmergencyStatusWidget(
                threatLevel: currentThreatLevel,
                location: currentLocation,
                statusColor: _getThreatLevelColor(currentThreatLevel),
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

              // SOS Emergency Button
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

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }

  Color _getThreatLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':
        return AppTheme.primaryLight;
      case 'MEDIUM':
        return AppTheme.secondaryLight;
      case 'LOW':
        return AppTheme.successLight;
      default:
        return AppTheme.primaryLight;
    }
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
                        final occupancyRate = (shelter["occupied"] as int) /
                            (shelter["capacity"] as int);
                        final distance = shelter["distance"];
                        final distanceText = distance is double 
                          ? '${distance.toStringAsFixed(1)} km'
                          : distance.toString();

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
                              "${(shelter["distance"] as double).toStringAsFixed(1)} km",
                              style: AppTheme.lightTheme.textTheme.bodyMedium,
                            ),
                            const Spacer(),
                            Text(
                              '${shelter["occupied"]}/${shelter["capacity"]} occupied',
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
                              }).toList(),
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
      // Find the shelter data to get coordinates
      final shelter = shelterData.firstWhere(
        (s) => s['name'] == shelterName,
        orElse: () => {},
      );
      
      Uri mapUri;
      
      if (shelter.isNotEmpty && shelter['latitude'] != null && shelter['longitude'] != null) {
        // Use coordinates for precise navigation
        final lat = shelter['latitude'];
        final lng = shelter['longitude'];
        
        // For mobile platforms, use the geo: scheme which works across platforms
        mapUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(shelterName)})');
        
        // Fallback to Google Maps URL if geo scheme doesn't work
        if (!await canLaunchUrl(mapUri)) {
          mapUri = Uri.parse('https://maps.google.com/maps?q=$lat,$lng');
        }
      } else {
        // Fallback: search by name using Google Maps
        final encodedName = Uri.encodeComponent(shelterName);
        mapUri = Uri.parse('https://maps.google.com/maps?q=$encodedName');
      }
      
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
        Fluttertoast.showToast(
          msg: "Opening maps for $shelterName...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.successLight,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        throw 'Could not launch maps application';
      }
    } catch (e) {
      print('Error opening maps: $e');
      
      // Alternative approach - provide manual instructions
      if (shelterData.any((s) => s['name'] == shelterName)) {
        final shelter = shelterData.firstWhere((s) => s['name'] == shelterName);
        final lat = shelter['latitude'];
        final lng = shelter['longitude'];
        
        if (lat != null && lng != null) {
          Fluttertoast.showToast(
            msg: "Maps app not available. Search coordinates: $lat, $lng in your maps app",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: AppTheme.primaryLight,
            textColor: Colors.white,
            fontSize: 14.0,
          );
        } else {
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

  void _toggleSOS() {
    setState(() {
      isSOSActive = !isSOSActive;
    });

    if (isSOSActive) {
      Fluttertoast.showToast(
        msg: "SOS ACTIVATED - Broadcasting emergency signal",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: AppTheme.primaryLight,
        textColor: Colors.white,
        fontSize: 18.0,
      );
    } else {
      Fluttertoast.showToast(
        msg: "SOS signal deactivated",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.textMediumEmphasisLight,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
}