import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class InstructionSection extends StatelessWidget {
  final String title;
  final String iconName;
  final Color color;
  final List<String> steps;
  final bool isExpanded;

  const InstructionSection({
    super.key,
    required this.title,
    required this.iconName,
    required this.color,
    required this.steps,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        leading: CustomIconWidget(
          iconName: iconName,
          color: color,
          size: 6.w,
        ),
        title: Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${steps.length} safety steps',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 3.h),
            child: Column(
              children: List.generate(steps.length, (index) {
                return InstructionStep(
                  stepNumber: index + 1,
                  stepText: steps[index],
                  color: color,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class InstructionStep extends StatelessWidget {
  final int stepNumber;
  final String stepText;
  final Color color;

  const InstructionStep({
    super.key,
    required this.stepNumber,
    required this.stepText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              stepText,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}