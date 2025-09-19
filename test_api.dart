import 'lib/core/utils/google_api_validator.dart';

void main() async {
  print('🧪 TESTING GOOGLE API CONFIGURATION');
  print('=====================================');
  
  try {
    await GoogleApiKeyValidator.quickTest();
  } catch (e) {
    print('Error during API validation: $e');
  }
  
  print('\n✅ Test completed. Check the output above for API status.');
}