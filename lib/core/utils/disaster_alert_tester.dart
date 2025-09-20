import 'package:flutter/material.dart';
import '../services/disaster_alert_store.dart';
import '../services/location_service.dart';
import '../services/india_disaster_alert_service.dart';

/// Helper class to test disaster alert functionality after app initialization
class DisasterAlertTester {
  /// Test location services
  static Future<Map<String, dynamic>> testLocationServices() async {
    final results = <String, dynamic>{};
    
    try {
      print('🧪 Testing location services...');
      
      // Test basic position
      final position = await LocationService.getCurrentPosition();
      results['has_position'] = position != null;
      if (position != null) {
        results['latitude'] = position.latitude;
        results['longitude'] = position.longitude;
      }
      
      // Test fallback location
      final fallbackLocation = await LocationService.getLocationWithFallback();
      results['has_fallback'] = fallbackLocation != null;
      if (fallbackLocation != null) {
        results['fallback_lat'] = fallbackLocation.latitude;
        results['fallback_lon'] = fallbackLocation.longitude;
        results['region'] = LocationService.getRegionForLocation(fallbackLocation);
        results['nearest_city'] = LocationService.getNearestCity(fallbackLocation);
      }
      
      results['success'] = true;
      print('✅ Location services test completed');
      
    } catch (e) {
      results['success'] = false;
      results['error'] = e.toString();
      print('❌ Location services test failed: $e');
    }
    
    return results;
  }

  /// Test disaster alert fetching
  static Future<Map<String, dynamic>> testDisasterAlerts() async {
    final results = <String, dynamic>{};
    
    try {
      print('🧪 Testing disaster alert services...');
      
      // Test combined alerts (this will test all sources internally)
      print('Testing combined alert service...');
      final allAlerts = await IndiaDisasterAlertService.getIndiaAlerts();
      results['total_alerts'] = allAlerts.length;
      
      // Analyze alerts by type
      final alertsByType = <String, int>{};
      for (final alert in allAlerts) {
        final typeName = alert.type.name;
        alertsByType[typeName] = (alertsByType[typeName] ?? 0) + 1;
      }
      results['alerts_by_type'] = alertsByType;
      
      // Analyze alerts by severity
      final alertsBySeverity = <String, int>{};
      for (final alert in allAlerts) {
        final severityName = alert.severity.name;
        alertsBySeverity[severityName] = (alertsBySeverity[severityName] ?? 0) + 1;
      }
      results['alerts_by_severity'] = alertsBySeverity;
      
      // Test alert store
      print('Testing alert store...');
      final alertStore = DisasterAlertStore.instance;
      final storedAlerts = await alertStore.fetchAndStoreAlerts();
      results['stored_alerts'] = storedAlerts.length;
      
      final summary = await alertStore.getAlertSummary();
      results['alert_summary'] = summary;
      
      results['success'] = true;
      print('✅ Disaster alert test completed');
      
    } catch (e) {
      results['success'] = false;
      results['error'] = e.toString();
      print('❌ Disaster alert test failed: $e');
    }
    
    return results;
  }

  /// Run comprehensive test suite
  static Future<Map<String, dynamic>> runFullTest() async {
    print('🚀 Starting comprehensive disaster alert test...');
    
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Test location services
    results['location_test'] = await testLocationServices();
    
    // Wait a bit between tests
    await Future.delayed(Duration(seconds: 2));
    
    // Test disaster alerts
    results['alerts_test'] = await testDisasterAlerts();
    
    // Overall success
    results['overall_success'] = 
      results['location_test']['success'] == true &&
      results['alerts_test']['success'] == true;
    
    print('🏁 Comprehensive test completed');
    _printTestResults(results);
    
    return results;
  }

  /// Print formatted test results
  static void _printTestResults(Map<String, dynamic> results) {
    print('\n${'=' * 50}');
    print('📊 DISASTER ALERT SYSTEM TEST RESULTS');
    print('=' * 50);
    
    final locationTest = results['location_test'] as Map<String, dynamic>;
    print('\n📍 LOCATION SERVICES:');
    print('   Success: ${locationTest['success']}');
    if (locationTest['success'] == true) {
      print('   Position: ${locationTest['has_position']}');
      if (locationTest['has_fallback'] == true) {
        print('   Region: ${locationTest['region']}');
        print('   Nearest City: ${locationTest['nearest_city']}');
      }
    } else {
      print('   Error: ${locationTest['error']}');
    }
    
    final alertsTest = results['alerts_test'] as Map<String, dynamic>;
    print('\n🚨 DISASTER ALERTS:');
    print('   Success: ${alertsTest['success']}');
    if (alertsTest['success'] == true) {
      print('   Total Alerts: ${alertsTest['total_alerts']}');
      print('   Stored in DB: ${alertsTest['stored_alerts']}');
      
      final alertsByType = alertsTest['alerts_by_type'] as Map<String, dynamic>?;
      if (alertsByType != null && alertsByType.isNotEmpty) {
        print('\n   📊 BY TYPE:');
        alertsByType.forEach((type, count) {
          print('      $type: $count');
        });
      }
      
      final alertsBySeverity = alertsTest['alerts_by_severity'] as Map<String, dynamic>?;
      if (alertsBySeverity != null && alertsBySeverity.isNotEmpty) {
        print('\n   📊 BY SEVERITY:');
        alertsBySeverity.forEach((severity, count) {
          print('      $severity: $count');
        });
      }
      
      final summary = alertsTest['alert_summary'] as Map<String, dynamic>?;
      if (summary != null) {
        print('\n📈 ALERT SUMMARY:');
        print('   Total: ${summary['total']}');
        print('   Nearby: ${summary['nearby']}');
        print('   Critical: ${summary['critical']}');
        print('   Severe: ${summary['severe']}');
      }
    } else {
      print('   Error: ${alertsTest['error']}');
    }
    
    print('\n🎯 OVERALL: ${results['overall_success'] ? "✅ SUCCESS" : "❌ FAILED"}');
    print('=' * 50 + '\n');
  }

  /// Create a simple test widget for UI testing
  static Widget createTestWidget() {
    return TestAlertWidget();
  }
}

/// Simple test widget for UI integration
class TestAlertWidget extends StatefulWidget {
  const TestAlertWidget({super.key});

  @override
  _TestAlertWidgetState createState() => _TestAlertWidgetState();
}

class _TestAlertWidgetState extends State<TestAlertWidget> {
  Map<String, dynamic>? _testResults;
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Disaster Alert Test')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _runTest,
              child: Text(_isRunning ? 'Running Test...' : 'Run Disaster Alert Test'),
            ),
            SizedBox(height: 20),
            if (_testResults != null) ..._buildResults(),
          ],
        ),
      ),
    );
  }

  void _runTest() async {
    setState(() {
      _isRunning = true;
      _testResults = null;
    });

    final results = await DisasterAlertTester.runFullTest();

    setState(() {
      _isRunning = false;
      _testResults = results;
    });
  }

  List<Widget> _buildResults() {
    final results = _testResults!;
    
    return [
      Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Test Results', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 8),
              Text('Overall: ${results['overall_success'] ? "✅ SUCCESS" : "❌ FAILED"}'),
              SizedBox(height: 8),
              Text('Location Services: ${results['location_test']['success'] ? "✅" : "❌"}'),
              Text('Disaster Alerts: ${results['alerts_test']['success'] ? "✅" : "❌"}'),
            ],
          ),
        ),
      ),
      SizedBox(height: 16),
      Expanded(
        child: SingleChildScrollView(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Full Results:\n${results.toString()}',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}