import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LanguageSelector extends StatelessWidget {
  final String selectedLanguage;
  final Map<String, String> languages;
  final ValueChanged<String> onLanguageChanged;

  const LanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.languages,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: selectedLanguage,
        icon: CustomIconWidget(
          iconName: 'language',
          color: Colors.white,
          size: 5.w,
        ),
        iconEnabledColor: Colors.white,
        dropdownColor: AppTheme.lightTheme.primaryColor,
        underline: Container(),
        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
        items: languages.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.value,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          if (value != null) {
            onLanguageChanged(value);
          }
        },
      ),
    );
  }
}

class DisasterTypeSelector extends StatelessWidget {
  final String selectedDisaster;
  final Map<String, String> disasters;
  final ValueChanged<String> onDisasterChanged;

  const DisasterTypeSelector({
    super.key,
    required this.selectedDisaster,
    required this.disasters,
    required this.onDisasterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: disasters.length,
        itemBuilder: (context, index) {
          final disasterName = disasters.keys.elementAt(index);
          final iconName = disasters[disasterName]!;
          final isSelected = selectedDisaster == disasterName;
          
          return GestureDetector(
            onTap: () => onDisasterChanged(disasterName),
            child: DisasterSelectorCard(
              title: disasterName,
              iconName: iconName,
              isSelected: isSelected,
            ),
          );
        },
      ),
    );
  }
}

class DisasterSelectorCard extends StatelessWidget {
  final String title;
  final String iconName;
  final bool isSelected;

  const DisasterSelectorCard({
    super.key,
    required this.title,
    required this.iconName,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20.w,
      margin: EdgeInsets.only(right: 3.w),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppTheme.lightTheme.primaryColor 
            : AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? AppTheme.lightTheme.primaryColor 
              : AppTheme.outlineLight,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: isSelected 
                ? Colors.white 
                : AppTheme.lightTheme.primaryColor,
            size: 8.w,
          ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: isSelected 
                  ? Colors.white 
                  : AppTheme.lightTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}