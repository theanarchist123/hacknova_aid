import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DisasterAlertMarkerSheet extends StatelessWidget {
  final Map<String, dynamic> alertData;

  const DisasterAlertMarkerSheet({
    super.key,
    required this.alertData,
  });

  @override
  Widget build(BuildContext context) {
    final String severity = (alertData['severity'] as String?) ?? 'medium';
    final Color severityColor = _getSeverityColor(severity);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40.w,
            height: 0.5.h,
            margin: EdgeInsets.symmetric(vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Alert header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: _getAlertIcon(
                            alertData['type'] as String? ?? 'general'),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (alertData['title'] as String?) ??
                                'Emergency Alert',
                            style: AppTheme.lightTheme.textTheme.titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: severityColor,
                            ),
                          ),
                          Text(
                            _getSeverityText(severity),
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: severityColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Alert details
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (alertData['description'] != null) ...[
                  Text(
                    'Description',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    alertData['description'] as String,
                    style: AppTheme.lightTheme.textTheme.bodyLarge,
                  ),
                  SizedBox(height: 2.h),
                ],

                // Location and radius
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Location',
                        (alertData['location'] as String?) ?? 'Unknown',
                        'location_on',
                        AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: _buildInfoCard(
                        'Affected Radius',
                        '${alertData['radius'] ?? 5} km',
                        'radio_button_unchecked',
                        const Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Time information
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Reported',
                        _formatTime(alertData['timestamp']),
                        'access_time',
                        const Color(0xFF757575),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: _buildInfoCard(
                        'Status',
                        (alertData['status'] as String?) ?? 'Active',
                        'info',
                        severityColor,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 3.h),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to emergency response
                          Navigator.pushNamed(
                              context, '/emergency-response-screen');
                        },
                        icon: CustomIconWidget(
                          iconName: 'emergency',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 20,
                        ),
                        label: const Text('Emergency Guide'),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to incident reporting
                          Navigator.pushNamed(
                              context, '/incident-reporting-screen');
                        },
                        icon: CustomIconWidget(
                          iconName: 'report',
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text('Report Update'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, String iconName, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: iconName,
                color: color,
                size: 16,
              ),
              SizedBox(width: 2.w),
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return const Color(0xFFD32F2F);
      case 'medium':
      case 'warning':
        return const Color(0xFFFFA000);
      case 'low':
      case 'info':
        return const Color(0xFF388E3C);
      default:
        return const Color(0xFFFFA000);
    }
  }

  String _getSeverityText(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return 'CRITICAL ALERT';
      case 'medium':
      case 'warning':
        return 'WARNING';
      case 'low':
      case 'info':
        return 'INFORMATION';
      default:
        return 'WARNING';
    }
  }

  String _getAlertIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flood':
        return 'water';
      case 'cyclone':
      case 'hurricane':
        return 'cyclone';
      case 'earthquake':
        return 'landscape';
      case 'fire':
        return 'local_fire_department';
      case 'outbreak':
        return 'coronavirus';
      default:
        return 'warning';
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      DateTime dateTime;
      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Unknown';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
