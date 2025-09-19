import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import './widgets/disaster_guide_widget.dart';
import './widgets/quick_instructions_widget.dart';

class DisasterSafetyScreen extends StatelessWidget {
  const DisasterSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Disaster Safety Instructions',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppTheme.lightTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  margin: EdgeInsets.only(bottom: 3.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryLight.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.security,
                        color: AppTheme.primaryLight,
                        size: 8.w,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Stay Safe During Disasters',
                        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Essential safety guidelines for natural disasters. Follow these instructions to protect yourself and your loved ones.',
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMediumEmphasisLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Quick Instructions Section
                _buildSectionHeader('Quick Instructions', Icons.flash_on),
                SizedBox(height: 2.h),
                const QuickInstructionsWidget(),
                SizedBox(height: 4.h),

                // Detailed Disaster Guides Section
                _buildSectionHeader('Disaster Guides', Icons.menu_book),
                SizedBox(height: 2.h),
                
                // Cyclone Guide
                DisasterGuideWidget(
                  disasterType: 'Cyclone',
                  iconData: Icons.cyclone,
                  color: AppTheme.primaryLight,
                  overview: 'A cyclone is a large-scale air mass that rotates around a strong center of low atmospheric pressure. Cyclones bring strong winds, heavy rain, and storm surges that can cause severe flooding and property damage.',
                  beforeSteps: [
                    'Monitor weather forecasts and official warnings regularly',
                    'Prepare an emergency kit with water, food, medicines, and important documents',
                    'Secure outdoor furniture, signboards, and loose objects',
                    'Check and clean drains and gutters around your property',
                    'Plan evacuation routes and identify safe shelter locations',
                    'Keep battery-powered radio and flashlights ready',
                    'Fill bathtubs and containers with clean water for storage',
                  ],
                  duringSteps: [
                    'Stay indoors and keep away from windows and glass doors',
                    'Listen to battery-powered radio for updates and instructions',
                    'Avoid using electrical appliances during the storm',
                    'Stay in the strongest part of your building',
                    'If evacuating, follow official evacuation routes only',
                    'Never drive through flooded roads or walkways',
                    'Keep emergency numbers and contacts easily accessible',
                  ],
                  afterSteps: [
                    'Wait for official all-clear before leaving shelter',
                    'Check for injuries and provide first aid if needed',
                    'Inspect your home for structural damage before entering',
                    'Avoid downed power lines and report them immediately',
                    'Document property damage with photos for insurance',
                    'Help neighbors and community members if safe to do so',
                    'Boil water before drinking if water supply is contaminated',
                  ],
                ),

                SizedBox(height: 3.h),

                // Floods Guide
                DisasterGuideWidget(
                  disasterType: 'Floods',
                  iconData: Icons.water,
                  color: Colors.blue.shade600,
                  overview: 'Flooding occurs when water overflows onto normally dry land. This can happen due to heavy rainfall, river overflow, coastal storms, or dam failures. Floods can develop slowly or occur suddenly without warning.',
                  beforeSteps: [
                    'Know your area\'s flood risk and evacuation routes',
                    'Keep sandbags and flood barriers ready if available',
                    'Move valuable items to higher floors or elevated areas',
                    'Install sump pumps and backup power sources',
                    'Review and update flood insurance policies',
                    'Create a family emergency communication plan',
                    'Identify higher ground locations for emergency evacuation',
                  ],
                  duringSteps: [
                    'Move immediately to higher ground if flooding begins',
                    'Never walk, swim, or drive through flood waters',
                    'Stay away from storm drains and manholes',
                    'If trapped in a building, go to the highest floor',
                    'Signal for help from upper floors or rooftops',
                    'Avoid electrical equipment if standing in water',
                    'Listen to emergency broadcasts for evacuation orders',
                  ],
                  afterSteps: [
                    'Return home only when authorities say it\'s safe',
                    'Be extremely cautious of structural damage',
                    'Pump out flooded basements gradually to avoid structural collapse',
                    'Clean and disinfect everything that got wet',
                    'Check electrical systems before turning power back on',
                    'Take photos of damage for insurance claims',
                    'Watch for contaminated water and practice good hygiene',
                  ],
                ),

                SizedBox(height: 3.h),

                // Forest Fire Guide
                DisasterGuideWidget(
                  disasterType: 'Forest Fire',
                  iconData: Icons.local_fire_department,
                  color: Colors.orange.shade700,
                  overview: 'Forest fires are uncontrolled fires that spread rapidly through vegetation and wooded areas. They can be caused by lightning, human activities, or extremely dry conditions. Fires can move very quickly and change direction unexpectedly.',
                  beforeSteps: [
                    'Create defensible space around your property by clearing vegetation',
                    'Use fire-resistant materials for roofing and exterior walls',
                    'Install fire-resistant landscaping with well-watered plants',
                    'Keep water sources accessible and maintain firefighting tools',
                    'Plan multiple evacuation routes from your area',
                    'Sign up for local emergency alert systems',
                    'Prepare go-bags with essentials for quick evacuation',
                  ],
                  duringSteps: [
                    'Evacuate immediately when ordered by authorities',
                    'If trapped, call emergency services and give your location',
                    'Close all windows, vents, and doors to prevent embers',
                    'Turn on all lights to help firefighters see your home',
                    'Stay in the center of your home away from outside walls',
                    'Cover yourself with woolen blankets if caught outside',
                    'Never try to outrun a fire - seek shelter immediately',
                  ],
                  afterSteps: [
                    'Return only when authorities declare the area safe',
                    'Watch for hot spots that may re-ignite',
                    'Check for structural damage before entering buildings',
                    'Be aware of hazards like weakened trees and power lines',
                    'Document all fire damage with photographs',
                    'Contact your insurance company as soon as possible',
                    'Practice fire safety to prevent future incidents',
                  ],
                ),

                SizedBox(height: 3.h),

                // Earthquake Guide
                DisasterGuideWidget(
                  disasterType: 'Earthquake',
                  iconData: Icons.landscape,
                  color: Colors.brown.shade600,
                  overview: 'An earthquake is the sudden shaking of the ground caused by the movement of tectonic plates beneath the Earth\'s surface. Earthquakes can occur without warning and cause buildings to collapse, trigger landslides, and disrupt essential services.',
                  beforeSteps: [
                    'Secure heavy furniture and appliances to walls',
                    'Identify safe spots in each room (under sturdy tables, against interior walls)',
                    'Practice "Drop, Cover, and Hold On" with your family',
                    'Keep emergency supplies in easily accessible locations',
                    'Know how to turn off gas, water, and electricity',
                    'Make sure your home meets current building codes',
                    'Develop a family reunification plan with out-of-area contacts',
                  ],
                  duringSteps: [
                    'Drop to hands and knees immediately',
                    'Take cover under a sturdy desk or table if available',
                    'Hold on to your shelter and protect your head and neck',
                    'Stay where you are - do not run outside during shaking',
                    'If outdoors, move away from buildings, trees, and power lines',
                    'If driving, pull over safely and stay in the vehicle',
                    'If in bed, stay there and cover your head with a pillow',
                  ],
                  afterSteps: [
                    'Check yourself and others for injuries',
                    'Inspect your home for damage before entering',
                    'Turn off gas if you smell gas or hear hissing sounds',
                    'Check water and electrical lines for damage',
                    'Be prepared for aftershocks - they can be strong',
                    'Use stairs instead of elevators',
                    'Stay away from damaged buildings and areas',
                  ],
                ),

                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryLight,
          size: 6.w,
        ),
        SizedBox(width: 2.w),
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryLight,
          ),
        ),
      ],
    );
  }
}