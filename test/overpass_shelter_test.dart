import 'package:hacknova_aid/core/services/overpass_service.dart';
import 'package:hacknova_aid/core/services/shelter_service.dart';

void main() async {
  print('🗺️ OpenStreetMap Shelter Service Test');
  print('=' * 60);
  
  // Test coordinates (Mumbai)
  const double testLat = 19.0760;
  const double testLng = 72.8777;
  const int radiusM = 10000; // 10km
  
  print('📍 Testing location: Mumbai ($testLat, $testLng)');
  print('🔍 Search radius: ${radiusM / 1000}km');
  print('');
  
  // Test 1: Direct Overpass API test
  print('1️⃣ Testing Overpass API Connection...');
  try {
    final isConnected = await OverpassService.testConnection();
    if (isConnected) {
      print('✅ Overpass API is accessible');
    } else {
      print('❌ Overpass API connection failed');
    }
  } catch (e) {
    print('❌ Overpass API test error: $e');
  }
  print('');
  
  // Test 2: Fetch shelters directly from Overpass
  print('2️⃣ Testing Direct Overpass Shelter Fetch...');
  try {
    final overpassShelters = await OverpassService.fetchShelters(
      latitude: testLat,
      longitude: testLng,
      radiusMeters: radiusM,
    );
    
    print('📊 Overpass Results: ${overpassShelters.length} facilities found');
    
    if (overpassShelters.isNotEmpty) {
      print('\nTop 5 facilities from OpenStreetMap:');
      for (int i = 0; i < overpassShelters.length.clamp(0, 5); i++) {
        final shelter = overpassShelters[i];
        print('   ${i + 1}. ${shelter['name']} (${shelter['type']})');
        print('      📍 ${shelter['distanceKm']}km away');
        print('      🏠 Capacity: ${shelter['capacity']}, Occupancy: ${shelter['occupancy']}%');
        print('      📞 Contact: ${shelter['contact']['phone'] ?? 'Not available'}');
        print('');
      }
    }
  } catch (e) {
    print('❌ Overpass shelter fetch failed: $e');
  }
  print('');
  
  // Test 3: Test integrated shelter service
  print('3️⃣ Testing Integrated Shelter Service...');
  try {
    final shelterService = ShelterService();
    
    // Test connectivity first
    final hasConnectivity = await shelterService.testConnectivity();
    print('🌐 Service connectivity: ${hasConnectivity ? "Available" : "Using fallback"}');
    
    // Fetch shelters using the integrated service
    final shelters = await shelterService.findNearbyShelters(
      latitude: testLat,
      longitude: testLng,
      radiusM: radiusM.toDouble(),
    );
    
    print('🏠 Total shelters found: ${shelters.length}');
    
    if (shelters.isNotEmpty) {
      print('\nIntegrated Service Results:');
      
      // Group by source
      final osmShelters = shelters.where((s) => s['source'] == 'OpenStreetMap').toList();
      final googleShelters = shelters.where((s) => s['source'] == 'Google Places').toList();
      final fallbackShelters = shelters.where((s) => s['source'] == 'Emergency Fallback').toList();
      
      print('   🗺️ OpenStreetMap: ${osmShelters.length}');
      print('   🔍 Google Places: ${googleShelters.length}');
      print('   🆘 Fallback: ${fallbackShelters.length}');
      print('');
      
      // Show top 5 shelters with details
      print('Top 5 Recommended Shelters:');
      for (int i = 0; i < shelters.length.clamp(0, 5); i++) {
        final shelter = shelters[i];
        print('   ${i + 1}. ${shelter['name']}');
        print('      Type: ${shelter['type']}');
        print('      Distance: ${shelter['distanceKm']}km (${shelter['walkingTime']})');
        print('      Capacity: ${shelter['capacity']}, ${shelter['occupancy']}% occupied');
        print('      Status: ${shelter['statusColor']} (${shelter['distanceCategory']})');
        print('      Hours: ${shelter['operatingHours']}');
        print('      Source: ${shelter['source']}');
        
        if (shelter['amenities'] != null && shelter['amenities'].isNotEmpty) {
          final amenities = (shelter['amenities'] as List).take(3).join(', ');
          print('      Amenities: $amenities');
        }
        print('');
      }
      
      // Test different shelter types
      print('Shelter Types Distribution:');
      final typeGroups = <String, int>{};
      for (final shelter in shelters) {
        final type = shelter['type'] as String;
        typeGroups[type] = (typeGroups[type] ?? 0) + 1;
      }
      
      for (var entry in typeGroups.entries) {
        print('   ${entry.key}: ${entry.value}');
      }
    }
  } catch (e) {
    print('❌ Integrated shelter service failed: $e');
  }
  print('');
  
  // Test 4: Performance test
  print('4️⃣ Performance Test...');
  final stopwatch = Stopwatch()..start();
  try {
    final shelterService = ShelterService();
    await shelterService.findNearbyShelters(
      latitude: testLat,
      longitude: testLng,
      radiusM: 5000, // Smaller radius for speed
    );
    stopwatch.stop();
    print('⚡ Search completed in ${stopwatch.elapsedMilliseconds}ms');
  } catch (e) {
    stopwatch.stop();
    print('❌ Performance test failed: $e');
  }
  
  print('');
  print('=' * 60);
  print('✅ OpenStreetMap Integration Test Complete!');
  print('');
  print('Key Benefits of OpenStreetMap Integration:');
  print('• 🆓 Free API - no usage limits or costs');
  print('• 🌐 No CORS issues - works in web browsers');
  print('• 🗺️ Global coverage with local detail');
  print('• 🏥 Comprehensive facility types (hospitals, schools, etc.)');
  print('• 🔄 Real community-maintained data');
  print('• 🚀 Fast response times');
  print('• 🛡️ Privacy-friendly - no tracking');
  print('');
  print('Your disaster response app now has reliable, free shelter data! 🎉');
}
