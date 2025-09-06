import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RecentAlertsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> alerts;

  const RecentAlertsWidget({
    Key? key,
    required this.alerts,
  }) : super(key: key);

  @override
  State<RecentAlertsWidget> createState() => _RecentAlertsWidgetState();
}

class _RecentAlertsWidgetState extends State<RecentAlertsWidget> {
  bool _isExpanded = false;

  IconData _getDisasterIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flood':
        return Icons.water;
      case 'cyclone':
        return Icons.cyclone;
      case 'outbreak':
        return Icons.coronavirus;
      case 'earthquake':
        return Icons.landscape;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.warning;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppTheme.lightTheme.colorScheme.error;
      case 'high':
        return Colors.orange;
      case 'medium':
        return AppTheme.lightTheme.colorScheme.secondary;
      case 'low':
        return Colors.blue;
      default:
        return AppTheme.lightTheme.colorScheme.secondary;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.alerts.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 15.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Recent Alerts',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.tertiary,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Your area is currently safe',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
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
          // Dropdown Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'notifications',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Recent Alerts (${widget.alerts.length})',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.alerts.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(widget.alerts.first['severity'] ?? 'medium'),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.alerts.first['severity']?.toUpperCase() ?? 'ALERT',
                        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  SizedBox(width: 2.w),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 6.w,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable Content
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.all(4.w),
                      itemCount: widget.alerts.length > 3 ? 3 : widget.alerts.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 3.h,
                        color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                      itemBuilder: (context, index) {
                        final alert = widget.alerts[index];
                        
                        return Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(alert['severity'] ?? 'medium').withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getDisasterIcon(alert['type'] ?? 'warning'),
                                    color: _getSeverityColor(alert['severity'] ?? 'medium'),
                                    size: 5.w,
                                  ),
                                  SizedBox(width: 2.w),
                                  Expanded(
                                    child: Text(
                                      alert['title'] ?? 'Emergency Alert',
                                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    _formatTimeAgo(DateTime.parse(alert['timestamp'] ?? DateTime.now().toIso8601String())),
                                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                                      color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                alert['message'] ?? 'No details available',
                                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (alert['affectedArea'] != null) ...[
                                SizedBox(height: 1.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 3.w,
                                      color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      alert['affectedArea'],
                                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                                        color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          
          // View All Button (only shown when expanded and there are more alerts)
          if (_isExpanded && widget.alerts.length > 3)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/disaster-alerts-screen'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
                child: Text(
                  'View All ${widget.alerts.length} Alerts',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
