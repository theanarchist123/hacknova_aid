import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AlertCardWidget extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onReminder;
  final VoidCallback? onMarkRead;
  final VoidCallback? onPin;
  final VoidCallback? onHide;
  final VoidCallback? onReport;

  const AlertCardWidget({
    Key? key,
    required this.alert,
    this.onTap,
    this.onShare,
    this.onReminder,
    this.onMarkRead,
    this.onPin,
    this.onHide,
    this.onReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isRead = alert['isRead'] ?? false;
    final bool isPinned = alert['isPinned'] ?? false;
    final String severity = alert['severity'] ?? 'medium';

    Color severityColor = _getSeverityColor(severity);
    IconData disasterIcon = _getDisasterIcon(alert['type'] ?? 'general');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Slidable(
        key: ValueKey(alert['id']),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onShare?.call(),
              backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
              foregroundColor: AppTheme.lightTheme.colorScheme.onSecondary,
              icon: Icons.share,
              label: 'Share',
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (_) => onReminder?.call(),
              backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
              foregroundColor: AppTheme.lightTheme.colorScheme.onTertiary,
              icon: Icons.alarm,
              label: 'Remind',
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (_) => onMarkRead?.call(),
              backgroundColor: isRead
                  ? AppTheme.lightTheme.colorScheme.outline
                  : AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: isRead
                  ? AppTheme.lightTheme.colorScheme.onSurface
                  : AppTheme.lightTheme.colorScheme.onPrimary,
              icon: isRead ? Icons.mark_email_unread : Icons.mark_email_read,
              label: isRead ? 'Unread' : 'Read',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
          child: Card(
            elevation: isPinned ? 4 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isPinned
                    ? AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.3)
                    : Colors.transparent,
                width: isPinned ? 2 : 0,
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isRead
                    ? AppTheme.lightTheme.colorScheme.surface
                    : AppTheme.lightTheme.colorScheme.surface
                        .withValues(alpha: 0.95),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: _getIconName(disasterIcon),
                          color: severityColor,
                          size: 6.w,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 2.w,
                                    vertical: 0.5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: severityColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    severity.toUpperCase(),
                                    style: AppTheme
                                        .lightTheme.textTheme.labelSmall
                                        ?.copyWith(
                                      color: AppTheme
                                          .lightTheme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isPinned) ...[
                                  SizedBox(width: 2.w),
                                  CustomIconWidget(
                                    iconName: 'push_pin',
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    size: 4.w,
                                  ),
                                ],
                                Spacer(),
                                Text(
                                  _formatTimestamp(alert['timestamp']),
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              alert['title'] ?? 'Emergency Alert',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight:
                                    isRead ? FontWeight.w400 : FontWeight.w600,
                                color: isRead
                                    ? AppTheme
                                        .lightTheme.colorScheme.onSurfaceVariant
                                    : AppTheme.lightTheme.colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'location_on',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 4.w,
                      ),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          alert['affectedArea'] ?? 'Location not specified',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    alert['description'] ?? 'No description available',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isRead) ...[
                    SizedBox(height: 1.h),
                    Container(
                      width: double.infinity,
                      height: 0.3.h,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        return AppTheme.lightTheme.colorScheme.error;
      case 'warning':
      case 'medium':
        return AppTheme.lightTheme.colorScheme.secondary;
      case 'low':
      case 'info':
        return AppTheme.lightTheme.colorScheme.tertiary;
      default:
        return AppTheme.lightTheme.colorScheme.secondary;
    }
  }

  IconData _getDisasterIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flood':
        return Icons.water;
      case 'cyclone':
      case 'hurricane':
        return Icons.cyclone;
      case 'earthquake':
        return Icons.landscape;
      case 'fire':
        return Icons.local_fire_department;
      case 'outbreak':
        return Icons.coronavirus;
      case 'storm':
        return Icons.thunderstorm;
      case 'drought':
        return Icons.wb_sunny;
      default:
        return Icons.warning;
    }
  }

  String _getIconName(IconData iconData) {
    if (iconData == Icons.water) return 'water';
    if (iconData == Icons.cyclone) return 'cyclone';
    if (iconData == Icons.landscape) return 'landscape';
    if (iconData == Icons.local_fire_department) return 'local_fire_department';
    if (iconData == Icons.coronavirus) return 'coronavirus';
    if (iconData == Icons.thunderstorm) return 'thunderstorm';
    if (iconData == Icons.wb_sunny) return 'wb_sunny';
    return 'warning';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime dateTime;
    if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Unknown';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'push_pin',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text(
                alert['isPinned'] == true ? 'Unpin Alert' : 'Pin Important',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                onPin?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'visibility_off',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 6.w,
              ),
              title: Text(
                'Hide Alert Type',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                onHide?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'report',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 6.w,
              ),
              title: Text(
                'Report False Alert',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onReport?.call();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
