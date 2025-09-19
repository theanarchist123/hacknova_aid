import 'package:flutter/material.dart';
import 'lib/core/services/india_disaster_alert_service.dart';

/// Quick test to verify real alerts are being fetched
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Testing India Disaster Alert Service...');
  
  try {
    final alerts = await IndiaDisasterAlertService.getIndiaAlerts();
    
    print('✅ Successfully fetched ${alerts.length} alerts');
    
    if (alerts.isNotEmpty) {
      print('📰 Real alert titles (not samples):');
      for (int i = 0; i < alerts.length && i < 5; i++) {
        final alert = alerts[i];
        print('   ${i + 1}. ${alert.title}');
        print('      Type: ${alert.type.name}, Severity: ${alert.severity.name}');
        print('      Source: ${alert.source}');
        print('      Time: ${alert.timestamp}');
        print('');
      }
    } else {
      print('⚠️ No alerts found');
    }
    
  } catch (e) {
    print('❌ Error testing alerts: $e');
  }
}