/// Simple language preference service
class LanguagePreferenceService {
  static Future<String> getPreferredLanguage() async {
    // Default to English for now
    return 'en';
  }
  
  static Future<void> setPreferredLanguage(String languageCode) async {
    print('Language preference set to: $languageCode');
  }
}