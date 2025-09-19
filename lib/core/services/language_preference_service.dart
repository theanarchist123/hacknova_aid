import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage user's preferred language for disaster alerts
class LanguagePreferenceService {
  static const String _languageKey = 'preferred_alert_language';
  static const String _defaultLanguage = 'en';
  
  static String? _cachedLanguage;

  /// Supported languages for disaster alerts
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'हिंदी (Hindi)',
    'mr': 'मराठी (Marathi)', 
    'gu': 'ગુજરાતી (Gujarati)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'bn': 'বাংলা (Bengali)',
    'pa': 'ਪੰਜਾਬੀ (Punjabi)',
    'ur': 'اردو (Urdu)',
  };

  /// Get user's preferred language
  static Future<String> getPreferredLanguage() async {
    if (_cachedLanguage != null) {
      return _cachedLanguage!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString(_languageKey) ?? _defaultLanguage;
      _cachedLanguage = language;
      return language;
    } catch (e) {
      print('❌ Error getting preferred language: $e');
      return _defaultLanguage;
    }
  }

  /// Set user's preferred language
  static Future<bool> setPreferredLanguage(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) {
      print('❌ Unsupported language code: $languageCode');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_languageKey, languageCode);
      if (success) {
        _cachedLanguage = languageCode;
        print('✅ Language preference set to: ${supportedLanguages[languageCode]}');
      }
      return success;
    } catch (e) {
      print('❌ Error setting preferred language: $e');
      return false;
    }
  }

  /// Get display name for language code
  static String getLanguageDisplayName(String languageCode) {
    return supportedLanguages[languageCode] ?? 'Unknown';
  }

  /// Check if language selection has been set
  static Future<bool> hasLanguageBeenSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_languageKey);
    } catch (e) {
      return false;
    }
  }

  /// Clear language preference (for testing)
  static Future<void> clearLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_languageKey);
      _cachedLanguage = null;
      print('🗑️ Language preference cleared');
    } catch (e) {
      print('❌ Error clearing language preference: $e');
    }
  }

  /// Get regional language suggestion based on user location
  static String suggestLanguageForRegion(double latitude, double longitude) {
    // Maharashtra region (including Andheri)
    if (latitude >= 15.6 && latitude <= 22.0 && longitude >= 72.6 && longitude <= 80.9) {
      return 'mr'; // Marathi
    }
    
    // Gujarat region
    if (latitude >= 20.1 && latitude <= 24.7 && longitude >= 68.2 && longitude <= 74.5) {
      return 'gu'; // Gujarati
    }
    
    // Tamil Nadu region
    if (latitude >= 8.0 && latitude <= 13.6 && longitude >= 76.2 && longitude <= 80.3) {
      return 'ta'; // Tamil
    }
    
    // Karnataka region
    if (latitude >= 11.5 && latitude <= 18.5 && longitude >= 74.0 && longitude <= 78.6) {
      return 'kn'; // Kannada
    }
    
    // Telangana/Andhra Pradesh region
    if (latitude >= 12.6 && latitude <= 19.9 && longitude >= 77.0 && longitude <= 84.8) {
      return 'te'; // Telugu
    }
    
    // West Bengal region
    if (latitude >= 21.5 && latitude <= 27.2 && longitude >= 85.8 && longitude <= 89.9) {
      return 'bn'; // Bengali
    }
    
    // Punjab region
    if (latitude >= 29.5 && latitude <= 32.5 && longitude >= 73.9 && longitude <= 76.9) {
      return 'pa'; // Punjabi
    }
    
    // Default to Hindi for other regions
    return 'hi';
  }

  /// Get display name for a language code
  static String getLanguageName(String languageCode) {
    const languageNames = {
      'en': 'English',
      'hi': 'Hindi',
      'mr': 'Marathi',
      'gu': 'Gujarati',
      'ta': 'Tamil',
      'te': 'Telugu',
      'kn': 'Kannada',
      'bn': 'Bengali',
      'pa': 'Punjabi',
      'ur': 'Urdu',
    };
    
    return languageNames[languageCode] ?? 'Unknown';
  }
}