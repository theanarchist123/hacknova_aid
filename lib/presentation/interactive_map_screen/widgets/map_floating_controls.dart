import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MapFloatingControls extends StatelessWidget {
  final VoidCallback onLocationPressed;
  final VoidCallback onMapTypePressed;
  final VoidCallback onLayersPressed;
  final bool isLocationLoading;
  final String currentMapType;

  const MapFloatingControls({
    super.key,
    required this.onLocationPressed,
    required this.onMapTypePressed,
    required this.onLayersPressed,
    this.isLocationLoading = false,
    this.currentMapType = 'normal',
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 4.w,
      bottom: 20.h,
      child: Column(
        children: [
          // Location button
          _buildControlButton(
            onPressed: onLocationPressed,
            child: isLocationLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  )
                : CustomIconWidget(
                    iconName: 'my_location',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 24,
                  ),
            tooltip: 'Center on my location',
          ),

          SizedBox(height: 2.h),

          // Map type button
          _buildControlButton(
            onPressed: onMapTypePressed,
            child: CustomIconWidget(
              iconName: _getMapTypeIcon(),
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            tooltip: 'Change map type',
          ),

          SizedBox(height: 2.h),

          // Layers button
          _buildControlButton(
            onPressed: onLayersPressed,
            child: CustomIconWidget(
              iconName: 'layers',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            tooltip: 'Toggle map layers',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required Widget child,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 12.w,
        height: 6.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  String _getMapTypeIcon() {
    switch (currentMapType) {
      case 'satellite':
        return 'satellite_alt';
      case 'terrain':
        return 'terrain';
      case 'hybrid':
        return 'layers';
      default:
        return 'map';
    }
  }
}
