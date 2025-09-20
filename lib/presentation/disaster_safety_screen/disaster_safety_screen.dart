import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/disaster_safety_content.dart';
import 'widgets/disaster_overview_card.dart';
import 'widgets/instruction_section.dart';
import 'widgets/language_selector.dart';

class DisasterSafetyScreen extends StatefulWidget {
  const DisasterSafetyScreen({super.key});

  @override
  State<DisasterSafetyScreen> createState() => _DisasterSafetyScreenState();
}

class _DisasterSafetyScreenState extends State<DisasterSafetyScreen> {
  String selectedLanguage = 'en';
  String selectedDisaster = 'Cyclone';
  
  final Map<String, String> languages = {
    'en': 'English',
    'hi': 'हिंदी',
    'mr': 'मराठी',
  };

  final Map<String, String> disasters = {
    'Cyclone': 'cyclone',
    'Flood': 'water_drop',
    'Forest Fire': 'local_fire_department',
    'Earthquake': 'landscape',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Disaster Safety Guide',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppTheme.lightTheme.primaryColor,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: Colors.white,
            size: 6.w,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Language Selector
          Container(
            margin: EdgeInsets.only(right: 4.w),
            child: LanguageSelector(
              selectedLanguage: selectedLanguage,
              languages: languages,
              onLanguageChanged: (String value) {
                setState(() {
                  selectedLanguage = value;
                });
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Disaster Type Selector
          Container(
            height: 12.h,
            margin: EdgeInsets.all(4.w),
            child: DisasterTypeSelector(
              selectedDisaster: selectedDisaster,
              disasters: disasters,
              onDisasterChanged: (String value) {
                setState(() {
                  selectedDisaster = value;
                });
              },
            ),
          ),

          // Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Section
                  DisasterOverviewCard(
                    title: _getDisasterTitle(),
                    iconName: disasters[selectedDisaster]!,
                    overview: _getOverviewText(),
                    accentColor: AppTheme.lightTheme.primaryColor,
                  ),
                  SizedBox(height: 3.h),
                  
                  // Before Disaster Section
                  InstructionSection(
                    title: 'Before $selectedDisaster',
                    iconName: 'preparation',
                    color: AppTheme.successLight,
                    steps: _getBeforeSteps(),
                  ),
                  SizedBox(height: 2.h),
                  
                  // During Disaster Section
                  InstructionSection(
                    title: 'During $selectedDisaster',
                    iconName: 'warning',
                    color: Colors.orange,
                    steps: _getDuringSteps(),
                  ),
                  SizedBox(height: 2.h),
                  
                  // After Disaster Section
                  InstructionSection(
                    title: 'After $selectedDisaster',
                    iconName: 'health_and_safety',
                    color: AppTheme.primaryLight,
                    steps: _getAfterSteps(),
                  ),
                  SizedBox(height: 2.h),
                  
                  // Quick Tips Section
                  QuickReferenceCard(
                    dos: _getDos(),
                    donts: _getDonts(),
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods to get content based on selected disaster and language
  String _getDisasterTitle() {
    switch (selectedDisaster) {
      case 'Cyclone':
        return DisasterSafetyContent.cycloneTitle[selectedLanguage] ?? 'Cyclone';
      case 'Flood':
        return DisasterSafetyContent.floodTitle[selectedLanguage] ?? 'Flood';
      case 'Forest Fire':
        return DisasterSafetyContent.forestFireTitle[selectedLanguage] ?? 'Forest Fire';
      case 'Earthquake':
        return DisasterSafetyContent.earthquakeTitle[selectedLanguage] ?? 'Earthquake';
      default:
        return selectedDisaster;
    }
  }

  String _getOverviewText() {
    switch (selectedDisaster) {
      case 'Cyclone':
        return DisasterSafetyContent.cycloneOverview[selectedLanguage] ?? '';
      case 'Flood':
        return DisasterSafetyContent.floodOverview[selectedLanguage] ?? '';
      case 'Forest Fire':
        return DisasterSafetyContent.forestFireOverview[selectedLanguage] ?? '';
      case 'Earthquake':
        return DisasterSafetyContent.earthquakeOverview[selectedLanguage] ?? '';
      default:
        return '';
    }
  }

  List<String> _getBeforeSteps() {
    switch (selectedDisaster) {
      case 'Cyclone':
        return DisasterSafetyContent.cycloneBeforeSteps[selectedLanguage] ?? [];
      case 'Flood':
        return DisasterSafetyContent.floodBeforeSteps[selectedLanguage] ?? [];
      case 'Forest Fire':
        return DisasterSafetyContent.forestFireBeforeSteps[selectedLanguage] ?? [];
      case 'Earthquake':
        return DisasterSafetyContent.earthquakeBeforeSteps[selectedLanguage] ?? [];
      default:
        return [];
    }
  }

  List<String> _getDuringSteps() {
    switch (selectedDisaster) {
      case 'Cyclone':
        return DisasterSafetyContent.cycloneDuringSteps[selectedLanguage] ?? [];
      case 'Flood':
        return DisasterSafetyContent.floodDuringSteps[selectedLanguage] ?? [];
      case 'Forest Fire':
        return DisasterSafetyContent.forestFireDuringSteps[selectedLanguage] ?? [];
      case 'Earthquake':
        return DisasterSafetyContent.earthquakeDuringSteps[selectedLanguage] ?? [];
      default:
        return [];
    }
  }

  List<String> _getAfterSteps() {
    switch (selectedDisaster) {
      case 'Cyclone':
        return DisasterSafetyContent.cycloneAfterSteps[selectedLanguage] ?? [];
      case 'Flood':
        return DisasterSafetyContent.floodAfterSteps[selectedLanguage] ?? [];
      case 'Forest Fire':
        return DisasterSafetyContent.forestFireAfterSteps[selectedLanguage] ?? [];
      case 'Earthquake':
        return DisasterSafetyContent.earthquakeAfterSteps[selectedLanguage] ?? [];
      default:
        return [];
    }
  }

  List<String> _getDos() {
    switch (selectedDisaster) {
      case 'Cyclone':
        return DisasterSafetyContent.cycloneDos[selectedLanguage] ?? [];
      case 'Flood':
        return DisasterSafetyContent.floodDos[selectedLanguage] ?? [];
      case 'Forest Fire':
        return DisasterSafetyContent.forestFireDos[selectedLanguage] ?? [];
      case 'Earthquake':
        return DisasterSafetyContent.earthquakeDos[selectedLanguage] ?? [];
      default:
        return [];
    }
  }

  List<String> _getDonts() {
    switch (selectedDisaster) {
      case 'Cyclone':
        return DisasterSafetyContent.cycloneDonts[selectedLanguage] ?? [];
      case 'Flood':
        return DisasterSafetyContent.floodDonts[selectedLanguage] ?? [];
      case 'Forest Fire':
        return DisasterSafetyContent.forestFireDonts[selectedLanguage] ?? [];
      case 'Earthquake':
        return DisasterSafetyContent.earthquakeDonts[selectedLanguage] ?? [];
      default:
        return [];
    }
  }
}