import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DisasterOverviewCard extends StatelessWidget {
  final String title;
  final String iconName;
  final String overview;
  final Color accentColor;

  const DisasterOverviewCard({
    super.key,
    required this.title,
    required this.iconName,
    required this.overview,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
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
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: accentColor,
                  size: 8.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Disaster Information',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            overview,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickReferenceCard extends StatelessWidget {
  final List<String> dos;
  final List<String> donts;

  const QuickReferenceCard({
    super.key,
    required this.dos,
    required this.donts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
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
                iconName: 'lightbulb',
                color: Colors.amber,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Quick Reference',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Do's Column
              Expanded(
                child: SafetyTipColumn(
                  title: 'DO\'S',
                  iconName: 'check_circle',
                  color: AppTheme.successLight,
                  tips: dos,
                ),
              ),
              
              SizedBox(width: 3.w),
              
              // Don'ts Column
              Expanded(
                child: SafetyTipColumn(
                  title: 'DON\'TS',
                  iconName: 'cancel',
                  color: AppTheme.primaryLight,
                  tips: donts,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SafetyTipColumn extends StatelessWidget {
  final String title;
  final String iconName;
  final Color color;
  final List<String> tips;

  const SafetyTipColumn({
    super.key,
    required this.title,
    required this.iconName,
    required this.color,
    required this.tips,
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
              Flexible(
                child: Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...tips.map((tip) => Padding(
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
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}