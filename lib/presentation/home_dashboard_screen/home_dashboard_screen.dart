import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/app_export.dart';
import '../../core/services/disaster_alerts_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/notification_service.dart';
import './widgets/alert_banner_widget.dart';
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
  bool _hasActiveAlert = false;
  int _selectedBottomNavIndex = 2; // Home is at index 2 (center of 5 tabs)

  // Real-time data services
  final DisasterAlertsService _alertsService = DisasterAlertsService();
  List<Map<String, dynamic>> _recentAlerts = [];
  bool _isLoadingAlerts = false;
  Position? _currentPosition;
  String _currentLocationName = "Getting location...";
  
  // Real-time notifications
  late Stream<Map<String, dynamic>> _notificationStream;
  Map<String, dynamic>? _currentNotification;

  @override
  void initState() {
    super.initState();
    _setupShakeDetection();
    _initializeLocation();
    _setupNotificationStream();
  }
  
  void _setupNotificationStream() {
    _notificationStream = NotificationService.startNotificationStream();
    _notificationStream.listen((notification) {
      if (mounted) {
        setState(() {
          _currentNotification = notification;
          _hasActiveAlert = true;
        });
        
        // Only update the top notification banner, no bottom popup
      }
    });
  }

  Future<void> _initializeLocation() async {
    try {
      // Request location permission
      await LocationService.requestLocationPermission();
      
      // Get current location
      _currentPosition = await LocationService.getCurrentPosition();
      
      if (_currentPosition != null) {
        _currentLocationName = await LocationService.getLocationName(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        
        if (mounted) {
          setState(() {});
        }
        
        // Load real-time alerts
        await _loadRealTimeAlerts();
      } else {
        if (mounted) {
          setState(() {
            _currentLocationName = "Location unavailable";
          });
        }
        // Load alerts without location
        await _loadRealTimeAlerts();
      }
    } catch (e) {
      print('Error initializing location: $e');
      if (mounted) {
        setState(() {
          _currentLocationName = "Location error";
        });
      }
      await _loadRealTimeAlerts();
    }
  }

  Future<void> _loadRealTimeAlerts() async {
    if (mounted) {
      setState(() => _isLoadingAlerts = true);
    }
    
    try {
      final alerts = await _alertsService.fetchDisasterAlerts(
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        radiusKm: 50,
      );
      
      if (mounted) {
        setState(() {
          _recentAlerts = alerts.take(5).toList(); // Show only recent 5 alerts
          _hasActiveAlert = alerts.any((alert) => 
            alert['severity'] == 'critical' || alert['severity'] == 'high');
        });
      }
    } catch (e) {
      print('Error loading alerts: $e');
      // Keep existing mock data as fallback
      if (mounted) {
        setState(() {
          _recentAlerts = _getFallbackAlerts();
          _hasActiveAlert = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAlerts = false);
      }
    }
  }

  List<Map<String, dynamic>> _getFallbackAlerts() {
    return [
      {
        "id": 1,
        "type": "flood",
        "title": "Flash Flood Warning",
        "description":
            "Heavy rainfall expected in the next 2 hours. Avoid low-lying areas and stay indoors if possible. Emergency services are on standby.",
        "severity": "critical",
        "affectedArea": "Downtown Mumbai, Maharashtra",
        "timestamp": DateTime.now()
            .subtract(const Duration(minutes: 15))
            .toIso8601String(),
        "isRead": false,
        "isPinned": false,
        "status": "active",
        "source": "Emergency Services",
      },
      {
        "id": 2,
        "type": "cyclone", 
        "title": "Cyclone Alert",
        "description":
            "Tropical cyclone approaching coastal areas. Wind speeds up to 120 km/h expected. Secure loose objects and stay away from windows.",
        "severity": "high",
        "affectedArea": "Coastal Gujarat",
        "timestamp":
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        "isRead": false,
        "isPinned": false,
        "status": "active",
        "source": "Weather Department",
      }
    ];
  }

  void _setupShakeDetection() {
    // Simulate shake detection for emergency SOS
    // In a real app, this would use accelerometer data
  }

  Future<void> _handleRefresh() async {
    if (mounted) {
      setState(() => _isRefreshing = true);
    }

    // Refresh location and alerts
    await _initializeLocation();

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
    
    // Refresh completed silently - no bottom popup needed
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
      case 'incident':
        Navigator.pushNamed(context, '/interactive-map-screen');
        break;
    }
  }

  void _onBottomNavTap(int index) {
    if (mounted) {
      setState(() => _selectedBottomNavIndex = index);
    }

    switch (index) {
      case 0:
        // OCR tab - placeholder for now
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OCR screen coming soon!'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 1:
        // Bluetooth Chat tab - placeholder for now
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth Chat screen coming soon!'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 2:
        // Already on Home - do nothing
        break;
      case 3:
        // Speech QnA tab - placeholder for now
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech Q&A screen coming soon!'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 4:
        // Response tab - navigate to emergency response screen
        Navigator.pushNamed(context, '/emergency-response-screen');
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
      case 'incident':
        return [
          {
            'title': 'Report Emergency',
            'icon': 'warning',
            'onTap': () => _handleQuickAction('incident'),
          },
          {
            'title': 'View Map',
            'icon': 'map',
            'onTap': () => _handleQuickAction('incident'),
          },
        ];
      default:
        return [];
    }
  }

  @override
  void dispose() {
    NotificationService.dispose();
    super.dispose();
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
              // Real-time Alert Banner
              if (_currentNotification != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: AlertBannerWidget(
                      alertType: _currentNotification!['severity'] ?? 'moderate',
                      alertMessage: '${_currentNotification!['icon'] ?? '⚠️'} ${_currentNotification!['title'] ?? 'Alert'}: ${_currentNotification!['message'] ?? 'Check disaster alerts for more information.'}',
                      onDismiss: () => setState(() {
                        _currentNotification = null;
                        _hasActiveAlert = false;
                      }),
                    ),
                  ),
                ),

              // Location Greeting
              SliverToBoxAdapter(
                child: LocationGreetingWidget(
                  location: _currentLocationName,
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
                            statusText: _isLoadingAlerts 
                              ? 'Loading alerts...' 
                              : '${_recentAlerts.length} active alerts',
                            activityCount: _recentAlerts.length,
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
                            title: 'Incident Reporting',
                            iconName: 'report_problem',
                            statusText: 'Report emergencies',
                            activityCount: 0,
                            onTap: () => _handleQuickAction('incident'),
                            contextualActions:
                                _getContextualActions('incident'),
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

              // Bottom padding
              SliverToBoxAdapter(
                child: SizedBox(height: 5.h),
              ),
            ],
          ),
        ),
      ),

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
                iconName: 'text_fields',
                color: _selectedBottomNavIndex == 0
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
                color: _selectedBottomNavIndex == 1
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
                color: _selectedBottomNavIndex == 2
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
                color: _selectedBottomNavIndex == 3
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
                color: _selectedBottomNavIndex == 4
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                size: 6.w,
              ),
              label: 'Response',
            ),
          ],
        ),
      ),
    );
  }
}
