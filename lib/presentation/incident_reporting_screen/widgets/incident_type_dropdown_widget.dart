import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class IncidentTypeDropdownWidget extends StatelessWidget {
  final String? selectedType;
  final Function(String?) onChanged;

  const IncidentTypeDropdownWidget({
    Key? key,
    required this.selectedType,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> incidentTypes = [
      {"value": "flood", "label": "Flood", "icon": "water_drop"},
      {"value": "fire", "label": "Fire", "icon": "local_fire_department"},
      {
        "value": "medical",
        "label": "Medical Emergency",
        "icon": "medical_services"
      },
      {"value": "security", "label": "Security Threat", "icon": "security"},
      {"value": "earthquake", "label": "Earthquake", "icon": "landscape"},
      {"value": "accident", "label": "Accident", "icon": "car_crash"},
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedType,
        decoration: InputDecoration(
          labelText: "Incident Type *",
          labelStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          prefixIcon: Padding(
            padding: EdgeInsets.all(3.w),
            child: CustomIconWidget(
              iconName: 'category',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 20,
            ),
          ),
        ),
        items: incidentTypes.map((type) {
          return DropdownMenuItem<String>(
            value: type["value"] as String,
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: type["icon"] as String,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 18,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    type["label"] as String,
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: AppTheme.lightTheme.colorScheme.surface,
        icon: CustomIconWidget(
          iconName: 'keyboard_arrow_down',
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
        isExpanded: true,
      ),
    );
  }
}
