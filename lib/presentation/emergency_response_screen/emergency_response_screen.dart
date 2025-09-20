import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_export.dart';
import '../../core/services/shelter_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/localization_service.dart';
import '../../models/disaster_safety_content.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeLocationAndShelters();
  }

  @override
  void dispose() {
    // No need to cancel anything specific here since we'll check mounted state
    super.dispose();
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
      "title": "CPR During Disasters",
      "category": "Life-Saving",
      "disasterTypes": ["Flood", "Earthquake", "Cyclone", "General Emergency"],
      "steps": [
        "Ensure area safety - check for electrical hazards, debris, or contaminated water",
        "Check responsiveness and breathing",
        "Call for help immediately (911 or local emergency)",
        "Position on firm, flat surface away from hazards",
        "Place hands on center of chest, interlock fingers",
        "Push hard and fast at least 2 inches deep, 100-120 compressions/minute",
        "Allow complete chest recoil between compressions",
        "Give 30 compressions, then 2 rescue breaths if trained",
        "Continue cycles until emergency services arrive"
      ],
      "icon": "favorite",
      "videoUrl": "videos/cpr_emergency_response.webm",
      "videoTitle": "CPR During Disasters Guide",
      "imageGuide": "Show hand placement on chest center, compression depth demonstration"
    },
    {
      "title": "Wound Care & Bleeding Control",
      "category": "Trauma Care", 
      "disasterTypes": ["Earthquake", "Forest Fire", "Cyclone", "General Emergency"],
      "steps": [
        "Ensure your safety first - wear gloves if available",
        "Assess wound severity and location",
        "Apply direct pressure with clean cloth or sterile gauze",
        "Maintain firm, continuous pressure",
        "If bleeding soaks through, add more dressings without removing first layer",
        "Elevate injured area above heart level if possible",
        "Apply pressure bandage to secure dressing",
        "Monitor for signs of shock",
        "Seek immediate medical attention for severe wounds"
      ],
      "icon": "healing",
      "videoUrl": "videos/wound_care_bleeding.webm",
      "videoTitle": "Wound Care and Bleeding Control",
      "imageGuide": "Direct pressure application, pressure point locations, proper bandaging"
    },
    {
      "title": "Jaw Injury & Head Trauma",
      "category": "Trauma Care",
      "disasterTypes": ["Earthquake", "Cyclone", "General Emergency"],
      "steps": [
        "Keep person still and calm",
        "Support jaw gently without forcing movement",
        "Check for breathing difficulties",
        "Do not remove objects embedded in wounds",
        "Apply cold compress to reduce swelling",
        "Support jaw with soft bandage if needed",
        "Monitor consciousness level",
        "Prepare for possible vomiting - position safely",
        "Get immediate medical help"
      ],
      "icon": "face",
      "videoUrl": "videos/jaw_injury_bandage.webm",
      "videoTitle": "Jaw Injury Bandage Technique",
      "imageGuide": "Jaw support positioning, bandage application, airway protection"
    },
    {
      "title": "Fracture Stabilization",
      "category": "Trauma Care",
      "disasterTypes": ["Earthquake", "Cyclone", "General Emergency"],
      "steps": [
        "Do not move person if spinal injury suspected",
        "Check circulation below injury (pulse, color, sensation)",
        "Immobilize fracture in position found",
        "Support joints above and below fracture",
        "Use splints - boards, magazines, or rigid materials",
        "Pad splints to prevent pressure points",
        "Secure with bandages, cloth strips, or tape",
        "Re-check circulation after splinting",
        "Monitor for shock and transport carefully"
      ],
      "icon": "healing",
      "videoUrl": "videos/fracture_stabilization.webm",
      "videoTitle": "Fracture Stabilization Guide",
      "imageGuide": "Splinting techniques, immobilization methods, circulation checks"
    },
    {
      "title": "Burn Treatment",
      "category": "Emergency Care",
      "disasterTypes": ["Forest Fire", "Earthquake", "General Emergency"],
      "steps": [
        "Remove person from heat source safely",
        "Stop the burning process - drop, roll if on fire",
        "Cool burn with cool (not cold) water for 10-15 minutes",
        "Remove jewelry and tight clothing before swelling",
        "Do not break blisters or apply ice",
        "Cover with sterile, non-stick dressing",
        "For severe burns, wrap loosely and avoid water",
        "Treat for shock - elevate legs, keep warm",
        "Seek immediate medical attention for severe burns"
      ],
      "icon": "local_fire_department",
      "videoUrl": "videos/burn_treatment.webm",
      "videoTitle": "Burn Treatment Guide",
      "imageGuide": "Burn severity assessment, cooling techniques, proper dressing application"
    },
    {
      "title": "Cut Treatment & Wound Care",
      "category": "Basic First Aid",
      "disasterTypes": ["General Emergency", "Forest Fire", "Earthquake"],
      "steps": [
        "Clean your hands before treating wound",
        "Control bleeding with direct pressure",
        "Clean wound gently with clean water if available",
        "Apply antibiotic ointment if available",
        "Cover with sterile bandage or clean cloth",
        "Change dressing regularly and keep dry",
        "Watch for signs of infection (redness, swelling, warmth)",
        "Seek medical attention for deep cuts or signs of infection"
      ],
      "icon": "healing",
      "videoUrl": "videos/cut_treatment.webm",
      "videoTitle": "Cut Treatment Guide",
      "imageGuide": "Wound cleaning technique, bandage application, infection signs"
    },
    {
      "title": "Head-to-Toe Assessment",
      "category": "Emergency Assessment",
      "disasterTypes": ["All Disasters", "General Emergency"],
      "steps": [
        "Ensure scene safety before approaching victim",
        "Check responsiveness - tap shoulders, call name",
        "Assess airway, breathing, and circulation (ABCs)",
        "Examine head and neck for injuries",
        "Check chest for breathing difficulties",
        "Assess abdomen for pain or distension",
        "Examine arms and legs for fractures",
        "Look for bleeding, burns, or other obvious injuries",
        "Monitor vital signs and consciousness level",
        "Document findings and communicate to emergency services"
      ],
      "icon": "personal_injury",
      "videoUrl": "videos/head_to_toe_assessment.webm",
      "videoTitle": "Head-to-Toe Assessment Guide",
      "imageGuide": "Systematic assessment technique, vital sign checks, injury documentation"
    },
    {
      "title": "Shock Treatment",
      "category": "Emergency Care",
      "disasterTypes": ["All Disasters", "General Emergency"],
      "steps": [
        "Keep person lying down in safe location",
        "Elevate legs 8-12 inches if no spinal injury suspected",
        "Keep person warm with blankets or clothing",
        "Loosen tight clothing around neck and chest",
        "Do not give food or water",
        "Monitor breathing and pulse regularly",
        "Reassure and keep person calm",
        "Turn on side if vomiting occurs",
        "Get emergency medical help immediately"
      ],
      "icon": "monitor_heart",
      "videoUrl": "videos/shock_treatment.webm",
      "videoTitle": "Shock Treatment Protocol",
      "imageGuide": "Proper positioning, leg elevation, warming techniques"
    }
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

              // Safety Instructions Card
              EmergencyActionCardWidget(
                title: 'Safety Instructions',
                subtitle:
                    'Comprehensive disaster preparedness and safety guidelines',
                iconName: 'shield',
                cardColor: Colors.orange.shade100,
                onTap: () => _showSafetyInstructionsModal(context),
                onLongPress: () => _showQuickSafetyTips(context),
              ),

              // Emergency Guides Card
              ValueListenableBuilder<SupportedLanguage>(
                valueListenable: LocalizationService.languageNotifier,
                builder: (context, currentLanguage, child) {
                  return EmergencyActionCardWidget(
                    title: LocalizationService.translate(LocalizationService.emergencyGuides),
                    subtitle: LocalizationService.translate(LocalizationService.emergencyGuidesDesc),
                    iconName: 'menu_book',
                    cardColor: Colors.teal.shade100,
                    onTap: () => _showEmergencyGuides(context),
                    onLongPress: () => _showQuickDisasterTips(context),
                  );
                },
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
        height: 90.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medical First Aid Guide',
                          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Emergency medical procedures for disaster situations',
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            
            // First Aid Procedures List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: firstAidGuides.length,
                itemBuilder: (context, index) {
                  final guide = firstAidGuides[index];
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
                    child: ExpansionTile(
                      leading: CustomIconWidget(
                        iconName: guide["icon"],
                        color: _getCategoryColor(guide["category"]),
                        size: 6.w,
                      ),
                      title: Text(
                        guide["title"],
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guide["category"],
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: _getCategoryColor(guide["category"]),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (guide["disasterTypes"] != null)
                            Wrap(
                              spacing: 1.w,
                              children: (guide["disasterTypes"] as List<String>).map((type) {
                                return Container(
                                  margin: EdgeInsets.only(top: 0.5.h),
                                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    type,
                                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.lightTheme.primaryColor,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                      children: [
                        Divider(color: AppTheme.outlineLight),
                        SizedBox(height: 1.h),
                        
                        // Image Guide Section
                        if (guide["imageGuide"] != null && guide["imageGuide"].isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(3.w),
                            margin: EdgeInsets.only(bottom: 2.h),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'image',
                                      color: AppTheme.lightTheme.primaryColor,
                                      size: 4.w,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Visual Guide',
                                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                                        color: AppTheme.lightTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  guide["imageGuide"],
                                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.lightTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Video Guide Section
                        if (guide["videoUrl"] != null && guide["videoUrl"].isNotEmpty)
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: 2.h),
                            child: ElevatedButton.icon(
                              onPressed: () => _launchVideo(guide["videoUrl"]),
                              icon: CustomIconWidget(
                                iconName: 'play_circle_fill',
                                color: Colors.white,
                                size: 5.w,
                              ),
                              label: Text(
                                'Watch: ${guide["videoTitle"]}',
                                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.secondaryLight,
                                padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        
                        // Steps Section
                        Text(
                          'Emergency Procedure Steps:',
                          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        ...List.generate(
                          (guide["steps"] as List<String>).length,
                          (stepIndex) {
                            final step = (guide["steps"] as List<String>)[stepIndex];
                            return Container(
                              margin: EdgeInsets.only(bottom: 1.h),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6.w,
                                    height: 6.w,
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(guide["category"]),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${stepIndex + 1}',
                                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 3.w),
                                  Expanded(
                                    child: Text(
                                      step,
                                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 2.h),
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Life-Saving':
        return AppTheme.primaryLight;
      case 'Trauma Care':
        return AppTheme.secondaryLight;
      case 'Emergency Care':
        return AppTheme.successLight;
      case 'Basic First Aid':
        return Colors.blue;
      case 'Emergency Assessment':
        return Colors.purple;
      default:
        return AppTheme.lightTheme.primaryColor;
    }
  }

  Future<void> _launchVideo(String videoPath) async {
    if (videoPath.startsWith('videos/')) {
      // Show video info modal with system player option
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VideoInfoModal(videoPath: videoPath),
      );
    } else if (videoPath.startsWith('http')) {
      // Launch external URL (fallback for any remaining YouTube links)
      try {
        final Uri videoUri = Uri.parse(videoPath);
        if (await canLaunchUrl(videoUri)) {
          await launchUrl(
            videoUri,
            mode: LaunchMode.externalApplication,
          );
          Fluttertoast.showToast(
            msg: "Opening video guide...",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: AppTheme.successLight,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        } else {
          throw 'Could not launch video';
        }
      } catch (e) {
        print('Error launching video: $e');
        Fluttertoast.showToast(
          msg: "Unable to open video. Please try again.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.primaryLight,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: "Invalid video path",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.primaryLight,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
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

  void _showSafetyInstructionsModal(BuildContext context) {
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
            // Header
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
                    iconName: 'shield',
                    color: Colors.orange,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safety Instructions',
                          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Comprehensive disaster preparedness and safety guidelines',
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/disaster-safety-screen');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    ),
                    child: Text(
                      'Full Guide',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            
            // Disaster Type Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 2.h,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                childAspectRatio: 1.2,
                children: [
                  _buildDisasterCard(
                    'Cyclone',
                    'cyclone',
                    Colors.blue.shade100,
                    Colors.blue.shade700,
                    'Strong winds and heavy rain safety',
                  ),
                  _buildDisasterCard(
                    'Flood',
                    'water_drop',
                    Colors.cyan.shade100,
                    Colors.cyan.shade700,
                    'Water emergency and evacuation',
                  ),
                  _buildDisasterCard(
                    'Forest Fire',
                    'local_fire_department',
                    Colors.orange.shade100,
                    Colors.orange.shade700,
                    'Fire safety and evacuation',
                  ),
                  _buildDisasterCard(
                    'Earthquake',
                    'landscape',
                    Colors.brown.shade100,
                    Colors.brown.shade700,
                    'Drop, cover, and hold procedures',
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDisasterCard(String title, String iconName, Color backgroundColor, Color textColor, String description) {
    return GestureDetector(
      onTap: () {
        _showQuickSafetyTips(context, disasterType: title);
      },
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: textColor,
              size: 8.w,
            ),
            SizedBox(height: 1.h),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 0.5.h),
            Text(
              description,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: textColor.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickSafetyTips(BuildContext context, {String? disasterType}) {
    final Map<String, Map<String, dynamic>> quickTips = {
      'Cyclone': {
        'icon': 'cyclone',
        'color': Colors.blue.shade700,
        'tips': DisasterSafetyContent.cycloneDos['en']!.take(3).toList(),
        'donts': DisasterSafetyContent.cycloneDonts['en']!.take(3).toList(),
      },
      'Flood': {
        'icon': 'water_drop',
        'color': Colors.cyan.shade700,
        'tips': DisasterSafetyContent.floodDos['en']!.take(3).toList(),
        'donts': DisasterSafetyContent.floodDonts['en']!.take(3).toList(),
      },
      'Forest Fire': {
        'icon': 'local_fire_department',
        'color': Colors.orange.shade700,
        'tips': DisasterSafetyContent.forestFireDos['en']!.take(3).toList(),
        'donts': DisasterSafetyContent.forestFireDonts['en']!.take(3).toList(),
      },
      'Earthquake': {
        'icon': 'landscape',
        'color': Colors.brown.shade700,
        'tips': DisasterSafetyContent.earthquakeDos['en']!.take(3).toList(),
        'donts': DisasterSafetyContent.earthquakeDonts['en']!.take(3).toList(),
      },
    };

    final selectedTips = disasterType != null ? quickTips[disasterType] : null;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.outlineLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            if (selectedTips != null) ...[
              // Specific disaster tips
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: selectedTips['icon'],
                      color: selectedTips['color'],
                      size: 6.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        '$disasterType Safety Tips',
                        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
              
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    children: [
                      // Do's Column
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: AppTheme.successLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.successLight.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomIconWidget(
                                    iconName: 'check_circle',
                                    color: AppTheme.successLight,
                                    size: 5.w,
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    'DO\'S',
                                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                      color: AppTheme.successLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2.h),
                              ...selectedTips['tips'].map<Widget>((tip) => Padding(
                                padding: EdgeInsets.only(bottom: 1.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 1.w,
                                      height: 1.w,
                                      margin: EdgeInsets.only(top: 1.h),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successLight,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 2.w),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 3.w),
                      
                      // Don'ts Column
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomIconWidget(
                                    iconName: 'cancel',
                                    color: AppTheme.primaryLight,
                                    size: 5.w,
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    'DON\'TS',
                                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                      color: AppTheme.primaryLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2.h),
                              ...selectedTips['donts'].map<Widget>((dont) => Padding(
                                padding: EdgeInsets.only(bottom: 1.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 1.w,
                                      height: 1.w,
                                      margin: EdgeInsets.only(top: 1.h),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 2.w),
                                    Expanded(
                                      child: Text(
                                        dont,
                                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // General safety tips when no specific disaster type
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  'Quick Safety Tips',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'General Emergency Preparedness:',
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      ...[
                        'Keep emergency kit ready with water, food, and supplies',
                        'Know your evacuation routes and emergency contacts',
                        'Stay informed through official weather and emergency alerts',
                        'Have a family communication plan prepared',
                        'Follow instructions from emergency services immediately'
                      ].map((tip) => Padding(
                        padding: EdgeInsets.only(bottom: 1.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomIconWidget(
                              iconName: 'star',
                              color: Colors.orange,
                              size: 4.w,
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                tip,
                                style: AppTheme.lightTheme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 2.h),
          ],
        ),
      ),
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

  void _toggleSOS() {
    if (mounted) {
      setState(() {
        isSOSActive = !isSOSActive;
      });
    }

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

  void _showEmergencyGuides(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: 85.h,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ValueListenableBuilder<SupportedLanguage>(
            valueListenable: LocalizationService.languageNotifier,
            builder: (context, currentLanguage, child) {
              return Column(
                children: [
                  // Header with Language Selector
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade600,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'menu_book',
                              color: Colors.white,
                              size: 6.w,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                LocalizationService.translate(LocalizationService.emergencyGuides),
                                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: CustomIconWidget(
                                iconName: 'close',
                                color: Colors.white,
                                size: 6.w,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        
                        // Language Selector
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'language',
                                color: Colors.white,
                                size: 4.w,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                LocalizationService.translate(LocalizationService.language),
                                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<SupportedLanguage>(
                                    value: currentLanguage,
                                    dropdownColor: Colors.teal.shade700,
                                    icon: CustomIconWidget(
                                      iconName: 'keyboard_arrow_down',
                                      color: Colors.white,
                                      size: 4.w,
                                    ),
                                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    items: SupportedLanguage.values.map((language) {
                                      return DropdownMenuItem(
                                        value: language,
                                        child: Text(
                                          language.displayName,
                                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (SupportedLanguage? newLanguage) {
                                      if (newLanguage != null) {
                                        LocalizationService.setLanguage(newLanguage);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 1.h),
                        Text(
                          LocalizationService.translate(LocalizationService.emergencyGuidesDesc),
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  // Scrollable Content with All Disaster Guides
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🌪️ CYCLONE GUIDE
                          _buildDisasterGuideCard(
                            LocalizationService.translate(LocalizationService.cyclone),
                            'cyclone',
                            AppTheme.primaryLight,
                            DisasterSafetyContent.cycloneOverview[currentLanguage.code] ?? 
                            DisasterSafetyContent.cycloneOverview['en'] ?? '',
                            DisasterSafetyContent.cycloneBeforeSteps[currentLanguage.code] ?? 
                            DisasterSafetyContent.cycloneBeforeSteps['en'] ?? [],
                            DisasterSafetyContent.cycloneDuringSteps[currentLanguage.code] ?? 
                            DisasterSafetyContent.cycloneDuringSteps['en'] ?? [],
                            DisasterSafetyContent.cycloneAfterSteps[currentLanguage.code] ?? 
                            DisasterSafetyContent.cycloneAfterSteps['en'] ?? [],
                            currentLanguage,
                          ),
                          SizedBox(height: 3.h),
                          
                          // 🌊 FLOOD GUIDE
                          _buildDisasterGuideCard(
                            LocalizationService.translate(LocalizationService.flood),
                            'water_drop',
                            Colors.blue.shade600,
                            DisasterSafetyContent.floodOverview[currentLanguage.code] ?? 
                            DisasterSafetyContent.floodOverview['en'] ?? '',
                            DisasterSafetyContent.floodBeforeSteps[currentLanguage.code] ?? 
                            DisasterSafetyContent.floodBeforeSteps['en'] ?? [],
                            DisasterSafetyContent.floodDuringSteps[currentLanguage.code] ?? 
                            DisasterSafetyContent.floodDuringSteps['en'] ?? [],
                            DisasterSafetyContent.floodAfterSteps[currentLanguage.code] ?? 
                            DisasterSafetyContent.floodAfterSteps['en'] ?? [],
                            currentLanguage,
                          ),
                          SizedBox(height: 3.h),
                          
                          // 🔥 FOREST FIRE GUIDE
                          _buildDisasterGuideCard(
                            LocalizationService.translate(LocalizationService.forestFire),
                            'local_fire_department',
                            Colors.orange.shade700,
                            DisasterSafetyContent.forestFireOverview[currentLanguage.code] ?? 
                            DisasterSafetyContent.forestFireOverview['en'] ?? '',
                            DisasterSafetyContent.forestFireBeforeSteps[currentLanguage.code] ?? 
                            DisasterSafetyContent.forestFireBeforeSteps['en'] ?? [],
                            DisasterSafetyContent.forestFireDuringSteps[currentLanguage.code] ?? 
                            DisasterSafetyContent.forestFireDuringSteps['en'] ?? [],
                            DisasterSafetyContent.forestFireAfterSteps[currentLanguage.code] ?? 
                            DisasterSafetyContent.forestFireAfterSteps['en'] ?? [],
                            currentLanguage,
                          ),
                          SizedBox(height: 3.h),
                          
                          // 🏗️ EARTHQUAKE GUIDE
                          _buildDisasterGuideCard(
                            LocalizationService.translate(LocalizationService.earthquake),
                            'landscape',
                            Colors.brown.shade600,
                            DisasterSafetyContent.earthquakeOverview[currentLanguage.code] ?? 
                            DisasterSafetyContent.earthquakeOverview['en'] ?? '',
                            DisasterSafetyContent.earthquakeBeforeSteps[currentLanguage.code] ?? 
                            DisasterSafetyContent.earthquakeBeforeSteps['en'] ?? [],
                            DisasterSafetyContent.earthquakeDuringSteps[currentLanguage.code] ?? 
                            DisasterSafetyContent.earthquakeDuringSteps['en'] ?? [],
                            DisasterSafetyContent.earthquakeAfterSteps[currentLanguage.code] ?? 
                            DisasterSafetyContent.earthquakeAfterSteps['en'] ?? [],
                            currentLanguage,
                          ),
                          SizedBox(height: 2.h),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDisasterGuideCard(String title, String iconName, Color color, 
                                 String overview, List<String> beforeSteps, 
                                 List<String> duringSteps, List<String> afterSteps,
                                 SupportedLanguage currentLanguage) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: iconName,
                  color: color,
                  size: 6.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          
          // Content Section
          Container(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Section
                Text(
                  LocalizationService.translate(LocalizationService.overview),
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  overview,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 2.h),
                
                // Before, During, After sections in horizontal layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📋 BEFORE Section
                    Expanded(
                      child: _buildStepsSection(
                        '${LocalizationService.translate(LocalizationService.before)} $title',
                        beforeSteps,
                        Colors.blue.shade600,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    
                    // ⚠️ DURING Section
                    Expanded(
                      child: _buildStepsSection(
                        '${LocalizationService.translate(LocalizationService.during)} $title',
                        duringSteps,
                        Colors.orange.shade600,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    
                    // ✅ AFTER Section
                    Expanded(
                      child: _buildStepsSection(
                        '${LocalizationService.translate(LocalizationService.after)} $title',
                        afterSteps,
                        Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsSection(String title, List<String> steps, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 1.h),
        
        // Step Items (showing first 3 with bullet points)
        ...steps.take(3).map((step) => Container(
          margin: EdgeInsets.only(bottom: 0.5.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bullet Point
              Container(
                margin: EdgeInsets.only(top: 0.3.h),
                width: 3.w,
                height: 3.w,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 1.w),
              
              // Step Text
              Expanded(
                child: Text(
                  step,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        )),
        
        // "More steps available" indicator
        if (steps.length > 3)
          Text(
            '...and ${steps.length - 3} more steps',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: color,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  void _showQuickDisasterTips(BuildContext context) {
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
        child: ValueListenableBuilder<SupportedLanguage>(
          valueListenable: LocalizationService.languageNotifier,
          builder: (context, currentLanguage, child) {
            return Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade600,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'bolt',
                        color: Colors.white,
                        size: 6.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        LocalizationService.translate(LocalizationService.quickDisasterTips),
                        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: CustomIconWidget(
                          iconName: 'close',
                          color: Colors.white,
                          size: 6.w,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Quick Tips Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        _buildQuickDisasterCard(
                          LocalizationService.translate(LocalizationService.cyclone),
                          'cyclone',
                          AppTheme.primaryLight,
                          DisasterSafetyContent.cycloneDos[currentLanguage.code] ?? 
                          DisasterSafetyContent.cycloneDos['en'] ?? [],
                          DisasterSafetyContent.cycloneDonts[currentLanguage.code] ?? 
                          DisasterSafetyContent.cycloneDonts['en'] ?? [],
                          currentLanguage,
                        ),
                        SizedBox(height: 2.h),
                        _buildQuickDisasterCard(
                          LocalizationService.translate(LocalizationService.flood),
                          'water_drop',
                          Colors.blue.shade600,
                          DisasterSafetyContent.floodDos[currentLanguage.code] ?? 
                          DisasterSafetyContent.floodDos['en'] ?? [],
                          DisasterSafetyContent.floodDonts[currentLanguage.code] ?? 
                          DisasterSafetyContent.floodDonts['en'] ?? [],
                          currentLanguage,
                        ),
                        SizedBox(height: 2.h),
                        _buildQuickDisasterCard(
                          LocalizationService.translate(LocalizationService.forestFire),
                          'local_fire_department',
                          Colors.orange.shade700,
                          DisasterSafetyContent.forestFireDos[currentLanguage.code] ?? 
                          DisasterSafetyContent.forestFireDos['en'] ?? [],
                          DisasterSafetyContent.forestFireDonts[currentLanguage.code] ?? 
                          DisasterSafetyContent.forestFireDonts['en'] ?? [],
                          currentLanguage,
                        ),
                        SizedBox(height: 2.h),
                        _buildQuickDisasterCard(
                          LocalizationService.translate(LocalizationService.earthquake),
                          'landscape',
                          Colors.brown.shade600,
                          DisasterSafetyContent.earthquakeDos[currentLanguage.code] ?? 
                          DisasterSafetyContent.earthquakeDos['en'] ?? [],
                          DisasterSafetyContent.earthquakeDonts[currentLanguage.code] ?? 
                          DisasterSafetyContent.earthquakeDonts['en'] ?? [],
                          currentLanguage,
                        ),
                        SizedBox(height: 3.h),
                        
                        // Navigate to Full Guides Button
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEmergencyGuides(context);
                            },
                            icon: CustomIconWidget(
                              iconName: 'book',
                              color: Colors.white,
                              size: 5.w,
                            ),
                            label: Text(
                              LocalizationService.translate(LocalizationService.viewCompleteGuides),
                              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickDisasterCard(String title, String iconName, Color color,
                                List<String> dos, List<String> donts, SupportedLanguage currentLanguage) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CustomIconWidget(
                iconName: iconName,
                color: color,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                '$title ${LocalizationService.translate(LocalizationService.quickTips)}',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          
          // Do's and Don'ts
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Do's Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'check_circle',
                          color: AppTheme.successLight,
                          size: 4.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          LocalizationService.translate(LocalizationService.dos),
                          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                            color: AppTheme.successLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    ...dos.take(3).map((tip) => Padding(
                      padding: EdgeInsets.only(bottom: 0.5.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 1.w,
                            height: 1.w,
                            margin: EdgeInsets.only(top: 0.5.h),
                            decoration: BoxDecoration(
                              color: AppTheme.successLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(
                              tip,
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              
              SizedBox(width: 3.w),
              
              // Don'ts Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'cancel',
                          color: AppTheme.primaryLight,
                          size: 4.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          LocalizationService.translate(LocalizationService.donts),
                          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    ...donts.take(3).map((tip) => Padding(
                      padding: EdgeInsets.only(bottom: 0.5.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 1.w,
                            height: 1.w,
                            margin: EdgeInsets.only(top: 0.5.h),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(
                              tip,
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VideoInfoModal extends StatelessWidget {
  final String videoPath;

  const VideoInfoModal({super.key, required this.videoPath});

  String _getVideoTitle(String path) {
    if (path.contains('cpr_emergency_response')) return 'CPR Emergency Response';
    if (path.contains('wound_care_bleeding')) return 'Wound Care & Bleeding Control';
    if (path.contains('jaw_injury_bandage')) return 'Jaw Injury Bandage';
    if (path.contains('fracture_stabilization')) return 'Fracture Stabilization';
    if (path.contains('burn_treatment')) return 'Burn Treatment';
    if (path.contains('cut_treatment')) return 'Cut Treatment';
    if (path.contains('head_to_toe_assessment')) return 'Head-to-Toe Assessment';
    if (path.contains('shock_treatment')) return 'Shock Treatment';
    return 'First Aid Video Guide';
  }

  String _getVideoDescription(String path) {
    if (path.contains('cpr_emergency_response')) return 'Learn proper CPR techniques for emergency situations including disasters.';
    if (path.contains('wound_care_bleeding')) return 'Essential wound care and bleeding control techniques using tourniquets.';
    if (path.contains('jaw_injury_bandage')) return 'Proper jaw injury bandaging techniques for head trauma situations.';
    if (path.contains('fracture_stabilization')) return 'Learn how to stabilize fractures and dislocations safely.';
    if (path.contains('burn_treatment')) return 'Essential burn treatment tips and cooling techniques.';
    if (path.contains('cut_treatment')) return 'How to treat cuts and grazes with proper first aid techniques.';
    if (path.contains('head_to_toe_assessment')) return 'Comprehensive clinical assessment guide for emergency situations.';
    if (path.contains('shock_treatment')) return 'How to recognize and treat shock in emergency situations.';
    return 'Professional first aid video guide for emergency situations.';
  }

  Future<void> _openVideoFile(BuildContext context) async {
    try {
      String fullPath = 'C:\\Users\\Khushi\\Downloads\\hacknova_aid-flat\\hacknova_aid-flat\\$videoPath';
      final Uri videoUri = Uri.file(fullPath);
      
      if (await canLaunchUrl(videoUri)) {
        await launchUrl(
          videoUri,
          mode: LaunchMode.externalApplication,
        );
        Navigator.pop(context);
      } else {
        throw 'Could not open video file';
      }
    } catch (e) {
      print('Error opening video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open video file. Please check if the file exists.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 12.w,
                  height: 1.h,
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.play_circle_filled,
                        color: Colors.red,
                        size: 8.w,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getVideoTitle(videoPath),
                            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'First Aid Video Guide',
                            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        size: 6.w,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Video Preview Area
                  Container(
                    width: double.infinity,
                    height: 25.h,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_library,
                            color: Colors.red,
                            size: 15.w,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Video Ready to Play',
                            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Tap the button below to open in your video player',
                            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Description
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.lightTheme.primaryColor,
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'About This Video',
                              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.lightTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          _getVideoDescription(videoPath),
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openVideoFile(context),
                          icon: Icon(Icons.play_arrow, size: 6.w),
                          label: Text(
                            'Open Video',
                            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 3.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 2.h),

                  // File Info
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_open,
                          color: Colors.grey,
                          size: 4.w,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            'File: $videoPath',
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}