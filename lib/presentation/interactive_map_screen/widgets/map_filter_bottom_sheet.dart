import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MapFilterBottomSheet extends StatefulWidget {
  final Map<String, bool> filterStates;
  final Function(Map<String, bool>) onFiltersChanged;

  const MapFilterBottomSheet({
    super.key,
    required this.filterStates,
    required this.onFiltersChanged,
  });

  @override
  State<MapFilterBottomSheet> createState() => _MapFilterBottomSheetState();
}

class _MapFilterBottomSheetState extends State<MapFilterBottomSheet> {
  late Map<String, bool> _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = Map.from(widget.filterStates);
  }

  @override
  Widget build(BuildContext context) {
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

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Map Layers',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onFiltersChanged(_currentFilters);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Apply',
                    style: TextStyle(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
            height: 1,
          ),

          // Filter options
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              children: [
                _buildFilterTile(
                  'Shelters',
                  'shelters',
                  'local_hotel',
                  AppTheme.lightTheme.colorScheme.primary,
                ),
                _buildFilterTile(
                  'Hospitals',
                  'hospitals',
                  'local_hospital',
                  const Color(0xFFE53935),
                ),
                _buildFilterTile(
                  'Food Centers',
                  'food_centers',
                  'restaurant',
                  const Color(0xFF43A047),
                ),
                _buildFilterTile(
                  'Evacuation Routes',
                  'evacuation_routes',
                  'directions',
                  const Color(0xFFFF9800),
                ),
                _buildFilterTile(
                  'Disaster Zones',
                  'disaster_zones',
                  'warning',
                  const Color(0xFFD32F2F),
                ),
                _buildFilterTile(
                  'Safe Zones',
                  'safe_zones',
                  'verified',
                  const Color(0xFF388E3C),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildFilterTile(
      String title, String key, String iconName, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: SwitchListTile(
        value: _currentFilters[key] ?? false,
        onChanged: (value) {
          setState(() {
            _currentFilters[key] = value;
          });
        },
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: iconName,
                color: color,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        activeColor: color,
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      ),
    );
  }
}
