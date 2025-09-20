import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

import '../../core/app_export.dart';
import '../../core/services/india_disaster_alert_service.dart';
import '../../core/services/language_preference_service.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/multilanguage_alert_card.dart';
import './widgets/alert_card_widget.dart';
import './widgets/alert_filter_chips_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/search_bar_widget.dart';

class DisasterAlertsScreen extends StatefulWidget {
  const DisasterAlertsScreen({super.key});

  @override
  State<DisasterAlertsScreen> createState() => _DisasterAlertsScreenState();
}

class _DisasterAlertsScreenState extends State<DisasterAlertsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = 'All';
  String _selectedSeverity = 'All';
  String _selectedType = 'All';
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  bool _isRefreshing = false;
  bool _isLoading = true;
  Position? _currentPosition;
  String _selectedLanguage = 'en'; // User's preferred language

  final List<String> _categories = ['All', 'Active', 'Warnings', 'Resolved'];

  // Real disaster alerts data from India Disaster Alert Service
  List<DisasterAlert> _realAlerts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _initializeAlerts();
  }

  Future<void> _initializeAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user's preferred language
      final preferredLanguage = await LanguagePreferenceService.getPreferredLanguage();
      setState(() {
        _selectedLanguage = preferredLanguage;
      });

      // Get current location
      await _getCurrentLocation();
      
      // Fetch real disaster alerts
      await _loadRealAlerts();
    } catch (e) {
      print('Error initializing alerts: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('Current location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadRealAlerts() async {
    try {
      print('🇮🇳 Loading India-focused disaster alerts...');
      
      // Get user location for proximity prioritization
      LatLng? userLocation;
      if (_currentPosition != null) {
        userLocation = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      }
      
      // Fetch alerts using the new India Disaster Alert Service
      final alerts = await IndiaDisasterAlertService.getIndiaAlerts(
        userLocation: userLocation,
        limitResults: 15, // Focused results for screen display
        languageCode: _selectedLanguage, // Use user's preferred language
      );
      
      setState(() {
        _realAlerts = alerts;
      });
      
      print('✅ Loaded ${alerts.length} India-focused disaster alerts');
      
      // Log actual alert titles for verification
      if (alerts.isNotEmpty) {
        print('📰 Current alert titles:');
        for (int i = 0; i < min(3, alerts.length); i++) {
          print('   ${i + 1}. ${alerts[i].title}');
        }
      }
    } catch (e) {
      print('❌ Error loading real alerts: $e');
      setState(() {
        _realAlerts = _getEmergencyFallbackAlerts();
      });
    }
  }

  Future<void> _refreshAlerts() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _getCurrentLocation();
      await _loadRealAlerts();
    } catch (e) {
      print('Error refreshing alerts: $e');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  List<DisasterAlert> _getEmergencyFallbackAlerts() {
    final now = DateTime.now();
    return [
      DisasterAlert(
        id: 'fallback_1',
        title: 'Service Notification',
        type: DisasterType.other,
        severity: AlertSeverity.info,
        description: 'Unable to fetch live disaster alerts. Please check your internet connection and try again.',
        location: LatLng(28.6139, 77.2090), // Delhi coordinates as fallback
        timestamp: now,
        source: 'Emergency Alert System',
        sourceUrl: '',
        metadata: {'fallback': true},
      )
    ];
  }

  /// Convert DisasterAlert to Map for compatibility with existing widgets
  Map<String, dynamic> _convertToMap(DisasterAlert alert) {
    return {
      'id': alert.id,
      'title': alert.title,
      'description': alert.description,
      'type': alert.type.name,
      'severity': alert.severity.name,
      'affectedArea': alert.source, // Use source as affected area for now
      'timestamp': alert.timestamp.toIso8601String(),
      'source': alert.source,
      'isRead': false, // Default values for UI state
      'isPinned': false,
      'status': 'active',
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<DisasterAlert> get _filteredAlerts {
    List<DisasterAlert> filtered = List.from(_realAlerts);

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((alert) {
        switch (_selectedCategory.toLowerCase()) {
          case 'active':
            return true; // All alerts are active by default
          case 'warnings':
            return alert.severity == AlertSeverity.warning || alert.severity == AlertSeverity.critical;
          case 'resolved':
            return false; // No resolved alerts in current implementation
          default:
            return true;
        }
      }).toList();
    }

    // Filter by severity
    if (_selectedSeverity != 'All') {
      filtered = filtered
          .where((alert) =>
              alert.severity.name.toLowerCase() ==
              _selectedSeverity.toLowerCase())
          .toList();
    }

    // Filter by type
    if (_selectedType != 'All') {
      filtered = filtered
          .where((alert) =>
              alert.type.name.toLowerCase() ==
              _selectedType.toLowerCase())
          .toList();
    }

    // Filter by date range
    if (_selectedDateRange != null) {
      filtered = filtered.where((alert) {
        final alertTimestamp = alert.timestamp;
        
        return alertTimestamp.isAfter(
                _selectedDateRange!.start.subtract(Duration(days: 1))) &&
            alertTimestamp.isBefore(_selectedDateRange!.end.add(Duration(days: 1)));
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((alert) {
        final title = alert.title.toLowerCase();
        final description = alert.description.toLowerCase();
        final query = _searchQuery.toLowerCase();

        return title.contains(query) ||
            description.contains(query);
      }).toList();
    }

    // Sort by timestamp (newest first) - pinning functionality can be added later
    filtered.sort((a, b) {
      return b.timestamp.compareTo(a.timestamp);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Disaster Alerts',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        foregroundColor: AppTheme.lightTheme.appBarTheme.foregroundColor,
        elevation: AppTheme.lightTheme.appBarTheme.elevation,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.appBarTheme.foregroundColor!,
            size: 6.w,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Language selection button
          IconButton(
            icon: CustomIconWidget(
              iconName: 'language',
              color: AppTheme.lightTheme.appBarTheme.foregroundColor!,
              size: 6.w,
            ),
            onPressed: _showLanguageSelector,
            tooltip: 'Select Language',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'notifications',
              color: AppTheme.lightTheme.appBarTheme.foregroundColor!,
              size: 6.w,
            ),
            onPressed: _showNotificationSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            SearchBarWidget(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onFilterTap: _showFilterBottomSheet,
              hintText: 'Search alerts by title, area, or description...',
            ),

            // Filter Chips
            AlertFilterChipsWidget(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),

            // Active Filters Indicator
            if (_selectedSeverity != 'All' ||
                _selectedType != 'All' ||
                _selectedDateRange != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'filter_alt',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Filters applied',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearAllFilters,
                      child: Text(
                        'Clear All',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Alerts List
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _filteredAlerts.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshAlerts,
                          color: AppTheme.lightTheme.colorScheme.primary,
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _filteredAlerts.length,
                            itemBuilder: (context, index) {
                              final alert = _filteredAlerts[index];
                              return MultiLanguageAlertCard(
                                alert: alert,
                                languageCode: _selectedLanguage,
                                onTap: () => _showAlertDetails(_convertToMap(alert)),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _reportNewAlert,
        backgroundColor:
            AppTheme.lightTheme.floatingActionButtonTheme.backgroundColor,
        foregroundColor:
            AppTheme.lightTheme.floatingActionButtonTheme.foregroundColor,
        child: CustomIconWidget(
          iconName: 'add_alert',
          color: AppTheme.lightTheme.floatingActionButtonTheme.foregroundColor!,
          size: 6.w,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            'Loading disaster alerts...',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.lightTheme.textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Fetching real-time data from Ambee API',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.lightTheme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'search_off',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 20.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'No alerts found',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms or filters'
                : 'No disaster alerts match your current filters',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: _clearAllFilters,
            child: Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterBottomSheetWidget(
        selectedSeverity: _selectedSeverity,
        selectedType: _selectedType,
        selectedDateRange: _selectedDateRange,
        onApplyFilters: (severity, type, dateRange) {
          setState(() {
            _selectedSeverity = severity;
            _selectedType = type;
            _selectedDateRange = dateRange;
          });
        },
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedSeverity = 'All';
      _selectedType = 'All';
      _selectedDateRange = null;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _showAlertDetails(Map<String, dynamic> alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                alert['title'] ?? 'Alert Details',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        alert['description'] ?? 'No description available',
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Affected Area',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        alert['affectedArea'] ?? 'Not specified',
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Safety Instructions',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '• Stay indoors and avoid unnecessary travel\n• Keep emergency supplies ready\n• Follow official evacuation orders if issued\n• Stay tuned to official updates',
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareAlert(Map<String, dynamic> alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert shared successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setReminder(Map<String, dynamic> alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set for this alert'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleReadStatus(Map<String, dynamic> alert) {
    setState(() {
      // For now, just show feedback - would need to implement persistent state storage
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert marked as read'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _togglePinStatus(Map<String, dynamic> alert) {
    setState(() {
      // For now, just show feedback - would need to implement persistent state storage
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert pinned'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _hideAlertType(Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hide Alert Type'),
        content: Text(
            'Are you sure you want to hide all "${alert['type']}" alerts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${alert['type']} alerts hidden'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Hide'),
          ),
        ],
      ),
    );
  }

  void _reportFalseAlert(Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report False Alert'),
        content: Text(
            'Are you sure you want to report this alert as false information?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Alert reported. Thank you for your feedback.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Report'),
          ),
        ],
      ),
    );
  }

  void _reportNewAlert() {
    Navigator.pushNamed(context, '/incident-reporting-screen');
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 1.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            SizedBox(height: 3.h),
            
            Text(
              'Select Alert Language',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            
            // Language Selector Widget
            LanguageSelector(
              initialLanguage: _selectedLanguage,
              onLanguageChanged: (String newLanguage) async {
                setState(() {
                  _selectedLanguage = newLanguage;
                });
                
                // Refresh alerts with new language
                await _loadRealAlerts();
                
                Navigator.pop(context);
                
                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Language changed to ${LanguagePreferenceService.getLanguageName(newLanguage)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              showTitle: false,
            ),
            
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            SizedBox(height: 2.h),
            Text(
              'Notification Settings',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            SwitchListTile(
              title: Text('Critical Alerts'),
              subtitle: Text('Receive notifications for critical emergencies'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text('Warning Alerts'),
              subtitle: Text('Receive notifications for warning level alerts'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text('Info Alerts'),
              subtitle: Text('Receive notifications for informational alerts'),
              value: false,
              onChanged: (value) {},
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
