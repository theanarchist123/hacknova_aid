import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmergencyContactsWidget extends StatelessWidget {
  const EmergencyContactsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> emergencyContacts = [
      {
        "name": "Emergency Services",
        "number": "911",
        "type": "Emergency",
        "icon": "local_hospital",
        "color": AppTheme.primaryLight,
      },
      {
        "name": "Fire Department",
        "number": "911",
        "type": "Fire",
        "icon": "local_fire_department",
        "color": AppTheme.primaryLight,
      },
      {
        "name": "Police",
        "number": "911",
        "type": "Police",
        "icon": "local_police",
        "color": AppTheme.primaryLight,
      },
      {
        "name": "Poison Control",
        "number": "1-800-222-1222",
        "type": "Medical",
        "icon": "medical_services",
        "color": AppTheme.secondaryLight,
      },
      {
        "name": "Red Cross",
        "number": "1-800-733-2767",
        "type": "Relief",
        "icon": "volunteer_activism",
        "color": AppTheme.successLight,
      },
      {
        "name": "Emergency Contact 1",
        "number": "+1-555-0123",
        "type": "Personal",
        "icon": "person",
        "color": AppTheme.successLight,
      },
    ];

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
                iconName: 'phone',
                color: AppTheme.lightTheme.primaryColor,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Emergency Contacts',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: emergencyContacts.length,
            separatorBuilder: (context, index) => SizedBox(height: 2.h),
            itemBuilder: (context, index) {
              final contact = emergencyContacts[index];
              return _buildContactCard(
                context,
                contact["name"] as String,
                contact["number"] as String,
                contact["type"] as String,
                contact["icon"] as String,
                contact["color"] as Color,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    String name,
    String number,
    String type,
    String iconName,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _makeCall(number),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: CustomIconWidget(
                iconName: iconName,
                color: Colors.white,
                size: 5.w,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    number,
                    style: AppTheme.dataTextTheme(isLight: true)
                        .bodyMedium
                        ?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    type,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMediumEmphasisLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustomIconWidget(
                iconName: 'call',
                color: Colors.white,
                size: 4.w,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _makeCall(String number) {
    Fluttertoast.showToast(
      msg: "Calling $number...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.successLight,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
