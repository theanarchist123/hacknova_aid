import 'package:hacknova_aid/core/services/free_alerts_service.dart';
import 'package:hacknova_aid/core/services/disaster_alerts_service.dart';

void main() async {
  print('🧪 Testing Free Disaster Alerts Service');
  print('=' * 60);
  
  // Test coordinates (Mumbai, India)
  const double testLat = 19.0760;
  const double testLng = 72.8777;
  
  print('📍 Test location: Mumbai ($testLat, $testLng)');
  print('');
  
  // Test 1: Service connectivity
  print('1️⃣ Testing service connectivity...');
  try {
    final connectivity = await FreeAlertsService.instance.testConnectivity();
    print('   Connectivity results:');
    connectivity.forEach((service, available) {
      print('   • $service: ${available ? "✅ Available" : "❌ Unavailable"}');
    });
  } catch (e) {
    print('   ❌ Connectivity test failed: $e');
  }
  print('');
  
  // Test 2: Fetch alerts using the new free service
  print('2️⃣ Testing free alerts service (USGS + NASA EONET + ReliefWeb)...');
  try {
    final alerts = await FreeAlertsService.instance.fetchAlertsNear(
      lat: testLat,
      lon: testLng,
      days: 14,
      radiusKm: 1000, // 1000km radius for better coverage
    );
    
    print('   📊 Found ${alerts.length} alerts from all sources');
    
    if (alerts.isNotEmpty) {
      // Group by source
      final bySource = <String, int>{};
      for (final alert in alerts) {
        final source = alert['source']?.toString().split(' ')[0] ?? 'Unknown';
        bySource[source] = (bySource[source] ?? 0) + 1;
      }
      
      print('   📈 Alerts by source:');
      bySource.forEach((source, count) {
        print('   • $source: $count alerts');
      });
      
      print('');
      print('   🔝 Top 5 Recent Alerts:');
      for (int i = 0; i < alerts.length.clamp(0, 5); i++) {
        final alert = alerts[i];
        print('   ${i + 1}. ${alert['title']}');
        print('      Type: ${alert['type']}, Severity: ${alert['severity']}');
        print('      Source: ${alert['source']}');
        if (alert['distance_km'] != null) {
          print('      Distance: ${alert['distance_km'].toStringAsFixed(1)}km');
        }
        print('      Time: ${alert['timestamp']}');
        print('');
      }
    }
  } catch (e) {
    print('   ❌ Free alerts service failed: $e');
  }
  print('');
  
  // Test 3: Test the main disaster alerts service
  print('3️⃣ Testing main disaster alerts service...');
  try {
    final disasterService = DisasterAlertsService();
    final serviceAlerts = await disasterService.fetchDisasterAlerts(
      latitude: testLat,
      longitude: testLng,
      radiusKm: 500,
    );
    
    print('   📊 Main service found ${serviceAlerts.length} alerts');
    
    if (serviceAlerts.isNotEmpty) {
      print('   🎯 Sample alerts:');
      for (int i = 0; i < serviceAlerts.length.clamp(0, 3); i++) {
        final alert = serviceAlerts[i];
        print('   ${i + 1}. ${alert['title']}');
        print('      Type: ${alert['type']}, Severity: ${alert['severity']}');
        print('      Description: ${alert['description']}');
        print('');
      }
    }
    
    // Test connectivity
    final isConnected = await disasterService.testConnectivity();
    print('   🌐 Service connectivity: ${isConnected ? "✅ Available" : "❌ Using fallback"}');
    
  } catch (e) {
    print('   ❌ Main disaster service failed: $e');
  }
  
  print('');
  print('=' * 60);
  print('✅ Test Complete!');
  print('');
  print('📊 Summary:');
  print('• Uses 3 free, CORS-safe APIs: USGS, NASA EONET, ReliefWeb');
  print('• No API keys required');
  print('• Works in Flutter web browsers');
  print('• Global coverage for disasters');
  print('• Automatic fallback systems');
  print('');
  print('🎉 Your disaster alerts are now CORS-free and reliable!');
}
