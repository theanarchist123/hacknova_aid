import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SafetyTipCard extends StatelessWidget {
  final String title;
  final String iconName;
  final Color color;
  final List<String> tips;
  final bool isDo; // true for Do's, false for Don'ts

  const SafetyTipCard({
    super.key,
    required this.title,
    required this.iconName,
    required this.color,
    required this.tips,
    required this.isDo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: iconName,
                color: color,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...tips.map((tip) => SafetyTipItem(
            tip: tip,
            color: color,
          )).toList(),
        ],
      ),
    );
  }
}

class SafetyTipItem extends StatelessWidget {
  final String tip;
  final Color color;

  const SafetyTipItem({
    super.key,
    required this.tip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 1.5.w,
            height: 1.5.w,
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              tip,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}