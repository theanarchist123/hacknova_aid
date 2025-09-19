/// Offline translation service for disaster alerts and precautions
class DisasterTranslationService {
  
  /// Translation database for disaster-related terms
  static const Map<String, Map<String, String>> _translations = {
    // Alert Types
    'earthquake': {
      'en': 'Earthquake',
      'hi': 'भूकंप',
      'mr': 'भूकंप',
      'gu': 'ભૂકંપ',
      'ta': 'நிலநடுக்கம்',
      'te': 'భూకంపనలు',
      'kn': 'ಭೂಕಂಪ',
      'bn': 'ভূমিকম্প',
      'pa': 'ਭੂਚਾਲ',
      'ur': 'زلزلہ',
    },
    'flood': {
      'en': 'Flood',
      'hi': 'बाढ़',
      'mr': 'पूर',
      'gu': 'પૂર',
      'ta': 'வெள்ளம்',
      'te': 'వరదలు',
      'kn': 'ಪ್ರವಾಹ',
      'bn': 'বন্যা',
      'pa': 'ਹੜ੍ਹ',
      'ur': 'سیلاب',
    },
    'cyclone': {
      'en': 'Cyclone',
      'hi': 'चक्रवात',
      'mr': 'चक्रीवादळ',
      'gu': 'ચક્રવાત',
      'ta': 'சூறாவளி',
      'te': 'తుఫాను',
      'kn': 'ಚಂಡಮಾರುತ',
      'bn': 'ঘূর্ণিঝড়',
      'pa': 'ਚੱਕਰਵਾਤ',
      'ur': 'طوفان',
    },
    'wildfire': {
      'en': 'Wildfire',
      'hi': 'जंगल की आग',
      'mr': 'जंगलातील आग',
      'gu': 'જંગલમાં આગ',
      'ta': 'காட்டுத் தீ',
      'te': 'అడవి మంటలు',
      'kn': 'ಕಾಡು ಬೆಂಕಿ',
      'bn': 'দাবানল',
      'pa': 'ਜੰਗਲੀ ਅੱਗ',
      'ur': 'جنگلی آگ',
    },
    'tsunami': {
      'en': 'Tsunami',
      'hi': 'सुनामी',
      'mr': 'त्सुनामी',
      'gu': 'સુનામી',
      'ta': 'சுனாமி',
      'te': 'సునామీ',
      'kn': 'ಸುನಾಮಿ',
      'bn': 'সুনামি',
      'pa': 'ਸੁਨਾਮੀ',
      'ur': 'سونامی',
    },
    'storm': {
      'en': 'Storm',
      'hi': 'तूफान',
      'mr': 'वादळ',
      'gu': 'તોફાન',
      'ta': 'புயல்',
      'te': 'తుఫాను',
      'kn': 'ಬಿರುಗಾಳಿ',
      'bn': 'ঝড়',
      'pa': 'ਤੂਫਾਨ',
      'ur': 'طوفان',
    },
    
    // Severity Levels
    'critical': {
      'en': 'Critical',
      'hi': 'अत्यंत गंभीर',
      'mr': 'अत्यंत गंभीर',
      'gu': 'અત્યંત ગંભીર',
      'ta': 'மிக முக்கியமான',
      'te': 'అత్యంత తీవ్రమైన',
      'kn': 'ಅತ್ಯಂತ ಗಂಭೀರ',
      'bn': 'অত্যন্ত গুরুতর',
      'pa': 'ਬਹੁਤ ਗੰਭੀਰ',
      'ur': 'انتہائی سنگین',
    },
    'severe': {
      'en': 'Severe',
      'hi': 'गंभीर',
      'mr': 'गंभीर',
      'gu': 'ગંભીર',
      'ta': 'கடுமையான',
      'te': 'తీవ్రమైన',
      'kn': 'ತೀವ್ರ',
      'bn': 'গুরুতর',
      'pa': 'ਗੰਭੀਰ',
      'ur': 'شدید',
    },
    'warning': {
      'en': 'Warning',
      'hi': 'चेतावनी',
      'mr': 'इशारा',
      'gu': 'ચેતવણી',
      'ta': 'எச்சரிக்கை',
      'te': 'హెచ్చరిక',
      'kn': 'ಎಚ್ಚರಿಕೆ',
      'bn': 'সতর্কতা',
      'pa': 'ਚੇਤਾਵਨੀ',
      'ur': 'انتباہ',
    },
    'info': {
      'en': 'Information',
      'hi': 'जानकारी',
      'mr': 'माहिती',
      'gu': 'માહિતી',
      'ta': 'தகவல்',
      'te': 'సమాచారం',
      'kn': 'ಮಾಹಿತಿ',
      'bn': 'তথ্য',
      'pa': 'ਜਾਣਕਾਰੀ',
      'ur': 'معلومات',
    },
    
    // Common Phrases
    'detected': {
      'en': 'detected',
      'hi': 'का पता चला',
      'mr': 'आढळून आलं',
      'gu': 'શોધાયું',
      'ta': 'கண்டறியப்பட்டது',
      'te': 'గుర్తించబడింది',
      'kn': 'ಪತ್ತೆಯಾಗಿದೆ',
      'bn': 'সনাক্ত',
      'pa': 'ਪਤਾ ਲੱਗਿਆ',
      'ur': 'دریافت',
    },
    'monitor_conditions': {
      'en': 'Monitor local conditions and take appropriate precautions',
      'hi': 'स्थानीय स्थितियों पर नज़र रखें और उचित एहतियात बरतें',
      'mr': 'स्थानिक परिस्थिती लक्षात ठेवा आणि योग्य खबरदारी घ्या',
      'gu': 'સ્થાનિક પરિસ્થિતિઓ પર નજર રાખો અને યોગ્ય સાવચેતી રાખો',
      'ta': 'உள்ளூர் நிலைமைகளை கண்காணித்து பொருத்தமான முன்னெச்சரிக்கைகளை எடுங்கள்',
      'te': 'స్థానిక పరిస్థితులను పర్యవేక్షించండి మరియు తగిన జాగ్రత్తలు తీసుకోండి',
      'kn': 'ಸ್ಥಳೀಯ ಪರಿಸ್ಥಿತಿಗಳನ್ನು ಮೇಲ್ವಿಚಾರಣೆ ಮಾಡಿ ಮತ್ತು ಸೂಕ್ತ ಮುನ್ನೆಚ್ಚರಿಕೆಗಳನ್ನು ತೆಗೆದುಕೊಳ್ಳಿ',
      'bn': 'স্থানীয় অবস্থা পর্যবেক্ষণ করুন এবং যথাযথ সতর্কতা নিন',
      'pa': 'ਸਥਾਨਕ ਹਾਲਾਤਾਂ ਦੀ ਨਿਗਰਾਨੀ ਕਰੋ ਅਤੇ ਢੁਕਵੀਂ ਸਾਵਧਾਨੀ ਬਰਤੋ',
      'ur': 'مقامی حالات کی نگرانی کریں اور مناسب احتیاط برتیں',
    },
    'located_km_away': {
      'en': 'Located {distance}km from your location',
      'hi': 'आपके स्थान से {distance} किमी दूर स्थित',
      'mr': 'आपल्या स्थानापासून {distance} किमी अंतरावर',
      'gu': 'તમારા સ્થાનથી {distance} કિમી દૂર સ્થિત',
      'ta': 'உங்கள் இடத்திலிருந்து {distance} கிமீ தூரத்தில் அமைந்துள்ளது',
      'te': 'మీ స్థానం నుండి {distance} కిమీ దూరంలో ఉంది',
      'kn': 'ನಿಮ್ಮ ಸ್ಥಳದಿಂದ {distance} ಕಿಮೀ ದೂರದಲ್ಲಿದೆ',
      'bn': 'আপনার অবস্থান থেকে {distance} কিমি দূরে অবস্থিত',
      'pa': 'ਤੁਹਾਡੇ ਸਥਾਨ ਤੋਂ {distance} ਕਿਮੀ ਦੂਰ ਸਥਿਤ',
      'ur': 'آپ کے مقام سے {distance} کلومیٹر دور واقع',
    },
    'weather_alert': {
      'en': 'Weather Alert',
      'hi': 'मौसम चेतावनी',
      'mr': 'हवामान इशारा',
      'gu': 'હવામાન ચેતવણી',
      'ta': 'வானிலை எச்சரிக்கை',
      'te': 'వాతావరణ హెచ్చరిక',
      'kn': 'ಹವಾಮಾನ ಎಚ್ಚರಿಕೆ',
      'bn': 'আবহাওয়া সতর্কতা',
      'pa': 'ਮੌਸਮ ਚੇਤਾਵਨੀ',
      'ur': 'موسمی انتباہ',
    },
    'wildfire_activity': {
      'en': 'Wildfire Activity',
      'hi': 'जंगल की आग की गतिविधि',
      'mr': 'जंगलातील आग',
      'gu': 'જંગલમાં આગની પ્રવૃત્તિ',
      'ta': 'காட்டுத் தீ நடவடிக்கை',
      'te': 'అడవి మంటల కార్యకలాపాలు',
      'kn': 'ಕಾಡಿನ ಬೆಂಕಿ ಚಟುವಟಿಕೆ',
      'bn': 'দাবানল কার্যকলাপ',
      'pa': 'ਜੰਗਲੀ ਅੱਗ ਦੀ ਗਤੀਵਿਧੀ',
      'ur': 'جنگلی آگ کی سرگرمی',
    },
  };

  /// Translate a term to the target language
  static String translateTerm(String term, String targetLanguage) {
    final translations = _translations[term.toLowerCase()];
    if (translations == null) {
      return term; // Return original if no translation found
    }
    
    return translations[targetLanguage] ?? translations['en'] ?? term;
  }

  /// Translate alert title with dynamic content
  static String translateAlertTitle(String title, String targetLanguage) {
    if (targetLanguage == 'en') return title;

    String translatedTitle = title;

    // Handle earthquake titles
    if (title.toLowerCase().contains('earthquake')) {
      final magnitudeMatch = RegExp(r'M(\d+\.?\d*)').firstMatch(title);
      final magnitude = magnitudeMatch?.group(1) ?? '';
      
      final locationMatch = RegExp(r'- (.+)$').firstMatch(title);
      final location = locationMatch?.group(1) ?? '';

      if (magnitude.isNotEmpty) {
        translatedTitle = '${translateTerm('earthquake', targetLanguage)} M$magnitude';
        if (location.isNotEmpty) {
          translatedTitle += ' - $location';
        }
      }
    }
    
    // Handle weather alerts
    else if (title.toLowerCase().contains('weather alert')) {
      final cityMatch = RegExp(r'Weather Alert: (.+)').firstMatch(title);
      final city = cityMatch?.group(1) ?? '';
      
      translatedTitle = translateTerm('weather_alert', targetLanguage);
      if (city.isNotEmpty) {
        translatedTitle += ': $city';
      }
    }
    
    // Handle wildfire alerts
    else if (title.toLowerCase().contains('wildfire activity')) {
      final regionMatch = RegExp(r'Wildfire Activity: (.+)').firstMatch(title);
      final region = regionMatch?.group(1) ?? '';
      
      translatedTitle = translateTerm('wildfire_activity', targetLanguage);
      if (region.isNotEmpty) {
        translatedTitle += ': $region';
      }
    }

    return translatedTitle;
  }

  /// Translate alert description with dynamic content
  static String translateAlertDescription(String description, String targetLanguage) {
    if (targetLanguage == 'en') return description;

    String translatedDescription = description;

    // Replace common terms
    _translations.forEach((key, translations) {
      final englishTerm = translations['en'] ?? '';
      final translatedTerm = translations[targetLanguage] ?? englishTerm;
      
      if (englishTerm.isNotEmpty && translatedTerm != englishTerm) {
        translatedDescription = translatedDescription.replaceAll(
          RegExp(englishTerm, caseSensitive: false),
          translatedTerm
        );
      }
    });

    // Handle distance phrases
    final distanceMatch = RegExp(r'Located (\d+)km from your location').firstMatch(description);
    if (distanceMatch != null) {
      final distance = distanceMatch.group(1);
      final translatedPhrase = translateTerm('located_km_away', targetLanguage)
          .replaceAll('{distance}', distance ?? '');
      translatedDescription = translatedDescription.replaceAll(distanceMatch.group(0)!, translatedPhrase);
    }

    // Handle monitor conditions phrase
    if (description.contains('Monitor local conditions and take appropriate precautions')) {
      translatedDescription = translatedDescription.replaceAll(
        'Monitor local conditions and take appropriate precautions',
        translateTerm('monitor_conditions', targetLanguage)
      );
    }

    return translatedDescription;
  }

  /// Get translated disaster type name
  static String getDisasterTypeName(String disasterType, String targetLanguage) {
    return translateTerm(disasterType.toLowerCase(), targetLanguage);
  }

  /// Get translated severity level
  static String getSeverityLevel(String severity, String targetLanguage) {
    return translateTerm(severity.toLowerCase(), targetLanguage);
  }
}