import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';

class DisasterPreparednessScreen extends StatefulWidget {
  const DisasterPreparednessScreen({super.key});

  @override
  State<DisasterPreparednessScreen> createState() => _DisasterPreparednessScreenState();
}

class _DisasterPreparednessScreenState extends State<DisasterPreparednessScreen> {
  String selectedLanguage = 'English';
  final List<String> languages = ['English', 'हिंदी (Hindi)', 'मराठी (Marathi)'];
  
  final Map<String, Map<String, dynamic>> disasterContent = {
    'floods': {
      'title': {
        'English': 'Floods',
        'हिंदी (Hindi)': 'बाढ़',
        'मराठी (Marathi)': 'पूर'
      },
      'icon': 'water_drop',
      'color': Colors.blue,
      'before': {
        'English': [
          'Stay informed about flood warnings in your area',
          'Prepare an emergency kit with food, water, and medicines',
          'Keep important documents in waterproof containers',
          'Know evacuation routes and higher ground locations',
          'Store drinking water (1 gallon per person per day)',
          'Charge electronic devices and keep backup batteries',
        ],
        'हिंदी (Hindi)': [
          'अपने क्षेत्र में बाढ़ की चेतावनी के बारे में जानकारी रखें',
          'भोजन, पानी और दवाओं के साथ आपातकालीन किट तैयार करें',
          'महत्वपूर्ण दस्तावेजों को वाटरप्रूफ कंटेनरों में रखें',
          'निकासी मार्गों और ऊंचे स्थानों को जानें',
          'पीने का पानी स्टोर करें (प्रति व्यक्ति प्रति दिन 1 गैलन)',
          'इलेक्ट्रॉनिक डिवाइस चार्ज करें और बैकअप बैटरी रखें',
        ],
        'मराठी (Marathi)': [
          'तुमच्या भागात पुराच्या चेतावणीबद्दल माहिती ठेवा',
          'अन्न, पाणी आणि औषधांसह आणीबाणीची किट तयार करा',
          'महत्त्वाच्या कागदपत्रांना वॉटरप्रूफ कंटेनरमध्ये ठेवा',
          'निर्गमन मार्ग आणि उंच जमिनीचे स्थान जाणून घ्या',
          'पिण्याचे पाणी साठवा (प्रति व्यक्ती दिवसाला १ गॅलन)',
          'इलेक्ट्रॉनिक उपकरणे चार्ज करा आणि बॅकअप बॅटरी ठेवा',
        ]
      },
      'during': {
        'English': [
          'Move to higher ground immediately if advised to evacuate',
          'Never walk or drive through flood water',
          'Stay away from downed electrical lines',
          'Listen to emergency broadcasts for updates',
          'If trapped, signal for help from the highest point',
          'Avoid drinking flood water or using it for cooking',
        ],
        'हिंदी (Hindi)': [
          'यदि निकासी की सलाह दी जाए तो तुरंत ऊंचे स्थान पर जाएं',
          'कभी भी बाढ़ के पानी में न चलें या गाड़ी न चलाएं',
          'गिरी हुई बिजली की लाइनों से दूर रहें',
          'अपडेट के लिए आपातकालीन प्रसारण सुनें',
          'यदि फंस गए हैं, तो सबसे ऊंचे स्थान से मदद का संकेत दें',
          'बाढ़ का पानी पीने या खाना बनाने के लिए उपयोग न करें',
        ],
        'मराठी (Marathi)': [
          'स्थलांतराची सल्लागार दिली असल्यास तात्काळ उंच जमिनीवर जा',
          'पुराच्या पाण्यातून कधीही चालू नका किंवा गाडी चालवू नका',
          'पडलेल्या विद्युत तारांपासून दूर राहा',
          'अपडेटसाठी आणीबाणी प्रसारण ऐका',
          'अडकल्यास, सर्वात उंच जागेवरून मदतीसाठी इशारा द्या',
          'पुराचे पाणी पिऊ नका किंवा स्वयंपाकासाठी वापरू नका',
        ]
      },
      'after': {
        'English': [
          'Wait for authorities to declare it safe before returning',
          'Check for structural damage before entering buildings',
          'Use flashlights, not candles, for lighting',
          'Boil water before drinking if water supply is compromised',
          'Take photos of damage for insurance claims',
          'Be aware of contaminated flood water and mud',
        ],
        'हिंदी (Hindi)': [
          'वापस जाने से पहले अधिकारियों द्वारा सुरक्षित घोषित करने का इंतजार करें',
          'इमारतों में प्रवेश करने से पहले संरचनात्मक क्षति की जांच करें',
          'प्रकाश के लिए मोमबत्तियों का नहीं, फ्लैशलाइट का उपयोग करें',
          'यदि पानी की आपूर्ति में समस्या है तो पीने से पहले पानी उबालें',
          'बीमा दावों के लिए नुकसान की तस्वीरें लें',
          'दूषित बाढ़ के पानी और कीचड़ से सावधान रहें',
        ],
        'मराठी (Marathi)': [
          'परत जाण्यापूर्वी अधिकाऱ्यांनी सुरक्षित घोषित करण्याची प्रतीक्षा करा',
          'इमारतींमध्ये प्रवेश करण्यापूर्वी संरचनात्मक नुकसानाची तपासणी करा',
          'प्रकाशासाठी मेणबत्त्या नव्हे तर फ्लॅशलाइट वापरा',
          'पाणी पुरवठा बिघडला असल्यास पिण्यापूर्वी पाणी उकळवा',
          'विमा दाव्यांसाठी नुकसानाचे फोटो काढा',
          'दूषित पुराचे पाणी आणि चिखलापासून सावध राहा',
        ]
      }
    },
    'earthquakes': {
      'title': {
        'English': 'Earthquakes',
        'हिंदी (Hindi)': 'भूकंप',
        'मराठी (Marathi)': 'भूकंप'
      },
      'icon': 'warning',
      'color': Colors.orange,
      'before': {
        'English': [
          'Secure heavy furniture and appliances to walls',
          'Identify safe spots in each room (under sturdy tables)',
          'Create an emergency plan with family members',
          'Keep emergency supplies in accessible locations',
          'Learn how to turn off gas, water, and electricity',
          'Practice "Drop, Cover, and Hold On" drills',
        ],
        'हिंदी (Hindi)': [
          'भारी फर्नीचर और उपकरणों को दीवारों से सुरक्षित करें',
          'हर कमरे में सुरक्षित स्थान पहचानें (मजबूत टेबल के नीचे)',
          'परिवार के सदस्यों के साथ आपातकालीन योजना बनाएं',
          'आपातकालीन आपूर्ति को पहुंच योग्य स्थानों में रखें',
          'गैस, पानी और बिजली बंद करना सीखें',
          '"गिरना, छुपना और पकड़ना" की ड्रिल का अभ्यास करें',
        ],
        'मराठी (Marathi)': [
          'जड फर्निचर आणि उपकरणे भिंतींना सुरक्षित करा',
          'प्रत्येक खोलीत सुरक्षित जागा ओळखा (भक्कम टेबलांखाली)',
          'कुटुंबातील सदस्यांसह आणीबाणीची योजना तयार करा',
          'आणीबाणीचा पुरवठा प्रवेशयोग्य ठिकाणी ठेवा',
          'गॅस, पाणी आणि वीज कशी बंद करावी ते शिका',
          '"खाली पडणे, झाकणे आणि धरणे" सरावाचा अभ्यास करा',
        ]
      },
      'during': {
        'English': [
          'Drop to hands and knees immediately',
          'Take cover under a sturdy desk or table',
          'Hold on to your shelter and protect your head',
          'Stay away from windows, mirrors, and tall furniture',
          'If outdoors, move away from buildings and power lines',
          'If in a car, pull over and stay inside',
        ],
        'हिंदी (Hindi)': [
          'तुरंत हाथों और घुटनों के बल गिर जाएं',
          'मजबूत डेस्क या टेबल के नीचे छुप जाएं',
          'अपने आश्रय को पकड़ें और अपने सिर की रक्षा करें',
          'खिड़कियों, दर्पणों और लंबे फर्नीचर से दूर रहें',
          'यदि बाहर हैं, तो इमारतों और बिजली की लाइनों से दूर चले जाएं',
          'यदि कार में हैं, तो गाड़ी रोकें और अंदर ही रहें',
        ],
        'मराठी (Marathi)': [
          'तात्काळ हात आणि गुडघ्यांवर पडा',
          'भक्कम डेस्क किंवा टेबलाखाली आश्रय घ्या',
          'तुमच्या आश्रयाला धरून राहा आणि डोक्याचे संरक्षण करा',
          'खिडक्या, आरसे आणि उंच फर्निचरपासून दूर राहा',
          'बाहेर असल्यास, इमारती आणि वीज तारांपासून दूर जा',
          'कारमध्ये असल्यास, कार थांबवा आणि आतच राहा',
        ]
      },
      'after': {
        'English': [
          'Check for injuries and provide first aid if needed',
          'Inspect your home for damage before re-entering',
          'Be prepared for aftershocks',
          'Check gas lines for leaks and turn off if damaged',
          'Use stairs, not elevators',
          'Stay away from damaged buildings and structures',
        ],
        'हिंदी (Hindi)': [
          'चोटों की जांच करें और यदि आवश्यक हो तो प्राथमिक चिकित्सा प्रदान करें',
          'फिर से प्रवेश करने से पहले अपने घर की क्षति का निरीक्षण करें',
          'आफ्टरशॉक के लिए तैयार रहें',
          'गैस लाइनों में रिसाव की जांच करें और क्षतिग्रस्त होने पर बंद करें',
          'लिफ्ट का नहीं, सीढ़ियों का उपयोग करें',
          'क्षतिग्रस्त इमारतों और संरचनाओं से दूर रहें',
        ],
        'मराठी (Marathi)': [
          'जखमांची तपासणी करा आणि आवश्यकतेनुसार प्राथमिक उपचार द्या',
          'पुन्हा प्रवेश करण्यापूर्वी तुमच्या घराच्या नुकसानाची तपासणी करा',
          'उत्तरकंपनांसाठी तयार राहा',
          'गॅस लाइन्समध्ये गळती तपासा आणि नुकसान झाल्यास बंद करा',
          'लिफ्ट नव्हे तर पायऱ्या वापरा',
          'नुकसान झालेल्या इमारती आणि संरचनांपासून दूर राहा',
        ]
      }
    },
    'cyclones': {
      'title': {
        'English': 'Cyclones/Hurricanes',
        'हिंदी (Hindi)': 'चक्रवात/तूफान',
        'मराठी (Marathi)': 'चक्रीवादळ/वादळ'
      },
      'icon': 'air',
      'color': Colors.grey,
      'before': {
        'English': [
          'Monitor weather reports and evacuation orders',
          'Secure or bring in outdoor furniture and objects',
          'Board up windows with plywood if possible',
          'Stock up on water, non-perishable food, and batteries',
          'Fill bathtubs and containers with water',
          'Charge all electronic devices',
        ],
        'हिंदी (Hindi)': [
          'मौसम रिपोर्ट और निकासी आदेशों पर नजर रखें',
          'बाहरी फर्नीचर और वस्तुओं को सुरक्षित करें या अंदर ले आएं',
          'यदि संभव हो तो खिड़कियों को प्लाईवुड से बंद करें',
          'पानी, गैर-खराब होने वाले भोजन और बैटरी का स्टॉक करें',
          'बाथटब और कंटेनरों को पानी से भरें',
          'सभी इलेक्ट्रॉनिक उपकरणों को चार्ज करें',
        ],
        'मराठी (Marathi)': [
          'हवामान अहवाल आणि स्थलांतर आदेशांचे निरीक्षण करा',
          'बाहेरील फर्निचर आणि वस्तू सुरक्षित करा किंवा आत आणा',
          'शक्य असल्यास खिडक्या प्लायवुडने बंद करा',
          'पाणी, न खराब होणारे अन्न आणि बॅटरीचा साठा करा',
          'बाथटब आणि कंटेनर पाण्याने भरा',
          'सर्व इलेक्ट्रॉनिक उपकरणे चार्ज करा',
        ]
      },
      'during': {
        'English': [
          'Stay indoors and away from windows',
          'Go to the lowest floor and interior rooms',
          'Listen to emergency broadcasts for updates',
          'Do not go outside during the eye of the storm',
          'Avoid using electrical appliances',
          'Stay away from flood water',
        ],
        'हिंदी (Hindi)': [
          'घर के अंदर रहें और खिड़कियों से दूर रहें',
          'सबसे निचली मंजिल और अंदरूनी कमरों में जाएं',
          'अपडेट के लिए आपातकालीन प्रसारण सुनें',
          'तूफान की आंख के दौरान बाहर न जाएं',
          'बिजली के उपकरणों का उपयोग न करें',
          'बाढ़ के पानी से दूर रहें',
        ],
        'मराठी (Marathi)': [
          'घरात राहा आणि खिडक्यांपासून दूर राहा',
          'सर्वात खालच्या मजल्यावर आणि आतील खोल्यांमध्ये जा',
          'अपडेटसाठी आणीबाणी प्रसारण ऐका',
          'वादळाच्या डोळ्यादरम्यान बाहेर जाऊ नका',
          'विद्युत उपकरणे वापरणे टाळा',
          'पुराच्या पाण्यापासून दूर राहा',
        ]
      },
      'after': {
        'English': [
          'Wait for authorities to declare all-clear',
          'Be cautious of downed power lines and debris',
          'Check for gas leaks and turn off utilities if damaged',
          'Document damage with photos for insurance',
          'Avoid driving through flood water',
          'Be aware of potentially contaminated flood water',
        ],
        'हिंदी (Hindi)': [
          'अधिकारियों द्वारा सब ठीक घोषित करने का इंतजार करें',
          'गिरी हुई बिजली की लाइनों और मलबे से सावधान रहें',
          'गैस रिसाव की जांच करें और क्षतिग्रस्त होने पर उपयोगिताओं को बंद करें',
          'बीमा के लिए फोटो के साथ नुकसान का दस्तावेजीकरण करें',
          'बाढ़ के पानी से गाड़ी चलाने से बचें',
          'संभावित दूषित बाढ़ के पानी से सावधान रहें',
        ],
        'मराठी (Marathi)': [
          'अधिकाऱ्यांनी सर्व-स्पष्ट घोषित करण्याची प्रतीक्षा करा',
          'पडलेल्या वीज तारा आणि ढिगाऱ्यांपासून सावध राहा',
          'गॅस गळतीची तपासणी करा आणि नुकसान झाल्यास उपयोगिता बंद करा',
          'विम्यासाठी फोटोंसह नुकसानाचे दस्तऐवजीकरण करा',
          'पुराच्या पाण्यातून गाडी चालवणे टाळा',
          'संभाव्य दूषित पुराच्या पाण्याची जाणीव ठेवा',
        ]
      }
    },
    'forest_fires': {
      'title': {
        'English': 'Forest Fires',
        'हिंदी (Hindi)': 'जंगलों की आग',
        'मराठी (Marathi)': 'वनाग्नी'
      },
      'icon': 'local_fire_department',
      'color': Colors.red,
      'before': {
        'English': [
          'Create a defensible space around your home',
          'Clear dry vegetation and debris from property',
          'Install fire-resistant roofing and siding',
          'Prepare emergency evacuation plans and routes',
          'Keep important documents in a ready-to-go bag',
          'Sign up for emergency alerts in your area',
        ],
        'हिंदी (Hindi)': [
          'अपने घर के चारों ओर एक रक्षात्मक स्थान बनाएं',
          'संपत्ति से सूखी वनस्पति और मलबे को साफ करें',
          'आग प्रतिरोधी छत और साइडिंग स्थापित करें',
          'आपातकालीन निकासी योजनाएं और मार्ग तैयार करें',
          'महत्वपूर्ण दस्तावेजों को तैयार बैग में रखें',
          'अपने क्षेत्र में आपातकालीन अलर्ट के लिए साइन अप करें',
        ],
        'मराठी (Marathi)': [
          'तुमच्या घराभोवती बचावात्मक जागा तयार करा',
          'मालमत्तेतून कोरडी वनस्पती आणि ढिगारा साफ करा',
          'अग्निरोधक छप्पर आणि साइडिंग बसवा',
          'आणीबाणीच्या निर्गमन योजना आणि मार्ग तयार करा',
          'महत्त्वाच्या कागदपत्रांना तयार बॅगमध्ये ठेवा',
          'तुमच्या भागातील आणीबाणी अलर्टसाठी साइन अप करा',
        ]
      },
      'during': {
        'English': [
          'Evacuate immediately if ordered by authorities',
          'If trapped, call 911 and signal for help',
          'Close all windows, doors, and vents',
          'Move away from the fire if possible',
          'Stay low to avoid smoke inhalation',
          'Cover nose and mouth with damp cloth',
        ],
        'हिंदी (Hindi)': [
          'यदि अधिकारियों द्वारा आदेश दिया गया हो तो तुरंत निकल जाएं',
          'यदि फंस गए हैं, तो 911 कॉल करें और मदद का संकेत दें',
          'सभी खिड़कियां, दरवाजे और वेंट बंद करें',
          'यदि संभव हो तो आग से दूर हट जाएं',
          'धुएं से बचने के लिए नीचे रहें',
          'नाक और मुंह को गीले कपड़े से ढकें',
        ],
        'मराठी (Marathi)': [
          'अधिकाऱ्यांनी आदेश दिला असल्यास तात्काळ स्थलांतर करा',
          'अडकल्यास, 911 वर कॉल करा आणि मदतीसाठी इशारा द्या',
          'सर्व खिडक्या, दरवाजे आणि व्हेंट बंद करा',
          'शक्य असल्यास आगीपासून दूर जा',
          'धुराचे इनहेलेशन टाळण्यासाठी खाली राहा',
          'नाक आणि तोंड ओल्या कापडाने झाकून ठेवा',
        ]
      },
      'after': {
        'English': [
          'Wait for officials to declare it safe to return',
          'Watch for hot spots and smoldering debris',
          'Check for structural damage before entering',
          'Be cautious of ash and debris when cleaning',
          'Document damage for insurance claims',
          'Stay hydrated and wear protective equipment',
        ],
        'हिंदी (Hindi)': [
          'अधिकारियों द्वारा वापस आना सुरक्षित घोषित करने का इंतजार करें',
          'गर्म स्थानों और धुएं वाले मलबे पर नजर रखें',
          'प्रवेश करने से पहले संरचनात्मक क्षति की जांच करें',
          'सफाई करते समय राख और मलबे से सावधान रहें',
          'बीमा दावों के लिए नुकसान का दस्तावेजीकरण करें',
          'हाइड्रेटेड रहें और सुरक्षात्मक उपकरण पहनें',
        ],
        'मराठी (Marathi)': [
          'अधिकाऱ्यांनी परत येणे सुरक्षित घोषित करण्याची प्रतीक्षा करा',
          'गरम जागा आणि धुमसणाऱ्या ढिगाऱ्यांवर लक्ष ठेवा',
          'प्रवेश करण्यापूर्वी संरचनात्मक नुकसानाची तपासणी करा',
          'साफसफाई करताना राख आणि ढिगाऱ्यांपासून सावध राहा',
          'विमा दाव्यांसाठी नुकसानाचे दस्तऐवजीकरण करा',
          'हायड्रेटेड राहा आणि संरक्षणात्मक उपकरणे घाला',
        ]
      }
    },
    'landslides': {
      'title': {
        'English': 'Landslides',
        'हिंदी (Hindi)': 'भूस्खलन',
        'मराठी (Marathi)': 'भूस्खलन'
      },
      'icon': 'landscape',
      'color': Colors.brown,
      'before': {
        'English': [
          'Know the landslide warning signs in your area',
          'Develop evacuation plans and alternate routes',
          'Plant ground cover on slopes to reduce erosion',
          'Install flexible pipe fittings to avoid gas or water leaks',
          'Consider professional inspection for slope stability',
          'Keep emergency supplies easily accessible',
        ],
        'हिंदी (Hindi)': [
          'अपने क्षेत्र में भूस्खलन की चेतावनी के संकेतों को जानें',
          'निकासी योजनाएं और वैकल्पिक मार्ग विकसित करें',
          'कटाव को कम करने के लिए ढलानों पर भूमि आवरण लगाएं',
          'गैस या पानी के रिसाव से बचने के लिए लचीली पाइप फिटिंग स्थापित करें',
          'ढलान स्थिरता के लिए पेशेवर निरीक्षण पर विचार करें',
          'आपातकालीन आपूर्ति को आसानी से सुलभ रखें',
        ],
        'मराठी (Marathi)': [
          'तुमच्या भागातील भूस्खलनाच्या चेतावणी चिन्हांना जाणून घ्या',
          'निर्गमन योजना आणि पर्यायी मार्ग विकसित करा',
          'धूप कमी करण्यासाठी उतारांवर भूमी आवरण लावा',
          'गॅस किंवा पाणी गळती टाळण्यासाठी लवचिक पाईप फिटिंग बसवा',
          'उतार स्थिरतेसाठी व्यावसायिक तपासणीचा विचार करा',
          'आणीबाणीचा पुरवठा सहज उपलब्ध ठेवा',
        ]
      },
      'during': {
        'English': [
          'Listen for unusual sounds that might indicate moving debris',
          'Move away from the path of a landslide as quickly as possible',
          'If escape is not possible, curl into a tight ball',
          'Protect your head and stay alert for falling rocks',
          'Avoid river valleys and low-lying areas',
          'Stay away from the landslide area',
        ],
        'हिंदी (Hindi)': [
          'असामान्य आवाजों को सुनें जो चलते मलबे का संकेत दे सकती हैं',
          'भूस्खलन के पथ से जितनी जल्दी हो सके दूर हट जाएं',
          'यदि बचना संभव नहीं है, तो कसकर गेंद की तरह सिकुड़ जाएं',
          'अपने सिर की रक्षा करें और गिरते पत्थरों के लिए सतर्क रहें',
          'नदी घाटियों और निचले क्षेत्रों से बचें',
          'भूस्खलन क्षेत्र से दूर रहें',
        ],
        'मराठी (Marathi)': [
          'हलणारे ढिगारे दर्शविणारे असामान्य आवाज ऐका',
          'भूस्खलनाच्या मार्गापासून शक्य तितक्या लवकर दूर जा',
          'सुटका शक्य नसल्यास, घट्ट बॉलप्रमाणे वळवळा',
          'तुमच्या डोक्याचे संरक्षण करा आणि पडणाऱ्या खडकांसाठी सावध राहा',
          'नदी खोऱ्या आणि सखल भागांपासून दूर राहा',
          'भूस्खलन क्षेत्रापासून दूर राहा',
        ]
      },
      'after': {
        'English': [
          'Stay away from the slide area - more slides may occur',
          'Check for injured and trapped persons near the slide',
          'Listen to local radio for emergency information',
          'Watch for flooding which may occur after a landslide',
          'Report broken utility lines to authorities',
          'Have a professional check your property for structural damage',
        ],
        'हिंदी (Hindi)': [
          'स्लाइड क्षेत्र से दूर रहें - और स्लाइड हो सकती हैं',
          'स्लाइड के पास घायल और फंसे हुए व्यक्तियों की जांच करें',
          'आपातकालीन जानकारी के लिए स्थानीय रेडियो सुनें',
          'भूस्खलन के बाद हो सकने वाली बाढ़ पर नजर रखें',
          'टूटी हुई उपयोगिता लाइनों की रिपोर्ट अधिकारियों को करें',
          'संरचनात्मक क्षति के लिए अपनी संपत्ति की पेशेवर जांच कराएं',
        ],
        'मराठी (Marathi)': [
          'स्लाइड क्षेत्रापासून दूर राहा - अधिक स्लाइड होऊ शकतात',
          'स्लाइडजवळ जखमी आणि अडकलेल्या व्यक्तींची तपासणी करा',
          'आणीबाणीच्या माहितीसाठी स्थानिक रेडिओ ऐका',
          'भूस्खलनानंतर होऊ शकणाऱ्या पुरांवर लक्ष ठेवा',
          'तुटलेल्या उपयोगिता लाईन्सची तक्रार अधिकाऱ्यांना करा',
          'संरचनात्मक नुकसानासाठी तुमच्या मालमत्तेची व्यावसायिक तपासणी करा',
        ]
      }
    }
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          _getLocalizedText('title'),
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Language Selector
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            margin: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLocalizedText('select_language'),
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                DropdownButtonFormField<String>(
                  value: selectedLanguage,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  ),
                  items: languages.map((String language) {
                    return DropdownMenuItem<String>(
                      value: language,
                      child: Text(language),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedLanguage = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Disaster Types Grid
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 2.h,
                childAspectRatio: 1.1,
                children: disasterContent.entries.map((entry) {
                  final disaster = entry.value;
                  return _buildDisasterCard(
                    entry.key,
                    disaster['title'][selectedLanguage] ?? disaster['title']['English']!,
                    disaster['icon'],
                    disaster['color'],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisasterCard(String disasterKey, String title, String iconName, Color color) {
    return GestureDetector(
      onTap: () => _showDisasterDetails(disasterKey),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outlineLight),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: color,
              size: 12.w,
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDisasterDetails(String disasterKey) {
    final disaster = disasterContent[disasterKey]!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 85.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.outlineLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: disaster['icon'],
                    color: disaster['color'],
                    size: 8.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      disaster['title'][selectedLanguage] ?? disaster['title']['English']!,
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 2.h),
            
            // Content tabs
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: AppTheme.lightTheme.primaryColor,
                      unselectedLabelColor: AppTheme.textMediumEmphasisLight,
                      tabs: [
                        Tab(text: _getLocalizedText('before')),
                        Tab(text: _getLocalizedText('during')),
                        Tab(text: _getLocalizedText('after')),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildInstructionsList(disaster['before'][selectedLanguage] ?? disaster['before']['English']!),
                          _buildInstructionsList(disaster['during'][selectedLanguage] ?? disaster['during']['English']!),
                          _buildInstructionsList(disaster['after'][selectedLanguage] ?? disaster['after']['English']!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsList(List<String> instructions) {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: instructions.length,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.outlineLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  instructions[index],
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getLocalizedText(String key) {
    final Map<String, Map<String, String>> localizedTexts = {
      'title': {
        'English': 'Disaster Preparedness',
        'हिंदी (Hindi)': 'आपदा तैयारी',
        'मराठी (Marathi)': 'आपत्ती तयारी'
      },
      'select_language': {
        'English': 'Select Language',
        'हिंदी (Hindi)': 'भाषा चुनें',
        'मराठी (Marathi)': 'भाषा निवडा'
      },
      'before': {
        'English': 'Before',
        'हिंदी (Hindi)': 'पहले',
        'मराठी (Marathi)': 'आधी'
      },
      'during': {
        'English': 'During',
        'हिंदी (Hindi)': 'दौरान',
        'मराठी (Marathi)': 'दरम्यान'
      },
      'after': {
        'English': 'After',
        'हिंदी (Hindi)': 'बाद में',
        'मराठी (Marathi)': 'नंतर'
      }
    };
    
    return localizedTexts[key]?[selectedLanguage] ?? localizedTexts[key]?['English'] ?? key;
  }
}