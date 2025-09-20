import 'package:flutter_test/flutter_test.dart';
import 'package:hacknova_aid/core/services/localization_service.dart';

void main() {
  group('LocalizationService Tests', () {
    test('should default to English language', () {
      expect(LocalizationService.currentLanguage, SupportedLanguage.english);
    });

    test('should change language and translate correctly', () {
      // Test English (default)
      expect(
        LocalizationService.translate(LocalizationService.emergencyGuides),
        'Emergency Guides',
      );

      // Change to Hindi
      LocalizationService.setLanguage(SupportedLanguage.hindi);
      expect(
        LocalizationService.translate(LocalizationService.emergencyGuides),
        'आपातकालीन गाइड',
      );

      // Change to Marathi
      LocalizationService.setLanguage(SupportedLanguage.marathi);
      expect(
        LocalizationService.translate(LocalizationService.emergencyGuides),
        'आपत्कालीन मार्गदर्शक',
      );

      // Reset to English
      LocalizationService.setLanguage(SupportedLanguage.english);
    });

    test('should handle missing translations gracefully', () {
      // Create a test translation map missing some languages
      const testTranslation = {
        'en': 'Test English',
        'hi': 'Test Hindi',
        // Missing Marathi
      };

      LocalizationService.setLanguage(SupportedLanguage.marathi);
      final result = LocalizationService.translate(testTranslation);
      
      // Should fallback to English when current language not available
      expect(result, 'Test English');

      // Reset to English
      LocalizationService.setLanguage(SupportedLanguage.english);
    });

    test('should translate disaster-related terms correctly', () {
      // Test Cyclone
      LocalizationService.setLanguage(SupportedLanguage.hindi);
      expect(
        LocalizationService.translate(LocalizationService.cyclone),
        'चक्रवात',
      );

      LocalizationService.setLanguage(SupportedLanguage.marathi);
      expect(
        LocalizationService.translate(LocalizationService.cyclone),
        'चक्रीवादळ',
      );

      // Test Before/During/After
      LocalizationService.setLanguage(SupportedLanguage.hindi);
      expect(
        LocalizationService.translate(LocalizationService.before),
        'पहले',
      );
      expect(
        LocalizationService.translate(LocalizationService.during),
        'दौरान',
      );
      expect(
        LocalizationService.translate(LocalizationService.after),
        'बाद में',
      );

      // Reset to English
      LocalizationService.setLanguage(SupportedLanguage.english);
    });

    test('should provide all supported languages', () {
      expect(SupportedLanguage.values.length, 3);
      
      final languages = SupportedLanguage.values;
      expect(languages.contains(SupportedLanguage.english), true);
      expect(languages.contains(SupportedLanguage.hindi), true);
      expect(languages.contains(SupportedLanguage.marathi), true);
    });

    test('should have correct language codes and display names', () {
      expect(SupportedLanguage.english.code, 'en');
      expect(SupportedLanguage.english.displayName, 'English');
      
      expect(SupportedLanguage.hindi.code, 'hi');
      expect(SupportedLanguage.hindi.displayName, 'हिंदी');
      
      expect(SupportedLanguage.marathi.code, 'mr');
      expect(SupportedLanguage.marathi.displayName, 'मराठी');
    });
  });
}