import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/models/community_pin.dart';
import '../../../core/app_export.dart';

class PinDetailsPopup extends StatelessWidget {
  final CommunityPin pin;
  final Function()? onEdit;
  final Function()? onDelete;
  final Function()? onVerify;
  final Function()? onNavigate;
  final Function()? onShare;

  const PinDetailsPopup({
    super.key,
    required this.pin,
    this.onEdit,
    this.onDelete,
    this.onVerify,
    this.onNavigate,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 60.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                // Pin icon
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: _getPinColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomIconWidget(
                    iconName: pin.type.iconName,
                    color: _getPinColor(),
                    size: 32,
                  ),
                ),

                SizedBox(width: 3.w),

                // Title and type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pin.title,
                        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        pin.type.displayName,
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Priority badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPriorityText(),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Description
          if (pin.description.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pin.description,
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
              ),
            ),

          SizedBox(height: 2.h),

          // Info row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                // Location
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: '${pin.location.latitude.toStringAsFixed(4)}, ${pin.location.longitude.toStringAsFixed(4)}',
                  ),
                ),
                SizedBox(width: 4.w),
                // Created time
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.access_time,
                    label: 'Created',
                    value: _formatDateTime(pin.createdAt),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Status indicators
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                // Verification status
                _buildStatusChip(
                  icon: pin.verifiedBy.isNotEmpty ? Icons.verified : Icons.help_outline,
                  label: pin.verifiedBy.isNotEmpty 
                      ? 'Verified by ${pin.verifiedBy.length}'
                      : 'Unverified',
                  color: pin.verifiedBy.isNotEmpty ? Colors.green : Colors.orange,
                ),

                SizedBox(width: 2.w),

                // Sync status
                _buildStatusChip(
                  icon: pin.isSyncedToBluetooth ? Icons.sync : Icons.sync_problem,
                  label: pin.isSyncedToBluetooth ? 'Synced' : 'Not synced',
                  color: pin.isSyncedToBluetooth ? Colors.blue : Colors.orange,
                ),

                SizedBox(width: 2.w),

                // Status
                _buildStatusChip(
                  icon: _getStatusIcon(),
                  label: _getStatusText(),
                  color: _getStatusColor(),
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Action buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              children: [
                // Primary actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onNavigate,
                        icon: const Icon(Icons.directions),
                        label: const Text('Navigate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                          foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onVerify,
                        icon: const Icon(Icons.verified),
                        label: const Text('Verify'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 1.h),

                // Secondary actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    OutlinedButton(
                      onPressed: onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Icon(Icons.delete),
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

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 1.w),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPinColor() {
    if (pin.type.isHazard) {
      switch (pin.priority) {
        case PinPriority.critical:
          return Colors.purple;
        case PinPriority.high:
          return Colors.red;
        case PinPriority.medium:
          return Colors.orange;
        case PinPriority.low:
          return Colors.yellow[700]!;
      }
    } else if (pin.type.isResource) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  Color _getPriorityColor() {
    switch (pin.priority) {
      case PinPriority.low:
        return Colors.green;
      case PinPriority.medium:
        return Colors.orange;
      case PinPriority.high:
        return Colors.red;
      case PinPriority.critical:
        return Colors.purple;
    }
  }

  String _getPriorityText() {
    switch (pin.priority) {
      case PinPriority.low:
        return 'LOW';
      case PinPriority.medium:
        return 'MED';
      case PinPriority.high:
        return 'HIGH';
      case PinPriority.critical:
        return 'CRIT';
    }
  }

  IconData _getStatusIcon() {
    switch (pin.status) {
      case PinStatus.active:
        return Icons.check_circle;
      case PinStatus.resolved:
        return Icons.check_circle_outline;
      case PinStatus.verified:
        return Icons.verified;
      case PinStatus.needs_verification:
        return Icons.help_outline;
    }
  }

  String _getStatusText() {
    switch (pin.status) {
      case PinStatus.active:
        return 'Active';
      case PinStatus.resolved:
        return 'Resolved';
      case PinStatus.verified:
        return 'Verified';
      case PinStatus.needs_verification:
        return 'Needs Verification';
    }
  }

  Color _getStatusColor() {
    switch (pin.status) {
      case PinStatus.active:
        return Colors.green;
      case PinStatus.resolved:
        return Colors.blue;
      case PinStatus.verified:
        return Colors.green;
      case PinStatus.needs_verification:
        return Colors.orange;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}