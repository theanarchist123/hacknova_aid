import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleApiKeyValidator {
  static const String apiKey = 'AIzaSyAxASAVnfdE_c9Axulg_dG0TBcTWGaN79I';

  /// Test if the Google API key is valid and has proper permissions
  static Future<Map<String, dynamic>> validateApiKey() async {
    Map<String, dynamic> results = {
      'geocoding': false,
      'places': false,
      'placeDetails': false,
      'errors': <String>[],
      'recommendations': <String>[],
    };

    print('🔍 Starting Google API Key validation...');
    print('API Key: ${apiKey.substring(0, 10)}...');

    // Test 1: Geocoding API
    try {
      print('\n📍 Testing Geocoding API...');
      final geocodingUrl = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=19.0760,72.8777&key=$apiKey';
      
      final geocodingResponse = await http.get(
        Uri.parse(geocodingUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DisasterApp/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (geocodingResponse.statusCode == 200) {
        final geocodingData = json.decode(geocodingResponse.body);
        if (geocodingData['status'] == 'OK') {
          print('✅ Geocoding API: WORKING');
          results['geocoding'] = true;
        } else {
          print('❌ Geocoding API Error: ${geocodingData['status']}');
          if (geocodingData['error_message'] != null) {
            print('   Error message: ${geocodingData['error_message']}');
            results['errors'].add('Geocoding: ${geocodingData['error_message']}');
          }
        }
      } else {
        print('❌ Geocoding API HTTP Error: ${geocodingResponse.statusCode}');
        results['errors'].add('Geocoding HTTP Error: ${geocodingResponse.statusCode}');
      }
    } catch (e) {
      print('❌ Geocoding API Exception: $e');
      results['errors'].add('Geocoding Exception: $e');
    }

    // Test 2: Places Autocomplete API
    try {
      print('\n🔍 Testing Places Autocomplete API...');
      final placesUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=restaurant&key=$apiKey';
      
      final placesResponse = await http.get(
        Uri.parse(placesUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DisasterApp/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (placesResponse.statusCode == 200) {
        final placesData = json.decode(placesResponse.body);
        if (placesData['status'] == 'OK' || placesData['status'] == 'ZERO_RESULTS') {
          print('✅ Places Autocomplete API: WORKING');
          results['places'] = true;
        } else {
          print('❌ Places API Error: ${placesData['status']}');
          if (placesData['error_message'] != null) {
            print('   Error message: ${placesData['error_message']}');
            results['errors'].add('Places: ${placesData['error_message']}');
          }
        }
      } else {
        print('❌ Places API HTTP Error: ${placesResponse.statusCode}');
        results['errors'].add('Places HTTP Error: ${placesResponse.statusCode}');
      }
    } catch (e) {
      print('❌ Places API Exception: $e');
      results['errors'].add('Places Exception: $e');
    }

    // Test 3: Place Details API (using a known place ID)
    try {
      print('\n📋 Testing Place Details API...');
      // This is a sample place ID for testing - it might not always work
      final placeDetailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=ChIJN1t_tDeuEmsRUsoyG83frY4&fields=geometry&key=$apiKey';
      
      final detailsResponse = await http.get(
        Uri.parse(placeDetailsUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DisasterApp/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (detailsResponse.statusCode == 200) {
        final detailsData = json.decode(detailsResponse.body);
        if (detailsData['status'] == 'OK') {
          print('✅ Place Details API: WORKING');
          results['placeDetails'] = true;
        } else {
          print('❌ Place Details API Error: ${detailsData['status']}');
          if (detailsData['error_message'] != null) {
            print('   Error message: ${detailsData['error_message']}');
            results['errors'].add('Place Details: ${detailsData['error_message']}');
          }
        }
      } else {
        print('❌ Place Details API HTTP Error: ${detailsResponse.statusCode}');
        results['errors'].add('Place Details HTTP Error: ${detailsResponse.statusCode}');
      }
    } catch (e) {
      print('❌ Place Details API Exception: $e');
      results['errors'].add('Place Details Exception: $e');
    }

    // Generate recommendations
    _generateRecommendations(results);

    print('\n📊 VALIDATION SUMMARY:');
    print('Geocoding API: ${results['geocoding'] ? '✅ Working' : '❌ Failed'}');
    print('Places API: ${results['places'] ? '✅ Working' : '❌ Failed'}');
    print('Place Details API: ${results['placeDetails'] ? '✅ Working' : '❌ Failed'}');
    
    if (results['errors'].isNotEmpty) {
      print('\n🚨 ERRORS FOUND:');
      for (String error in results['errors']) {
        print('  • $error');
      }
    }

    if (results['recommendations'].isNotEmpty) {
      print('\n💡 RECOMMENDATIONS:');
      for (String rec in results['recommendations']) {
        print('  • $rec');
      }
    }

    return results;
  }

  static void _generateRecommendations(Map<String, dynamic> results) {
    List<String> recommendations = [];

    if (!results['geocoding'] && !results['places'] && !results['placeDetails']) {
      recommendations.add('API key appears to be completely invalid or billing is not set up');
      recommendations.add('Check Google Cloud Console and ensure billing is enabled');
      recommendations.add('Verify the API key is correct and has no restrictions');
    }

    bool hasRequestDenied = false;
    bool hasQuotaExceeded = false;
    
    for (String error in results['errors']) {
      if (error.toLowerCase().contains('request_denied')) {
        hasRequestDenied = true;
      }
      if (error.toLowerCase().contains('over_query_limit')) {
        hasQuotaExceeded = true;
      }
    }

    if (hasRequestDenied) {
      recommendations.add('REQUEST_DENIED errors suggest API key restrictions or missing permissions');
      recommendations.add('Enable Geocoding API, Places API, and Place Details API in Google Cloud Console');
      recommendations.add('Check API key restrictions (HTTP referrers, IP addresses, Android apps)');
    }

    if (hasQuotaExceeded) {
      recommendations.add('OVER_QUERY_LIMIT suggests you have exceeded your API quota');
      recommendations.add('Check your Google Cloud Console for quota limits and usage');
      recommendations.add('Consider upgrading your billing plan if needed');
    }

    if (results['geocoding'] == false && results['places'] == true) {
      recommendations.add('Geocoding API is failing but Places API works - check specific API permissions');
    }

    if (results['geocoding'] == true && results['places'] == false) {
      recommendations.add('Places API is failing but Geocoding works - enable Places API in Google Cloud Console');
    }

    recommendations.add('Ensure billing is enabled in Google Cloud Console');
    recommendations.add('Check that the correct APIs are enabled: Geocoding, Places, Place Details');
    recommendations.add('Verify API key has no unnecessary restrictions');

    results['recommendations'] = recommendations;
  }

  /// Quick API test for debugging
  static Future<void> quickTest() async {
    print('🚀 Running quick Google API test...');
    await validateApiKey();
  }
}