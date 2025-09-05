import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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
  String currentLocation = "Downtown District, Emergency Zone Alpha";
  bool isSOSActive = false;

  final List<Map<String, dynamic>> shelterData = [
    {
      "name": "Central Community Shelter",
      "address": "123 Main Street, Downtown",
      "capacity": 500,
      "occupied": 342,
      "distance": "0.8 miles",
      "amenities": ["Medical", "Food", "Wi-Fi"],
      "status": "Available"
    },
    {
      "name": "Riverside Emergency Center",
      "address": "456 River Road, Riverside",
      "capacity": 300,
      "occupied": 298,
      "distance": "1.2 miles",
      "amenities": ["Medical", "Food"],
      "status": "Nearly Full"
    },
    {
      "name": "North Side Relief Station",
      "address": "789 North Avenue, North Side",
      "capacity": 400,
      "occupied": 156,
      "distance": "2.1 miles",
      "amenities": ["Food", "Supplies", "Pet Care"],
      "status": "Available"
    },
  ];

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

              // Emergency Contacts Widget
              const EmergencyContactsWidget(),

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
                  Text(
                    'Emergency Shelters',
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
                itemCount: shelterData.length,
                itemBuilder: (context, index) {
                  final shelter = shelterData[index];
                  final occupancyRate = (shelter["occupied"] as int) /
                      (shelter["capacity"] as int);

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
                              ),
                            ),
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
                                shelter["status"] as String,
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
                              shelter["distance"] as String,
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

  void _navigateToShelter(String shelterName) {
    Navigator.pop(context);
    Fluttertoast.showToast(
      msg: "Opening navigation to $shelterName",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.successLight,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _callShelter(String shelterName) {
    Fluttertoast.showToast(
      msg: "Calling $shelterName...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.primaryLight,
      textColor: Colors.white,
      fontSize: 16.0,
    );
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