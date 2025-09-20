import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final String currentRoute;

  const AppBottomNavigationBar({
    super.key,
    required this.currentRoute,
  });

  // Map route names to bottom nav indices
  static const Map<String, int> _routeToIndex = {
    '/ocr-screen': 0,
    '/ocr-summarizer-screen': 0,
    '/bluetooth-sos-screen': 1,
    '/home-dashboard-screen': 2,
    '/': 2, // Default home route
    '/speech-qna-screen': 3,
    '/emergency-response-screen': 4,
  };

  // Get current index based on route
  static int getIndexForRoute(String route) {
    // Handle AppRoutes constants
    if (route == AppRoutes.ocrSummarizerClean) return 0;
    if (route == AppRoutes.bluetoothSOS) return 1;
    if (route == AppRoutes.homeDashboard) return 2;
    if (route == AppRoutes.speechQna) return 3;
    if (route == AppRoutes.disasterPreparedness) return 4;
    
    return _routeToIndex[route] ?? 2; // Default to home if route not found
  }

  void _onBottomNavTap(BuildContext context, int index) {
    final currentIndex = getIndexForRoute(currentRoute);
    // Don't navigate if already on the target screen
    if (index == currentIndex) return;

    String targetRoute;
    switch (index) {
      case 0:
        targetRoute = AppRoutes.ocrSummarizerClean;
        break;
      case 1:
        targetRoute = AppRoutes.bluetoothSOS;
        break;
      case 2:
        targetRoute = AppRoutes.homeDashboard;
        break;
      case 3:
        targetRoute = AppRoutes.speechQna;
        break;
      case 4:
        targetRoute = '/emergency-response-screen';
        break;
      default:
        targetRoute = AppRoutes.homeDashboard;
    }

    // Use pushReplacementNamed to avoid stacking screens
    Navigator.pushReplacementNamed(context, targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = getIndexForRoute(currentRoute);
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onBottomNavTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
        unselectedItemColor:
            AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
        selectedLabelStyle:
            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTheme.lightTheme.textTheme.labelSmall,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'text_fields',
              color: currentIndex == 0
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
              size: 6.w,
            ),
            label: 'OCR',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'bluetooth',
              color: currentIndex == 1
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
              size: 6.w,
            ),
            label: 'Bluetooth',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'home',
              color: currentIndex == 2
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
              size: 6.w,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'mic',
              color: currentIndex == 3
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
              size: 6.w,
            ),
            label: 'Speech Q&A',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'emergency',
              color: currentIndex == 4
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
              size: 6.w,
            ),
            label: 'Response',
          ),
        ],
      ),
    );
  }
}