import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CommunicationToolsWidget extends StatefulWidget {
  const CommunicationToolsWidget({Key? key}) : super(key: key);

  @override
  State<CommunicationToolsWidget> createState() =>
      _CommunicationToolsWidgetState();
}

class _CommunicationToolsWidgetState extends State<CommunicationToolsWidget> {
  bool isBluetoothEnabled = false;
  bool isWifiDirectEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
              CustomIconWidget(
                iconName: 'wifi',
                color: AppTheme.lightTheme.primaryColor,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Offline Communication',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          _buildCommunicationOption(
            'Bluetooth Messaging',
            'Connect with nearby devices',
            'bluetooth',
            isBluetoothEnabled,
            (value) => setState(() => isBluetoothEnabled = value),
          ),
          SizedBox(height: 2.h),
          _buildCommunicationOption(
            'Wi-Fi Direct',
            'Direct device-to-device communication',
            'wifi_tethering',
            isWifiDirectEnabled,
            (value) => setState(() => isWifiDirectEnabled = value),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showEmergencyPhrasebook(context);
              },
              icon: CustomIconWidget(
                iconName: 'translate',
                color: Colors.white,
                size: 5.w,
              ),
              label: Text(
                'Emergency Phrasebook',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryLight,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationOption(
    String title,
    String subtitle,
    String iconName,
    bool isEnabled,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: isEnabled
              ? AppTheme.successLight
              : AppTheme.textMediumEmphasisLight,
          size: 5.w,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Switch(
          value: isEnabled,
          onChanged: onChanged,
          activeColor: AppTheme.successLight,
        ),
      ],
    );
  }

  void _showEmergencyPhrasebook(BuildContext context) {
    final List<Map<String, dynamic>> phrases = [
      {
        "english": "Help me, please!",
        "spanish": "¡Ayúdame, por favor!",
        "french": "Aidez-moi, s'il vous plaît!",
        "category": "Emergency"
      },
      {
        "english": "I need medical assistance",
        "spanish": "Necesito asistencia médica",
        "french": "J'ai besoin d'aide médicale",
        "category": "Medical"
      },
      {
        "english": "Where is the nearest shelter?",
        "spanish": "¿Dónde está el refugio más cercano?",
        "french": "Où est l'abri le plus proche?",
        "category": "Shelter"
      },
      {
        "english": "I am lost",
        "spanish": "Estoy perdido",
        "french": "Je suis perdu",
        "category": "Navigation"
      },
      {
        "english": "Call emergency services",
        "spanish": "Llama a los servicios de emergencia",
        "french": "Appelez les services d'urgence",
        "category": "Emergency"
      },
    ];

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
              child: Text(
                'Emergency Phrasebook',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: phrases.length,
                itemBuilder: (context, index) {
                  final phrase = phrases[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 2.h),
                    child: ExpansionTile(
                      title: Text(
                        phrase["english"] as String,
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        phrase["category"] as String,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.primaryColor,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTranslation(
                                  'Spanish', phrase["spanish"] as String),
                              SizedBox(height: 1.h),
                              _buildTranslation(
                                  'French', phrase["french"] as String),
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

  Widget _buildTranslation(String language, String translation) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$language: ',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.primaryColor,
          ),
        ),
        Expanded(
          child: Text(
            translation,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
