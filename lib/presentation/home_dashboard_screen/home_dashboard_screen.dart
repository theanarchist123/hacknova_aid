import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/alert_banner_widget.dart';
import './widgets/emergency_fab_widget.dart';
import './widgets/location_greeting_widget.dart';
import './widgets/quick_action_card_widget.dart';
import './widgets/recent_alerts_widget.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with TickerProviderStateMixin {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  bool _isRefreshing = false;
  bool _hasActiveAlert = true;
  int _selectedBottomNavIndex = 0;

  // Mock data for alerts
  final List<Map<String, dynamic>> _recentAlerts = [
    {
      "id": 1,
      "type": "flood",
      "title": "Flash Flood Warning",
      "description":
          "Heavy rainfall expected in the next 2 hours. Avoid low-lying areas and stay indoors if possible. Emergency services are on standby.",
      "severity": "critical",
      "location": "Downtown Mumbai, Maharashtra",
      "timestamp": DateTime.now()
          .subtract(const Duration(minutes: 15))
          .toIso8601String(),
    },
    {
      "id": 2,
      "type": "cyclone",
      "title": "Cyclone Alert",
      "description":
          "Tropical cyclone approaching coastal areas. Wind speeds up to 120 km/h expected. Secure loose objects and stay away from windows.",
      "severity": "high",
      "location": "Coastal Gujarat",
      "timestamp":
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    },
    {
      "id": 3,
      "type": "outbreak",
      "title": "Health Advisory",
      "description":
          "Increased cases of dengue fever reported in the area. Take precautions against mosquito breeding and seek medical attention for fever symptoms.",
      "severity": "medium",
      "location": "South Delhi",
      "timestamp":
          DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
    },
    {
      "id": 4,
      "type": "earthquake",
      "title": "Seismic Activity",
      "description":
          "Minor earthquake detected. No immediate danger but residents should be aware of aftershock possibilities.",
      "severity": "low",
      "location": "Himachal Pradesh",
      "timestamp":
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupShakeDetection();
  }

  void _setupShakeDetection() {
    // Simulate shake detection for emergency SOS
    // In a real app, this would use accelerometer data
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);

    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isRefreshing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data refreshed successfully'),
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleQuickAction(String action) {
    HapticFeedback.lightImpact();

    switch (action) {
      case 'prediction':
        Navigator.pushNamed(context, '/disaster-alerts-screen');
        break;
      case 'preparedness':
        Navigator.pushNamed(context, '/emergency-response-screen');
        break;
      case 'response':
        Navigator.pushNamed(context, '/emergency-response-screen');
        break;
      case 'sos':
        _handleEmergencySOS();
        break;
    }
  }

  void _handleEmergencySOS() {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'emergency',
              color: Colors.white,
              size: 8.w,
            ),
            SizedBox(width: 3.w),
            Text(
              'Emergency SOS',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Emergency services will be contacted immediately. Your location and emergency contacts will be notified.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _activateEmergencySOS();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: const Text('Activate SOS'),
          ),
        ],
      ),
    );
  }

  void _activateEmergencySOS() {
    // In a real app, this would:
    // 1. Get current location
    // 2. Contact emergency services
    // 3. Send alerts to emergency contacts
    // 4. Enable offline communication features

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: Colors.white,
              size: 6.w,
            ),
            SizedBox(width: 3.w),
            const Expanded(
              child: Text('Emergency SOS activated. Help is on the way.'),
            ),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedBottomNavIndex = index);

    switch (index) {
      case 0:
        // Already on Home
        break;
      case 1:
        Navigator.pushNamed(context, '/interactive-map-screen');
        break;
      case 2:
        Navigator.pushNamed(context, '/incident-reporting-screen');
        break;
      case 3:
        // Settings - would navigate to settings screen
        break;
    }
  }

  List<Map<String, dynamic>> _getContextualActions(String cardType) {
    switch (cardType) {
      case 'prediction':
        return [
          {
            'title': 'Weather Forecast',
            'icon': 'wb_sunny',
            'onTap': () => _handleQuickAction('prediction'),
          },
          {
            'title': 'Disaster Alerts',
            'icon': 'warning',
            'onTap': () => _handleQuickAction('prediction'),
          },
        ];
      case 'preparedness':
        return [
          {
            'title': 'Emergency Kit',
            'icon': 'medical_services',
            'onTap': () => _handleQuickAction('preparedness'),
          },
          {
            'title': 'Evacuation Routes',
            'icon': 'directions',
            'onTap': () => _handleQuickAction('preparedness'),
          },
        ];
      case 'response':
        return [
          {
            'title': 'Emergency Contacts',
            'icon': 'contact_phone',
            'onTap': () => _handleQuickAction('response'),
          },
          {
            'title': 'First Aid Guide',
            'icon': 'healing',
            'onTap': () => _handleQuickAction('response'),
          },
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: AppTheme.lightTheme.colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              // Alert Banner
              if (_hasActiveAlert)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: AlertBannerWidget(
                      alertType: 'critical',
                      alertMessage:
                          'Flash Flood Warning: Heavy rainfall expected in your area. Stay indoors and avoid low-lying areas.',
                      onDismiss: () => setState(() => _hasActiveAlert = false),
                    ),
                  ),
                ),

              // Location Greeting
              SliverToBoxAdapter(
                child: LocationGreetingWidget(
                  location: 'Mumbai, Maharashtra',
                  weatherStatus: 'Rainy',
                  temperature: '28°C',
                ),
              ),

              // Quick Action Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style:
                            AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 4.w,
                        mainAxisSpacing: 2.h,
                        childAspectRatio: 1.0,
                        children: [
                          QuickActionCardWidget(
                            title: 'Prediction',
                            iconName: 'trending_up',
                            statusText: 'Weather alerts active',
                            activityCount: 3,
                            onTap: () => _handleQuickAction('prediction'),
                            contextualActions:
                                _getContextualActions('prediction'),
                          ),
                          QuickActionCardWidget(
                            title: 'Preparedness',
                            iconName: 'checklist',
                            statusText: 'Emergency kit ready',
                            activityCount: 0,
                            onTap: () => _handleQuickAction('preparedness'),
                            contextualActions:
                                _getContextualActions('preparedness'),
                          ),
                          QuickActionCardWidget(
                            title: 'Response',
                            iconName: 'emergency',
                            statusText: 'Services available',
                            activityCount: 1,
                            onTap: () => _handleQuickAction('response'),
                            contextualActions:
                                _getContextualActions('response'),
                          ),
                          QuickActionCardWidget(
                            title: 'SOS',
                            iconName: 'sos',
                            statusText: 'Emergency assistance',
                            activityCount: 0,
                            cardColor: AppTheme.lightTheme.colorScheme.error,
                            onTap: () => _handleQuickAction('sos'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Alerts Section
              SliverToBoxAdapter(
                child: RecentAlertsWidget(alerts: _recentAlerts),
              ),

              // Bottom padding for FAB
              SliverToBoxAdapter(
                child: SizedBox(height: 10.h),
              ),
            ],
          ),
        ),
      ),

      // Emergency FAB
      floatingActionButton: EmergencyFabWidget(
        onPressed: _handleEmergencySOS,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
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
          currentIndex: _selectedBottomNavIndex,
          onTap: _onBottomNavTap,
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
                iconName: 'home',
                color: _selectedBottomNavIndex == 0
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                size: 6.w,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  CustomIconWidget(
                    iconName: 'map',
                    color: _selectedBottomNavIndex == 1
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                    size: 6.w,
                  ),
                  if (_recentAlerts
                      .where((alert) => alert['severity'] == 'critical')
                      .isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 2.w,
                        height: 2.w,
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: 'report',
                color: _selectedBottomNavIndex == 2
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                size: 6.w,
              ),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: 'settings',
                color: _selectedBottomNavIndex == 3
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                size: 6.w,
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
