import 'package:flutter/foundation.dart';

enum SupportedLanguage {
  english('en', 'English'),
  hindi('hi', 'हिंदी'),
  marathi('mr', 'मराठी');

  const SupportedLanguage(this.code, this.displayName);
  final String code;
  final String displayName;
}

class LocalizationService {
  static ValueNotifier<SupportedLanguage> languageNotifier = 
      ValueNotifier(SupportedLanguage.english);

  static SupportedLanguage get currentLanguage => languageNotifier.value;

  static void setLanguage(SupportedLanguage language) {
    languageNotifier.value = language;
  }

  static String translate(Map<String, String> translations) {
    return translations[currentLanguage.code] ?? 
           translations['en'] ?? 
           translations.values.first;
  }

  // Emergency Guides Translation Keys
  static const Map<String, String> emergencyGuides = {
    'en': 'Emergency Guides',
    'hi': 'आपातकालीन गाइड',
    'mr': 'आपत्कालीन मार्गदर्शक',
  };

  static const Map<String, String> emergencyGuidesDesc = {
    'en': 'Comprehensive disaster response guides for all emergencies',
    'hi': 'सभी आपात स्थितियों के लिए व्यापक आपदा प्रतिक्रिया गाइड',
    'mr': 'सर्व आपत्कालीन परिस्थितींसाठी सर्वसमावेशक आपत्ती प्रतिसाद मार्गदर्शक',
  };

  static const Map<String, String> disasterGuides = {
    'en': 'Disaster Guides',
    'hi': 'आपदा गाइड',
    'mr': 'आपत्ती मार्गदर्शक',
  };

  static const Map<String, String> quickDisasterTips = {
    'en': 'Quick Disaster Tips',
    'hi': 'त्वरित आपदा सुझाव',
    'mr': 'जलद आपत्ती टिप्स',
  };

  static const Map<String, String> language = {
    'en': 'Language',
    'hi': 'भाषा',
    'mr': 'भाषा',
  };

  static const Map<String, String> overview = {
    'en': 'Overview',
    'hi': 'सिंहावलोकन',
    'mr': 'सारांश',
  };

  static const Map<String, String> before = {
    'en': 'Before',
    'hi': 'पहले',
    'mr': 'आधी',
  };

  static const Map<String, String> during = {
    'en': 'During',
    'hi': 'दौरान',
    'mr': 'दरम्यान',
  };

  static const Map<String, String> after = {
    'en': 'After',
    'hi': 'बाद में',
    'mr': 'नंतर',
  };

  static const Map<String, String> andMore = {
    'en': 'and',
    'hi': 'और',
    'mr': 'आणि',
  };

  static const Map<String, String> more = {
    'en': 'more',
    'hi': 'अधिक',
    'mr': 'अधिक',
  };

  static const Map<String, String> steps = {
    'en': 'steps',
    'hi': 'चरण',
    'mr': 'पायऱ्या',
  };

  static const Map<String, String> viewCompleteGuides = {
    'en': 'View Complete Guides',
    'hi': 'पूर्ण गाइड देखें',
    'mr': 'संपूर्ण मार्गदर्शक पहा',
  };

  static const Map<String, String> quickTips = {
    'en': 'Quick Tips',
    'hi': 'त्वरित सुझाव',
    'mr': 'जलद टिप्स',
  };

  static const Map<String, String> dos = {
    'en': 'DO\'S',
    'hi': 'करें',
    'mr': 'करा',
  };

  static const Map<String, String> donts = {
    'en': 'DON\'TS',
    'hi': 'न करें',
    'mr': 'करू नका',
  };

  static const Map<String, String> close = {
    'en': 'Close',
    'hi': 'बंद करें',
    'mr': 'बंद करा',
  };

  // Disaster Type Names (for dynamic translation)
  static const Map<String, String> cyclone = {
    'en': 'Cyclone',
    'hi': 'चक्रवात',
    'mr': 'चक्रीवादळ',
  };

  static const Map<String, String> flood = {
    'en': 'Flood',
    'hi': 'बाढ़',
    'mr': 'पूर',
  };

  static const Map<String, String> forestFire = {
    'en': 'Forest Fire',
    'hi': 'वन आग',
    'mr': 'वन आग',
  };

  static const Map<String, String> earthquake = {
    'en': 'Earthquake',
    'hi': 'भूकंप',
    'mr': 'भूकंप',
  };

  // Additional Emergency Guide Terms
  static const Map<String, String> safetyPrecautions = {
    'en': 'Safety Precautions',
    'hi': 'सुरक्षा सावधानियां',
    'mr': 'सुरक्षा खबरदारी',
  };

  static const Map<String, String> emergencyProcedures = {
    'en': 'Emergency Procedures',
    'hi': 'आपातकालीन प्रक्रिया',
    'mr': 'आपत्कालीन प्रक्रिया',
  };

  static const Map<String, String> preparedness = {
    'en': 'Preparedness',
    'hi': 'तैयारी',
    'mr': 'तयारी',
  };

  static const Map<String, String> response = {
    'en': 'Response',
    'hi': 'प्रतिक्रिया',
    'mr': 'प्रतिसाद',
  };

  static const Map<String, String> recovery = {
    'en': 'Recovery',
    'hi': 'पुनर्प्राप्ति',
    'mr': 'पुनर्प्राप्ती',
  };

  static const Map<String, String> warning = {
    'en': 'Warning',
    'hi': 'चेतावनी',
    'mr': 'चेतावणी',
  };

  static const Map<String, String> alert = {
    'en': 'Alert',
    'hi': 'अलर्ट',
    'mr': 'सतर्कता',
  };

  static const Map<String, String> evacuation = {
    'en': 'Evacuation',
    'hi': 'निकासी',
    'mr': 'निर्गमन',
  };

  static const Map<String, String> shelter = {
    'en': 'Shelter',
    'hi': 'आश्रय',
    'mr': 'आश्रय',
  };

  static const Map<String, String> firstAid = {
    'en': 'First Aid',
    'hi': 'प्राथमिक चिकित्सा',
    'mr': 'प्राथमिक वैद्यकीय मदत',
  };

  static const Map<String, String> emergencyKit = {
    'en': 'Emergency Kit',
    'hi': 'आपातकालीन किट',
    'mr': 'आपत्कालीन किट',
  };

  static const Map<String, String> communicationPlan = {
    'en': 'Communication Plan',
    'hi': 'संचार योजना',
    'mr': 'संवाद योजना',
  };

  static const Map<String, String> importantDocuments = {
    'en': 'Important Documents',
    'hi': 'महत्वपूर्ण दस्तावेज',
    'mr': 'महत्वाची कागदपत्रे',
  };

  static const Map<String, String> waterSupply = {
    'en': 'Water Supply',
    'hi': 'पानी की आपूर्ति',
    'mr': 'पाणी पुरवठा',
  };

  static const Map<String, String> foodSupply = {
    'en': 'Food Supply',
    'hi': 'भोजन आपूर्ति',
    'mr': 'अन्न पुरवठा',
  };

  static const Map<String, String> powerOutage = {
    'en': 'Power Outage',
    'hi': 'विद्युत कटौती',
    'mr': 'वीज खंडित',
  };

  static const Map<String, String> transportation = {
    'en': 'Transportation',
    'hi': 'परिवहन',
    'mr': 'परिवहन',
  };

  static const Map<String, String> medicalAssistance = {
    'en': 'Medical Assistance',
    'hi': 'चिकित्सा सहायता',
    'mr': 'वैद्यकीय मदत',
  };

  static const Map<String, String> emergencyContacts = {
    'en': 'Emergency Contacts',
    'hi': 'आपातकालीन संपर्क',
    'mr': 'आपत्कालीन संपर्क',
  };

  static const Map<String, String> stayInformed = {
    'en': 'Stay Informed',
    'hi': 'सूचित रहें',
    'mr': 'माहिती ठेवा',
  };

  static const Map<String, String> stayCalm = {
    'en': 'Stay Calm',
    'hi': 'शांत रहें',
    'mr': 'शांत रहा',
  };

  static const Map<String, String> followInstructions = {
    'en': 'Follow Instructions',
    'hi': 'निर्देशों का पालन करें',
    'mr': 'सूचनांचे पालन करा',
  };

  static const Map<String, String> seekSafety = {
    'en': 'Seek Safety',
    'hi': 'सुरक्षा की तलाश करें',
    'mr': 'सुरक्षितता शोधा',
  };

  static const Map<String, String> avoidDanger = {
    'en': 'Avoid Danger',
    'hi': 'खतरे से बचें',
    'mr': 'धोक्यापासून दूर रहा',
  };

  static const Map<String, String> reportEmergency = {
    'en': 'Report Emergency',
    'hi': 'आपातकाल की रिपोर्ट करें',
    'mr': 'आपत्कालीन परिस्थितीची तक्रार करा',
  };

  static const Map<String, String> helpOthers = {
    'en': 'Help Others',
    'hi': 'दूसरों की मदद करें',
    'mr': 'इतरांना मदत करा',
  };

  static const Map<String, String> stayTogether = {
    'en': 'Stay Together',
    'hi': 'एक साथ रहें',
    'mr': 'एकत्र रहा',
  };

  static const Map<String, String> checkForInjuries = {
    'en': 'Check for Injuries',
    'hi': 'चोटों की जांच करें',
    'mr': 'जखमांची तपासणी करा',
  };

  static const Map<String, String> documentDamage = {
    'en': 'Document Damage',
    'hi': 'नुकसान का दस्तावेजीकरण करें',
    'mr': 'नुकसानाचे दस्तऐवजीकरण करा',
  };
}