import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickActionCardWidget extends StatefulWidget {
  final String title;
  final String iconName;
  final String statusText;
  final int activityCount;
  final Color? cardColor;
  final VoidCallback onTap;
  final List<Map<String, dynamic>>? contextualActions;

  const QuickActionCardWidget({
    Key? key,
    required this.title,
    required this.iconName,
    required this.statusText,
    required this.activityCount,
    this.cardColor,
    required this.onTap,
    this.contextualActions,
  }) : super(key: key);

  @override
  State<QuickActionCardWidget> createState() => _QuickActionCardWidgetState();
}

class _QuickActionCardWidgetState extends State<QuickActionCardWidget> {
  bool _isPressed = false;

  void _showContextualMenu() {
    if (widget.contextualActions == null || widget.contextualActions!.isEmpty)
      return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
            SizedBox(height: 3.h),
            Text(
              widget.title,
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            ...widget.contextualActions!
                .map((action) => ListTile(
                      leading: CustomIconWidget(
                        iconName: action['icon'] ?? 'help',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 6.w,
                      ),
                      title: Text(
                        action['title'] ?? '',
                        style: AppTheme.lightTheme.textTheme.bodyLarge,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        if (action['onTap'] != null) {
                          action['onTap']();
                        }
                      },
                    ))
                .toList(),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onLongPress: _showContextualMenu,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        child: Card(
          elevation: _isPressed ? 8 : 4,
          color: widget.cardColor ?? AppTheme.lightTheme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            height: 20.h,
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: widget.cardColor != null
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomIconWidget(
                        iconName: widget.iconName,
                        color: widget.cardColor != null
                            ? Colors.white
                            : AppTheme.lightTheme.colorScheme.primary,
                        size: 8.w,
                      ),
                    ),
                    widget.activityCount > 0
                        ? Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.activityCount > 99
                                  ? '99+'
                                  : widget.activityCount.toString(),
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.title,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.cardColor != null
                        ? Colors.white
                        : AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.h),
                Text(
                  widget.statusText,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: widget.cardColor != null
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
