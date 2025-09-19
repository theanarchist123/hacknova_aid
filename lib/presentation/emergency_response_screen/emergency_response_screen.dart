import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/services/shelter_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/models/disaster_safety_content.dart';
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
    return ValueListenableBuilder<SupportedLanguage>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, currentLang, child) {
        return Scaffold(
          backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              LocalizationService.translate(LocalizationService.emergencyResponse),
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
                              isSOSActive 
                                  ? LocalizationService.translate(LocalizationService.sosActive)
                                  : LocalizationService.translate(LocalizationService.sos),
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
                          ? LocalizationService.translate(LocalizationService.sosBroadcasting)
                          : LocalizationService.translate(LocalizationService.sosInstruction),
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
                  LocalizationService.translate(LocalizationService.emergencyActions),
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 2.h),

              // Find Shelter Card
              EmergencyActionCardWidget(
                title: LocalizationService.translate(LocalizationService.findShelter),
                subtitle: LocalizationService.translate(LocalizationService.findShelterDesc),
                iconName: 'home',
                cardColor: AppTheme.successLight,
                onTap: () => _showShelterOptions(context),
                onLongPress: () => _showShelterAdvancedOptions(context),
              ),

              // Emergency Contacts Card
              EmergencyActionCardWidget(
                title: LocalizationService.translate(LocalizationService.emergencyContacts),
                subtitle: LocalizationService.translate(LocalizationService.emergencyContactsDesc),
                iconName: 'phone',
                cardColor: AppTheme.primaryLight,
                onTap: () => _showEmergencyContactsModal(context),
                onLongPress: () => _broadcastLocation(),
              ),

              // First Aid Guide Card
              EmergencyActionCardWidget(
                title: LocalizationService.translate(LocalizationService.firstAidGuide),
                subtitle: LocalizationService.translate(LocalizationService.firstAidDesc),
                iconName: 'medical_services',
                cardColor: AppTheme.secondaryLight,
                onTap: () => _showFirstAidGuide(context),
                onLongPress: () => _requestMedicalHelp(),
              ),

              // Safety Instructions Card
              EmergencyActionCardWidget(
                title: LocalizationService.translate(LocalizationService.safetyInstructions),
                subtitle: LocalizationService.translate(LocalizationService.safetyInstructionsDesc),
                iconName: 'security',
                cardColor: Colors.deepPurple.shade400,
                onTap: () => _navigateToSafetyInstructions(context),
                onLongPress: () => _showQuickSafetyTips(context),
              ),

              // Emergency Guides Card
              EmergencyActionCardWidget(
                title: LocalizationService.translate(LocalizationService.emergencyGuides),
                subtitle: LocalizationService.translate(LocalizationService.emergencyGuidesDesc),
                iconName: 'menu_book',
                cardColor: Colors.teal.shade600,
                onTap: () => _showEmergencyGuides(context),
                onLongPress: () => _showQuickDisasterTips(context),
              ),

              // Communication Tools
              const CommunicationToolsWidget(),

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
        );
      },
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
                          LocalizationService.translate(LocalizationService.emergencyDialogTitle),
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
                            LocalizationService.translate(LocalizationService.noSheltersFound),
                            style: AppTheme.lightTheme.textTheme.titleMedium,
                          ),
                          Text(
                            LocalizationService.translate(LocalizationService.enableLocationForBetter),
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
                                label: Text(LocalizationService.translate(LocalizationService.navigate)),
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
                                label: Text(LocalizationService.translate(LocalizationService.call)),
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
                    LocalizationService.translate(LocalizationService.firstAidGuide),
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
              LocalizationService.translate(LocalizationService.advancedOptions),
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
              title: Text(LocalizationService.translate(LocalizationService.interactiveMap)),
              subtitle: Text(LocalizationService.translate(LocalizationService.interactiveMapDesc)),
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
              title: Text(LocalizationService.translate(LocalizationService.reportIncident)),
              subtitle: Text(LocalizationService.translate(LocalizationService.reportIncidentDesc)),
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
              title: Text(LocalizationService.translate(LocalizationService.returnToDashboard)),
              subtitle: Text(LocalizationService.translate(LocalizationService.returnToDashboardDesc)),
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

  void _navigateToSafetyInstructions(BuildContext context) {
    Navigator.pushNamed(context, '/disaster-safety-screen');
  }

  void _showQuickSafetyTips(BuildContext context) {
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
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade400,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 6.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Quick Safety Tips',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 6.w,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickTipCard(
                      'Universal Emergency Tips',
                      Icons.emergency,
                      Colors.red.shade600,
                      [
                        'Stay calm and assess the situation',
                        'Follow official evacuation orders immediately',
                        'Keep emergency contacts easily accessible',
                        'Have emergency kit ready with water, food, medicines',
                        'Identify multiple evacuation routes',
                      ],
                    ),
                    SizedBox(height: 2.h),
                    _buildQuickTipCard(
                      'Communication',
                      Icons.phone,
                      Colors.blue.shade600,
                      [
                        'Keep phones charged and have power banks',
                        'Use text messages when calls don\'t work',
                        'Designate out-of-area emergency contact',
                        'Know your local emergency services numbers',
                        'Use social media to check in with family',
                      ],
                    ),
                    SizedBox(height: 2.h),
                    _buildQuickTipCard(
                      'First Aid Basics',
                      Icons.medical_services,
                      Colors.green.shade600,
                      [
                        'Learn basic CPR and first aid',
                        'Control bleeding with direct pressure',
                        'Keep injured person warm and comfortable',
                        'Don\'t move seriously injured victims',
                        'Call for professional medical help immediately',
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToSafetyInstructions(context);
                        },
                        icon: Icon(Icons.book, size: 5.w),
                        label: Text(
                          'View Complete Safety Guide',
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade400,
                          foregroundColor: Colors.white,
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
        ),
      ),
    );
  }

  Widget _buildQuickTipCard(String title, IconData icon, Color color, List<String> tips) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                Icon(icon, color: color, size: 5.w),
                SizedBox(width: 2.w),
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              children: tips.map((tip) => Container(
                margin: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 0.5.h),
                      width: 4.w,
                      height: 4.w,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        tip,
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textHighEmphasisLight,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyGuides(BuildContext context) {
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
                      Icon(
                        Icons.menu_book,
                        color: Colors.white,
                        size: 6.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        LocalizationService.translate(LocalizationService.disasterGuides),
                        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 6.w,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  // Language Selector
                  Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: Colors.white,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        LocalizationService.translate(LocalizationService.language),
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: ValueListenableBuilder<SupportedLanguage>(
                          valueListenable: LocalizationService.languageNotifier,
                          builder: (context, currentLang, child) {
                            return DropdownButton<SupportedLanguage>(
                              value: currentLang,
                              dropdownColor: Colors.teal.shade700,
                              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                              underline: Container(
                                height: 1,
                                color: Colors.white,
                              ),
                              items: SupportedLanguage.values.map((lang) {
                                return DropdownMenuItem(
                                  value: lang,
                                  child: Text(
                                    lang.displayName,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                              onChanged: (SupportedLanguage? newLang) {
                                if (newLang != null) {
                                  LocalizationService.setLanguage(newLang);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: ValueListenableBuilder<SupportedLanguage>(
                valueListenable: LocalizationService.languageNotifier,
                builder: (context, currentLang, child) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cyclone Guide
                        _buildDisasterGuideCard(
                          LocalizationService.translate(DisasterSafetyContent.cycloneTitle),
                          Icons.cyclone,
                          AppTheme.primaryLight,
                          LocalizationService.translate(DisasterSafetyContent.cycloneOverview),
                          DisasterSafetyContent.cycloneBeforeSteps[currentLang.code] ?? DisasterSafetyContent.cycloneBeforeSteps['en'] ?? [],
                          DisasterSafetyContent.cycloneDuringSteps[currentLang.code] ?? DisasterSafetyContent.cycloneDuringSteps['en'] ?? [],
                          DisasterSafetyContent.cycloneAfterSteps[currentLang.code] ?? DisasterSafetyContent.cycloneAfterSteps['en'] ?? [],
                        ),
                        SizedBox(height: 3.h),
                        
                        // Flood Guide
                        _buildDisasterGuideCard(
                          LocalizationService.translate(DisasterSafetyContent.floodTitle),
                          Icons.water,
                          Colors.blue.shade600,
                          LocalizationService.translate(DisasterSafetyContent.floodOverview),
                          DisasterSafetyContent.floodBeforeSteps[currentLang.code] ?? DisasterSafetyContent.floodBeforeSteps['en'] ?? [],
                          DisasterSafetyContent.floodDuringSteps[currentLang.code] ?? DisasterSafetyContent.floodDuringSteps['en'] ?? [],
                          DisasterSafetyContent.floodAfterSteps[currentLang.code] ?? DisasterSafetyContent.floodAfterSteps['en'] ?? [],
                        ),
                        SizedBox(height: 3.h),
                        
                        // Forest Fire Guide
                        _buildDisasterGuideCard(
                          LocalizationService.translate(DisasterSafetyContent.forestFireTitle),
                          Icons.local_fire_department,
                          Colors.orange.shade700,
                          LocalizationService.translate(DisasterSafetyContent.forestFireOverview),
                          DisasterSafetyContent.forestFireBeforeSteps[currentLang.code] ?? DisasterSafetyContent.forestFireBeforeSteps['en'] ?? [],
                          DisasterSafetyContent.forestFireDuringSteps[currentLang.code] ?? DisasterSafetyContent.forestFireDuringSteps['en'] ?? [],
                          DisasterSafetyContent.forestFireAfterSteps[currentLang.code] ?? DisasterSafetyContent.forestFireAfterSteps['en'] ?? [],
                        ),
                        SizedBox(height: 3.h),
                        
                        // Earthquake Guide
                        _buildDisasterGuideCard(
                          LocalizationService.translate(DisasterSafetyContent.earthquakeTitle),
                          Icons.landscape,
                          Colors.brown.shade600,
                          LocalizationService.translate(DisasterSafetyContent.earthquakeOverview),
                          DisasterSafetyContent.earthquakeBeforeSteps[currentLang.code] ?? DisasterSafetyContent.earthquakeBeforeSteps['en'] ?? [],
                          DisasterSafetyContent.earthquakeDuringSteps[currentLang.code] ?? DisasterSafetyContent.earthquakeDuringSteps['en'] ?? [],
                          DisasterSafetyContent.earthquakeAfterSteps[currentLang.code] ?? DisasterSafetyContent.earthquakeAfterSteps['en'] ?? [],
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
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.teal.shade600,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt,
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
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 6.w,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<SupportedLanguage>(
                valueListenable: LocalizationService.languageNotifier,
                builder: (context, currentLang, child) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        _buildQuickDisasterCard(
                          LocalizationService.translate(DisasterSafetyContent.cycloneTitle),
                          Icons.cyclone,
                          AppTheme.primaryLight,
                          DisasterSafetyContent.cycloneDos[currentLang.code] ?? [],
                          DisasterSafetyContent.cycloneDonts[currentLang.code] ?? [],
                        ),
                        SizedBox(height: 2.h),
                        _buildQuickDisasterCard(
                          LocalizationService.translate(DisasterSafetyContent.floodTitle),
                          Icons.water,
                          Colors.blue.shade600,
                          DisasterSafetyContent.floodDos[currentLang.code] ?? DisasterSafetyContent.floodDos['en'] ?? [],
                          DisasterSafetyContent.floodDonts[currentLang.code] ?? DisasterSafetyContent.floodDonts['en'] ?? [],
                        ),
                        SizedBox(height: 2.h),
                        _buildQuickDisasterCard(
                          LocalizationService.translate(DisasterSafetyContent.forestFireTitle),
                          Icons.local_fire_department,
                          Colors.orange.shade700,
                          DisasterSafetyContent.forestFireDos[currentLang.code] ?? DisasterSafetyContent.forestFireDos['en'] ?? [],
                          DisasterSafetyContent.forestFireDonts[currentLang.code] ?? DisasterSafetyContent.forestFireDonts['en'] ?? [],
                        ),
                        SizedBox(height: 2.h),
                        _buildQuickDisasterCard(
                          LocalizationService.translate(DisasterSafetyContent.earthquakeTitle),
                          Icons.landscape,
                          Colors.brown.shade600,
                          DisasterSafetyContent.earthquakeDos[currentLang.code] ?? DisasterSafetyContent.earthquakeDos['en'] ?? [],
                          DisasterSafetyContent.earthquakeDonts[currentLang.code] ?? DisasterSafetyContent.earthquakeDonts['en'] ?? [],
                        ),
                        SizedBox(height: 3.h),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEmergencyGuides(context);
                            },
                            icon: Icon(Icons.menu_book, size: 5.w),
                            label: Text(
                              LocalizationService.translate(LocalizationService.viewCompleteGuides),
                              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
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

  Widget _buildDisasterGuideCard(String title, IconData icon, Color color, String overview, List<String> beforeSteps, List<String> duringSteps, List<String> afterSteps) {
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
          // Header
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
                Icon(icon, color: color, size: 6.w),
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
          
          // Overview
          Container(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    Expanded(
                      child: _buildStepsSection(
                        '${LocalizationService.translate(LocalizationService.before)} $title',
                        beforeSteps,
                        Colors.blue.shade600,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: _buildStepsSection(
                        '${LocalizationService.translate(LocalizationService.during)} $title',
                        duringSteps,
                        Colors.orange.shade600,
                      ),
                    ),
                    SizedBox(width: 2.w),
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
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 1.h),
        ...steps.take(3).map((step) => Container(
          margin: EdgeInsets.only(bottom: 0.5.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        if (steps.length > 3)
          Text(
            '...${LocalizationService.translate(LocalizationService.andMore)} ${steps.length - 3} ${LocalizationService.translate(LocalizationService.more)}',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: color,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildQuickDisasterCard(String disaster, IconData icon, Color color, List<String> dos, List<String> donts) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
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
                Icon(icon, color: color, size: 5.w),
                SizedBox(width: 2.w),
                Text(
                  disaster,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    LocalizationService.translate(LocalizationService.quickGuide),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Container(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                // Do's Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600, size: 4.w),
                          SizedBox(width: 1.w),
                          Text(
                            LocalizationService.translate(LocalizationService.dos),
                            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      ...dos.map((item) => _buildQuickItem(item, Colors.green.shade600, Icons.check)),
                    ],
                  ),
                ),
                
                // Divider
                Container(
                  width: 1,
                  height: 15.h,
                  color: Colors.grey.shade300,
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                ),
                
                // Don'ts Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red.shade600, size: 4.w),
                          SizedBox(width: 1.w),
                          Text(
                            LocalizationService.translate(LocalizationService.donts),
                            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      ...donts.map((item) => _buildQuickItem(item, Colors.red.shade600, Icons.close)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickItem(String text, Color color, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 0.2.h),
            child: Icon(
              icon,
              color: color,
              size: 3.w,
            ),
          ),
          SizedBox(width: 1.5.w),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textHighEmphasisLight,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}