import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SeveritySliderWidget extends StatelessWidget {
  final double severity;
  final Function(double) onChanged;

  const SeveritySliderWidget({
    Key? key,
    required this.severity,
    required this.onChanged,
  }) : super(key: key);

  Color _getSeverityColor(double value) {
    if (value <= 3) {
      return AppTheme.lightTheme.colorScheme.tertiary; // Green for low
    } else if (value <= 7) {
      return AppTheme.lightTheme.colorScheme.secondary; // Amber for medium
    } else {
      return AppTheme.lightTheme.colorScheme.primary; // Red for high
    }
  }

  String _getSeverityLabel(double value) {
    if (value <= 3) {
      return "Low";
    } else if (value <= 7) {
      return "Medium";
    } else {
      return "High";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'warning',
                color: _getSeverityColor(severity),
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                "Severity Level *",
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getSeverityLabel(severity),
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: _getSeverityColor(severity),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getSeverityColor(severity),
              thumbColor: _getSeverityColor(severity),
              overlayColor: _getSeverityColor(severity).withValues(alpha: 0.2),
              inactiveTrackColor: AppTheme.lightTheme.colorScheme.outline,
              trackHeight: 4,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: severity,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "1 - Low",
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                ),
              ),
              Text(
                "5 - Medium",
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.secondary,
                ),
              ),
              Text(
                "10 - High",
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
