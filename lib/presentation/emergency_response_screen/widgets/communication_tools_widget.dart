import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CommunicationToolsWidget extends StatefulWidget {
  const CommunicationToolsWidget({super.key});

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
          activeThumbColor: AppTheme.successLight,
        ),
      ],
    );
  }

  void _showEmergencyPhrasebook(BuildContext context) {
    print('🔥 DEBUG: Emergency phrasebook button clicked - navigating to disaster preparedness');
    Navigator.pushNamed(context, '/disaster-preparedness');
  }
}
