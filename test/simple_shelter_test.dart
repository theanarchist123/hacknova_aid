import 'package:hacknova_aid/core/services/overpass_service.dart';
import 'package:hacknova_aid/core/services/shelter_service.dart';

void main() async {
  print('🗺️ Testing OpenStreetMap Integration');
  print('=' * 50);
  
  try {
    // Test 1: Basic connectivity
    print('1. Testing Overpass API connectivity...');
    final isConnected = await OverpassService.testConnection();
    print('   Result: ${isConnected ? "✅ Connected" : "❌ No connection"}');
    
    if (isConnected) {
      // Test 2: Fetch shelters for Mumbai
      print('\n2. Fetching shelters for Mumbai...');
      final shelters = await OverpassService.fetchShelters(
        latitude: 19.0760,
        longitude: 72.8777,
        radiusMeters: 5000, // 5km
      );
      
      print('   Found ${shelters.length} potential shelter facilities');
      
      if (shelters.isNotEmpty) {
        print('\n   Top 3 facilities:');
        final topCount = shelters.length < 3 ? shelters.length : 3;
        for (int i = 0; i < topCount; i++) {
          final shelter = shelters[i];
          print('   ${i + 1}. ${shelter['name']} (${shelter['type']})');
          print('      Distance: ${shelter['distanceKm']}km');
        }
      }
      
      // Test 3: Integrated service
      print('\n3. Testing integrated shelter service...');
      final shelterService = ShelterService();
      final allShelters = await shelterService.findNearbyShelters(
        latitude: 19.0760,
        longitude: 72.8777,
        radiusM: 5000.0,
      );
      
      print('   Total shelters from integrated service: ${allShelters.length}');
      
      // Count by source
      final sources = <String, int>{};
      for (final shelter in allShelters) {
        final source = shelter['source'] as String;
        sources[source] = (sources[source] ?? 0) + 1;
      }
      
      print('   Sources breakdown:');
      sources.forEach((source, count) {
        print('   - $source: $count');
      });
      
      print('\n✅ OpenStreetMap integration is working!');
      print('\nBenefits:');
      print('• Free to use - no API costs');
      print('• No CORS issues in web browsers');
      print('• Global coverage with local details');
      print('• Real community-maintained data');
      
    } else {
      print('\n❌ Cannot connect to Overpass API');
      print('   The integration is ready but needs internet connection');
    }
    
  } catch (e, stackTrace) {
    print('\n❌ Test failed with error: $e');
    print('Stack trace:');
    print(stackTrace);
  }
  
  print('\n${'=' * 50}');
  print('Test complete!');
}
