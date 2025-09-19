import 'package:flutter/material.dart';

enum SupportedLanguage {
  english('en', 'English', 'English'),
  hindi('hi', 'हिंदी', 'Hindi'),
  marathi('mr', 'मराठी', 'Marathi');

  const SupportedLanguage(this.code, this.displayName, this.englishName);
  
  final String code;
  final String displayName;
  final String englishName;
}

class LocalizationService {
  static SupportedLanguage _currentLanguage = SupportedLanguage.english;
  static final ValueNotifier<SupportedLanguage> _languageNotifier = 
      ValueNotifier(SupportedLanguage.english);

  static SupportedLanguage get currentLanguage => _currentLanguage;
  static ValueNotifier<SupportedLanguage> get languageNotifier => _languageNotifier;

  static void setLanguage(SupportedLanguage language) {
    _currentLanguage = language;
    _languageNotifier.value = language;
  }

  static String translate(Map<String, String> translations) {
    return translations[_currentLanguage.code] ?? translations['en'] ?? '';
  }

  // Common translations
  static Map<String, String> get appTitle => {
    'en': 'Disaster Safety Instructions',
    'hi': 'आपदा सुरक्षा निर्देश',
    'mr': 'आपत्ती सुरक्षा सूचना',
  };

  static Map<String, String> get staySafe => {
    'en': 'Stay Safe During Disasters',
    'hi': 'आपदाओं के दौरान सुरक्षित रहें',
    'mr': 'आपत्तींमध्ये सुरक्षित रहा',
  };

  static Map<String, String> get essentialGuidelines => {
    'en': 'Essential safety guidelines for natural disasters. Follow these instructions to protect yourself and your loved ones.',
    'hi': 'प्राकृतिक आपदाओं के लिए आवश्यक सुरक्षा दिशा-निर्देश। अपनी और अपने प्रियजनों की सुरक्षा के लिए इन निर्देशों का पालन करें।',
    'mr': 'नैसर्गिक आपत्तींसाठी आवश्यक सुरक्षा मार्गदर्शक तत्त्वे. स्वतःचे आणि आपल्या प्रियजनांचे संरक्षण करण्यासाठी या सूचनांचे पालन करा.',
  };

  static Map<String, String> get quickInstructions => {
    'en': 'Quick Instructions',
    'hi': 'त्वरित निर्देश',
    'mr': 'त्वरित सूचना',
  };

  static Map<String, String> get disasterGuides => {
    'en': 'Disaster Guides',
    'hi': 'आपदा गाइड',
    'mr': 'आपत्ती मार्गदर्शक',
  };

  static Map<String, String> get overview => {
    'en': 'Overview',
    'hi': 'अवलोकन',
    'mr': 'विहंगावलोकन',
  };

  static Map<String, String> get before => {
    'en': 'Before',
    'hi': 'पहले',
    'mr': 'आधी',
  };

  static Map<String, String> get during => {
    'en': 'During',
    'hi': 'दौरान',
    'mr': 'दरम्यान',
  };

  static Map<String, String> get after => {
    'en': 'After',
    'hi': 'बाद में',
    'mr': 'नंतर',
  };

  static Map<String, String> get dos => {
    'en': 'DO\'S',
    'hi': 'करें',
    'mr': 'करा',
  };

  static Map<String, String> get donts => {
    'en': 'DON\'TS',
    'hi': 'न करें',
    'mr': 'करू नका',
  };

  static Map<String, String> get quickGuide => {
    'en': 'Quick Guide',
    'hi': 'त्वरित गाइड',
    'mr': 'त्वरित मार्गदर्शक',
  };

  static Map<String, String> get tapToView => {
    'en': 'Tap to view safety guidelines',
    'hi': 'सुरक्षा दिशा-निर्देश देखने के लिए टैप करें',
    'mr': 'सुरक्षा मार्गदर्शक तत्त्वे पाहण्यासाठी टॅप करा',
  };

  static Map<String, String> get andMore => {
    'en': 'and',
    'hi': 'और',
    'mr': 'आणि',
  };

  static Map<String, String> get more => {
    'en': 'more',
    'hi': 'अधिक',
    'mr': 'अधिक',
  };

  static Map<String, String> get viewCompleteGuides => {
    'en': 'View Complete Guides',
    'hi': 'पूर्ण गाइड देखें',
    'mr': 'संपूर्ण मार्गदर्शक पहा',
  };

  static Map<String, String> get quickDisasterTips => {
    'en': 'Quick Disaster Tips',
    'hi': 'त्वरित आपदा सुझाव',
    'mr': 'त्वरित आपत्ती टिप्स',
  };

  static Map<String, String> get language => {
    'en': 'Language:',
    'hi': 'भाषा:',
    'mr': 'भाषा:',
  };

  // Emergency Response translations
  static Map<String, String> get emergencyResponse => {
    'en': 'Emergency Response',
    'hi': 'आपातकालीन प्रतिक्रिया',
    'mr': 'आणीबाणी प्रतिसाद',
  };

  static Map<String, String> get sosActive => {
    'en': 'ACTIVE',
    'hi': 'सक्रिय',
    'mr': 'सक्रिय',
  };

  static Map<String, String> get sos => {
    'en': 'SOS',
    'hi': 'एसओएस',
    'mr': 'एसओएस',
  };

  static Map<String, String> get sosBroadcasting => {
    'en': 'SOS signal is broadcasting your location',
    'hi': 'एसओएस सिग्नल आपका स्थान प्रसारित कर रहा है',
    'mr': 'एसओएस सिग्नल तुमचे स्थान प्रसारित करत आहे',
  };

  static Map<String, String> get sosInstruction => {
    'en': 'Tap to send emergency SOS signal',
    'hi': 'आपातकालीन एसओएस सिग्नल भेजने के लिए टैप करें',
    'mr': 'आणीबाणी एसओएस सिग्नल पाठवण्यासाठी टॅप करा',
  };

  static Map<String, String> get emergencyActions => {
    'en': 'Emergency Actions',
    'hi': 'आपातकालीन कार्य',
    'mr': 'आणीबाणी कृती',
  };

  static Map<String, String> get findShelter => {
    'en': 'Find Shelter',
    'hi': 'आश्रय खोजें',
    'mr': 'निवारा शोधा',
  };

  static Map<String, String> get findShelterDesc => {
    'en': 'Locate nearest emergency shelters with capacity info',
    'hi': 'क्षमता की जानकारी के साथ निकटतम आपातकालीन आश्रयों का पता लगाएं',
    'mr': 'क्षमतेच्या माहितीसह जवळचे आणीबाणी निवारे शोधा',
  };

  static Map<String, String> get emergencyContacts => {
    'en': 'Emergency Contacts',
    'hi': 'आपातकालीन संपर्क',
    'mr': 'आणीबाणी संपर्क',
  };

  static Map<String, String> get emergencyContactsDesc => {
    'en': 'Quick access to emergency services and personal contacts',
    'hi': 'आपातकालीन सेवाओं और व्यक्तिगत संपर्कों तक त्वरित पहुंच',
    'mr': 'आणीबाणी सेवा आणि वैयक्तिक संपर्कांमध्ये त्वरित प्रवेश',
  };

  static Map<String, String> get firstAidGuide => {
    'en': 'First Aid Guide',
    'hi': 'प्राथमिक चिकित्सा गाइड',
    'mr': 'प्राथमिक वैद्यकीय मार्गदर्शक',
  };

  static Map<String, String> get firstAidDesc => {
    'en': 'Offline medical procedures and emergency care instructions',
    'hi': 'ऑफलाइन चिकित्सा प्रक्रियाएं और आपातकालीन देखभाल निर्देश',
    'mr': 'ऑफलाइन वैद्यकीय प्रक्रिया आणि आणीबाणी काळजी सूचना',
  };

  static Map<String, String> get safetyInstructions => {
    'en': 'Safety Instructions',
    'hi': 'सुरक्षा निर्देश',
    'mr': 'सुरक्षा सूचना',
  };

  static Map<String, String> get safetyInstructionsDesc => {
    'en': 'Disaster safety guides and quick emergency checklists',
    'hi': 'आपदा सुरक्षा गाइड और त्वरित आपातकालीन चेकलिस्ट',
    'mr': 'आपत्ती सुरक्षा मार्गदर्शक आणि त्वरित आणीबाणी तपासणी यादी',
  };

  static Map<String, String> get emergencyGuides => {
    'en': 'Emergency Guides',
    'hi': 'आपातकालीन गाइड',
    'mr': 'आणीबाणी मार्गदर्शक',
  };

  static Map<String, String> get emergencyGuidesDesc => {
    'en': 'Multilingual safety guides for natural disasters',
    'hi': 'प्राकृतिक आपदाओं के लिए बहुभाषी सुरक्षा गाइड',
    'mr': 'नैसर्गिक आपत्तींसाठी बहुभाषिक सुरक्षा मार्गदर्शक',
  };

  static Map<String, String> get emergencyDialogTitle => {
    'en': 'Emergency Shelters',
    'hi': 'आपातकालीन आश्रय',
    'mr': 'आणीबाणी निवारे',
  };

  static Map<String, String> get noSheltersFound => {
    'en': 'No shelters found',
    'hi': 'कोई आश्रय नहीं मिला',
    'mr': 'कोणतेही निवारे सापडले नाहीत',
  };

  static Map<String, String> get enableLocationForBetter => {
    'en': 'Enable location for better results',
    'hi': 'बेहतर परिणामों के लिए स्थान सक्षम करें',
    'mr': 'चांगल्या परिणामांसाठी स्थान सक्षम करा',
  };

  static Map<String, String> get navigate => {
    'en': 'Navigate',
    'hi': 'नेविगेट करें',
    'mr': 'मार्गदर्शन करा',
  };

  static Map<String, String> get call => {
    'en': 'Call',
    'hi': 'कॉल करें',
    'mr': 'कॉल करा',
  };

  static Map<String, String> get advancedOptions => {
    'en': 'Advanced Options',
    'hi': 'उन्नत विकल्प',
    'mr': 'प्रगत पर्याय',
  };

  static Map<String, String> get interactiveMap => {
    'en': 'Interactive Map',
    'hi': 'इंटरैक्टिव मैप',
    'mr': 'परस्परसंवादी नकाशा',
  };

  static Map<String, String> get interactiveMapDesc => {
    'en': 'View disaster zones and evacuation routes',
    'hi': 'आपदा क्षेत्रों और निकासी मार्गों को देखें',
    'mr': 'आपत्ती क्षेत्रे आणि निर्गमन मार्ग पहा',
  };

  static Map<String, String> get reportIncident => {
    'en': 'Report Incident',
    'hi': 'घटना की रिपोर्ट करें',
    'mr': 'घटना नोंदवा',
  };

  static Map<String, String> get reportIncidentDesc => {
    'en': 'Report emergency situations or resource needs',
    'hi': 'आपातकालीन स्थितियों या संसाधन आवश्यकताओं की रिपोर्ट करें',
    'mr': 'आणीबाणी परिस्थिती किंवा संसाधन गरजांची तक्रार करा',
  };

  static Map<String, String> get resourceSharing => {
    'en': 'Resource Sharing',
    'hi': 'संसाधन साझाकरण',
    'mr': 'संसाधन सामायिकरण',
  };

  static Map<String, String> get resourceSharingDesc => {
    'en': 'Share or request emergency resources with community',
    'hi': 'समुदाय के साथ आपातकालीन संसाधन साझा करें या अनुरोध करें',
    'mr': 'समुदायासह आणीबाणी संसाधने सामायिक करा किंवा विनंती करा',
  };

  static Map<String, String> get evacuationPlan => {
    'en': 'Evacuation Plan',
    'hi': 'निकासी योजना',
    'mr': 'निर्गमन योजना',
  };

  static Map<String, String> get evacuationPlanDesc => {
    'en': 'Create and manage personalized evacuation plans',
    'hi': 'व्यक्तिगत निकासी योजना बनाएं और प्रबंधित करें',
    'mr': 'वैयक्तिक निर्गमन योजना तयार करा आणि व्यवस्थापित करा',
  };

  static Map<String, String> get returnToDashboard => {
    'en': 'Return to Dashboard',
    'hi': 'डैशबोर्ड पर वापस जाएं',
    'mr': 'डॅशबोर्डवर परत जा',
  };

  static Map<String, String> get returnToDashboardDesc => {
    'en': 'Go back to main emergency dashboard',
    'hi': 'मुख्य आपातकालीन डैशबोर्ड पर वापस जाएं',
    'mr': 'मुख्य आणीबाणी डॅशबोर्डवर परत जा',
  };
}