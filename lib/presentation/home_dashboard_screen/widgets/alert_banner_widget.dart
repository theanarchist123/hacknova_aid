import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AlertBannerWidget extends StatefulWidget {
  final String alertType;
  final String alertMessage;
  final VoidCallback? onDismiss;

  const AlertBannerWidget({
    Key? key,
    required this.alertType,
    required this.alertMessage,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<AlertBannerWidget> createState() => _AlertBannerWidgetState();
}

class _AlertBannerWidgetState extends State<AlertBannerWidget> {
  bool _isVisible = true;

  Color _getAlertColor() {
    switch (widget.alertType.toLowerCase()) {
      case 'critical':
        return AppTheme.lightTheme.colorScheme.error;
      case 'warning':
        return AppTheme.lightTheme.colorScheme.secondary;
      default:
        return AppTheme.lightTheme.colorScheme.secondary;
    }
  }

  IconData _getAlertIcon() {
    switch (widget.alertType.toLowerCase()) {
      case 'critical':
        return Icons.warning;
      case 'warning':
        return Icons.info;
      default:
        return Icons.info;
    }
  }

  void _dismissAlert() {
    setState(() {
      _isVisible = false;
    });
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Dismissible(
      key: Key('alert_banner_${widget.alertType}'),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) => _dismissAlert(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: _getAlertColor(),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: _getAlertIcon().codePoint.toString(),
              color: Colors.white,
              size: 6.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                widget.alertMessage,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: _dismissAlert,
              child: CustomIconWidget(
                iconName: 'close',
                color: Colors.white,
                size: 5.w,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
