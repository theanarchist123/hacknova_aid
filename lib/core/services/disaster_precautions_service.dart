/// Comprehensive disaster precautions in multiple languages
class DisasterPrecautionsService {

  /// Get detailed precautions for a specific disaster type in the target language
  static List<String> getPrecautions(String disasterType, String languageCode) {
    final precautions = _precautionsDatabase[disasterType.toLowerCase()];
    if (precautions == null) return [];
    
    return precautions[languageCode] ?? precautions['en'] ?? [];
  }

  /// Database of precautions for each disaster type in multiple languages
  static const Map<String, Map<String, List<String>>> _precautionsDatabase = {
    'earthquake': {
      'en': [
        'Drop, Cover, and Hold On immediately when shaking starts',
        'Stay away from windows, mirrors, and heavy objects that could fall',
        'If outdoors, move away from buildings, power lines, and trees',
        'If in a vehicle, pull over safely and stay inside until shaking stops',
        'After earthquake: Check for injuries and provide first aid',
        'Inspect your home for damage, gas leaks, and electrical issues',
        'Be prepared for aftershocks - they can be as strong as the main quake',
        'Keep emergency supplies: water, food, flashlight, radio, first aid kit',
        'Have an emergency communication plan with your family',
        'Stay informed through official emergency broadcasts'
      ],
      'hi': [
        'हिलने पर तुरंत झुकें, छुपें और पकड़ें',
        'खिड़कियों, शीशों और गिर सकने वाली भारी वस्तुओं से दूर रहें',
        'यदि बाहर हैं तो इमारतों, बिजली की लाइनों और पेड़ों से दूर चले जाएं',
        'वाहन में हैं तो सुरक्षित रूप से रोकें और हिलना बंद होने तक अंदर रहें',
        'भूकंप के बाद: चोटों की जांच करें और प्राथमिक चिकित्सा प्रदान करें',
        'घर में नुकसान, गैस लीक और बिजली की समस्याओं की जांच करें',
        'आफ्टरशॉक के लिए तैयार रहें - ये मुख्य भूकंप जितने तेज़ हो सकते हैं',
        'आपातकालीन सामग्री रखें: पानी, भोजन, टॉर्च, रेडियो, प्राथमिक चिकित्सा किट',
        'अपने परिवार के साथ आपातकालीन संचार योजना बनाएं',
        'आधिकारिक आपातकालीन प्रसारण के माध्यम से जानकारी रखें'
      ],
      'mr': [
        'हादरे सुरू झाल्यावर लगेच खाली पडा, लपवा आणि धरून रहा',
        'खिडक्या, आरसे आणि पडू शकतील अशा जड वस्तूंपासून दूर रहा',
        'बाहेर असाल तर इमारती, वीज तारा आणि झाडांपासून दूर जा',
        'वाहनात असाल तर सुरक्षितपणे थांबवा आणि हादरणे थांबेपर्यंत आत रहा',
        'भूकंपानंतर: जखमांची तपासणी करा आणि प्राथमिक उपचार द्या',
        'घरात नुकसान, गॅस गळती आणि वीज समस्यांची तपासणी करा',
        'आफ्टरशॉकसाठी तयार रहा - ते मुख्य भूकंपाइतके जोरदार असू शकतात',
        'आणीबाणीचे साहित्य ठेवा: पाणी, अन्न, टॉर्च, रेडिओ, प्राथमिक उपचार किट',
        'आपल्या कुटुंबासह आणीबाणीची संपर्क योजना तयार करा',
        'अधिकृत आणीबाणी प्रसारणाद्वारे माहिती मिळवत रहा'
      ],
      'gu': [
        'હલવા શરૂ થાય તો તરત જ નીચે, આવરણ અને પકડી રાખો',
        'બારીઓ, અરીસાઓ અને પડી શકે તેવી ભારે વસ્તુઓથી દૂર રહો',
        'બહાર હોવ તો ઇમારતો, વીજ લાઈનો અને વૃક્ષોથી દૂર જાઓ',
        'વાહનમાં હોવ તો સુરક્ષિત રીતે રોકો અને હલવું બંધ થાય ત્યાં સુધી અંદર રહો',
        'ભૂકંપ પછી: ઈજાઓ તપાસો અને પ્રાથમિક સારવાર આપો',
        'ઘરમાં નુકસાન, ગેસ લીક અને વીજળીની સમસ્યાઓ તપાસો',
        'આફ્ટરશોક માટે તૈયાર રહો - તે મુખ્ય ભૂકંપ જેટલા મજબૂત હોઈ શકે છે',
        'કટોકટીનો સામાન રાખો: પાણી, ખોરાક, ટોર્ચ, રેડિયો, પ્રાથમિક સારવાર કિટ',
        'તમારા પરિવાર સાથે કટોકટીની સંચાર યોજના બનાવો',
        'સત્તાવાર કટોકટીના પ્રસારણ દ્વારા માહિતી મેળવતા રહો'
      ],
    },
    
    'flood': {
      'en': [
        'Move to higher ground immediately if flooding is imminent',
        'Never drive through flooded roads - Turn Around, Don\'t Drown',
        'Avoid walking in moving water - 6 inches can knock you down',
        'If trapped in building, go to highest floor, not the attic',
        'Signal for help from rooftop or upper windows',
        'Stay away from electrical lines and equipment',
        'Do not drink floodwater - use bottled or boiled water only',
        'Keep emergency supplies in waterproof containers',
        'Have evacuation plan and emergency meeting point',
        'Listen to emergency broadcasts for evacuation orders'
      ],
      'hi': [
        'बाढ़ आसन्न हो तो तुरंत ऊंची जगह पर जाएं',
        'बाढ़ वाली सड़कों पर कभी न चलाएं - वापस मुड़ें, डूबें नहीं',
        'बहते पानी में चलने से बचें - 6 इंच पानी आपको गिरा सकता है',
        'इमारत में फंसे हों तो सबसे ऊपरी मंजिल पर जाएं, अटारी में नहीं',
        'छत या ऊपरी खिड़कियों से मदद के लिए इशारा करें',
        'बिजली की लाइनों और उपकरणों से दूर रहें',
        'बाढ़ का पानी न पिएं - केवल बोतलबंद या उबला पानी इस्तेमाल करें',
        'आपातकालीन सामग्री को जलरोधी कंटेनर में रखें',
        'निकासी योजना और आपातकालीन मिलने का स्थान तय करें',
        'निकासी आदेशों के लिए आपातकालीन प्रसारण सुनें'
      ],
      'mr': [
        'पूर येण्याची शक्यता असेल तर लगेच उंच जागी जा',
        'पुराच्या रस्त्यावर कधीही वाहन चालवू नका - मागे फिरा, बुडू नका',
        'वाहत्या पाण्यात चालण्याटाळा - 6 इंच पाणी तुम्हाला पाडू शकतं',
        'इमारतीत अडकलेत तर सगळ्यात वरच्या मजल्यावर जा, पोटमाळ्यात नाही',
        'छतावरून किंवा वरच्या खिडक्यांतून मदतीसाठी इशारा करा',
        'वीज तारा आणि उपकरणांपासून दूर रहा',
        'पुराचं पाणी पिऊ नका - फक्त बाटलीचं किंवा उकळलेलं पाणी वापरा',
        'आणीबाणीचं साहित्य जलरोधक डब्यांत ठेवा',
        'निघून जाण्याची योजना आणि आणीबाणीचं मिळण्याचं ठिकाण ठरवा',
        'निघून जाण्याच्या आदेशांसाठी आणीबाणीचे प्रसारण ऐका'
      ],
      'gu': [
        'પૂર આવવાની શક્યતા હોય તો તરત જ ઊંચી જગ્યાએ જાઓ',
        'પૂરના રસ્તાઓ પર ક્યારેય વાહન ન ચલાવો - પાછા ફરો, ડૂબશો નહીં',
        'વહેતા પાણીમાં ચાલવાનું ટાળો - 6 ઇંચ પાણી તમને પાડી શકે છે',
        'ઇમારતમાં ફસાયેલા હોવ તો સૌથી ઉપરના માળે જાઓ, છાપરામાં નહીં',
        'છત અથવા ઉપરની બારીઓથી મદદ માટે સંકેત આપો',
        'વીજ લાઈનો અને સાધનોથી દૂર રહો',
        'પૂરનું પાણી ન પીવો - માત્ર બોટલ અથવા ઉકાળેલું પાણી વાપરો',
        'કટોકટીનો સામાન પાણીરોધક કન્ટેનરમાં રાખો',
        'સ્થળાંતર યોજના અને કટોકટીનું મળવાનું સ્થાન નક્કી કરો',
        'સ્થળાંતર આદેશો માટે કટોકટીના પ્રસારણ સાંભળો'
      ],
    },

    'cyclone': {
      'en': [
        'Monitor weather updates and evacuation orders closely',
        'Secure or bring indoors all loose outdoor objects',
        'Board up windows with plywood or protective shutters',
        'Stock up on water, non-perishable food, medications for 7 days',
        'Charge all devices and have backup power sources ready',
        'Identify strongest room in house - away from windows',
        'Never go outside during the eye of the storm',
        'Stay away from windows and glass doors during the storm',
        'After storm: Watch for flooding, downed power lines, debris',
        'Do not use candles - use flashlights to avoid fire risk'
      ],
      'hi': [
        'मौसम अपडेट और निकासी आदेशों पर बारीकी से नज़र रखें',
        'बाहर की सभी ढीली वस्तुओं को सुरक्षित करें या अंदर लाएं',
        'खिड़कियों को प्लाइवुड या सुरक्षात्मक शटर से बंद करें',
        '7 दिनों के लिए पानी, गैर-नाशवान भोजन, दवाओं का भंडार करें',
        'सभी उपकरणों को चार्ज करें और बैकअप पावर स्रोत तैयार रखें',
        'घर में सबसे मजबूत कमरे की पहचान करें - खिड़कियों से दूर',
        'तूफान की आंख के दौरान कभी बाहर न जाएं',
        'तूफान के दौरान खिड़कियों और कांच के दरवाजों से दूर रहें',
        'तूफान के बाद: बाढ़, गिरी बिजली लाइनों, मलबे पर ध्यान दें',
        'मोमबत्तियों का उपयोग न करें - आग के जोखिम से बचने के लिए टॉर्च का उपयोग करें'
      ],
      'mr': [
        'हवामान अपडेट आणि निकासी आदेशांवर बारकाईने लक्ष ठेवा',
        'बाहेरच्या सर्व सैल वस्तू सुरक्षित करा किंवा आत आणा',
        'खिडक्यांना प्लायवूड किंवा संरक्षणात्मक शटरने बंद करा',
        '7 दिवसांसाठी पाणी, न खराब होणारे अन्न, औषधांचा साठा करा',
        'सर्व उपकरणे चार्ज करा आणि बॅकअप पॉवर स्रोत तयार ठेवा',
        'घरातील सर्वात मजबूत खोली ओळखा - खिडक्यांपासून दूर',
        'वादळाच्या डोळ्याच्या वेळी कधीही बाहेर जाऊ नका',
        'वादळाच्या वेळी खिडक्या आणि काचेच्या दारांपासून दूर रहा',
        'वादळानंतर: पूर, पडलेल्या वीज तारा, मोडतोड यांकडे लक्ष द्या',
        'मेणबत्त्या वापरू नका - आगीचा धोका टाळण्यासाठी टॉर्च वापरा'
      ],
      'gu': [
        'હવામાન અપડેટ્સ અને ખાલી કરાવવાના આદેશો પર નજીકથી નજર રાખો',
        'બહારની બધી છૂટક વસ્તુઓને સુરક્ષિત કરો અથવા અંદર લાવો',
        'બારીઓને પ્લાયવુડ અથવા સુરક્ષા શટરથી બંધ કરો',
        '7 દિવસ માટે પાણી, ન બગડતું ખોરાક, દવાઓનો સંગ્રહ કરો',
        'બધા ઉપકરણો ચાર્જ કરો અને બેકઅપ પાવર સ્ત્રોત તૈયાર રાખો',
        'ઘરમાં સૌથી મજબૂત ઓરડો ઓળખો - બારીઓથી દૂર',
        'વાવાઝોડાની આંખ દરમિયાન ક્યારેય બહાર ન જાઓ',
        'વાવાઝોડા દરમિયાન બારીઓ અને કાચના દરવાજાઓથી દૂર રહો',
        'વાવાઝોડા પછી: પૂર, પડેલી વીજ લાઈનો, કાટમાળ જુઓ',
        'મીણબત્તીઓ વાપરશો નહીં - આગના જોખમ ટાળવા માટે ટોર્ચ વાપરો'
      ],
    },

    'wildfire': {
      'en': [
        'Create defensible space around your home - clear vegetation',
        'Have evacuation plan ready and know multiple exit routes',
        'Keep important documents in fireproof safe or ready to grab',
        'Monitor air quality and stay indoors if smoke is heavy',
        'Wet down roof and surrounding areas if safe to do so',
        'Close all windows, doors, and vents to prevent embers entering',
        'Move flammable materials away from exterior walls',
        'If evacuating: Leave early, don\'t wait for official order',
        'Never drive through smoke - visibility can drop to zero',
        'After fire: Check for hotspots, be careful of ash and debris'
      ],
      'hi': [
        'अपने घर के चारों ओर रक्षात्मक स्थान बनाएं - वनस्पति साफ करें',
        'निकासी योजना तैयार रखें और कई निकास मार्गों को जानें',
        'महत्वपूर्ण दस्तावेजों को अग्निरोधी तिजोरी में रखें या पकड़ने के लिए तैयार रखें',
        'हवा की गुणवत्ता पर नज़र रखें और धुआं भारी हो तो घर के अंदर रहें',
        'यदि सुरक्षित हो तो छत और आसपास के क्षेत्रों को गीला करें',
        'अंगारों को अंदर आने से रोकने के लिए सभी खिड़कियां, दरवाजे और हवादार बंद करें',
        'ज्वलनशील सामग्री को बाहरी दीवारों से दूर ले जाएं',
        'यदि निकल रहे हैं: जल्दी निकलें, आधिकारिक आदेश का इंतजार न करें',
        'धुएं के बीच कभी न चलाएं - दृश्यता शून्य हो सकती है',
        'आग के बाद: गर्म स्थानों की जांच करें, राख और मलबे से सावधान रहें'
      ],
      'mr': [
        'आपल्या घराभोवती संरक्षणात्मक जागा तयार करा - वनस्पती साफ करा',
        'निकासी योजना तयार ठेवा आणि अनेक निर्गम मार्ग जाणून घ्या',
        'महत्त्वाची कागदपत्रे अग्निरोधक तिजोरीत ठेवा किंवा घेण्यासाठी तयार ठेवा',
        'हवेच्या गुणवत्तेवर लक्ष ठेवा आणि धूर जास्त असेल तर घरात रहा',
        'सुरक्षित असेल तर छत आणि आजूबाजूचे भाग ओले करा',
        'अंगार आत येण्यापासून रोखण्यासाठी सर्व खिडक्या, दरवाजे आणि हवाई छिद्रे बंद करा',
        'ज्वलनशील साहित्य बाहेरच्या भिंतींपासून दूर न्या',
        'बाहेर पडत असाल तर: लवकर निघा, अधिकृत आदेशाची वाट पाहू नका',
        'धुरात कधीही गाडी चालवू नका - दृश्यमानता शून्य होऊ शकते',
        'आगीनंतर: गरम ठिकाणे तपासा, राख आणि मोडतोडपासून सावध रहा'
      ],
    },

    'tsunami': {
      'en': [
        'If you feel earthquake near coast, move inland immediately',
        'If ocean water recedes unusually, evacuate to higher ground',
        'Move at least 2 miles inland or 100 feet above sea level',
        'Never go to beach to watch tsunami waves',
        'Follow marked tsunami evacuation routes',
        'Listen for tsunami warning sirens and follow instructions',
        'Stay away from all waterways, rivers, and coastal areas',
        'If in water when wave hits, grab floating debris and hold on',
        'Waves can continue for hours - don\'t return until all-clear',
        'After tsunami: Avoid flood waters, may contain dangerous debris'
      ],
      'hi': [
        'यदि तट के पास भूकंप महसूस करें तो तुरंत अंतर्देशीय चले जाएं',
        'यदि समुद्र का पानी असामान्य रूप से पीछे हटे तो ऊंची जगह पर चले जाएं',
        'कम से कम 2 मील अंतर्देशीय या समुद्र तल से 100 फीट ऊपर जाएं',
        'सुनामी की लहरें देखने के लिए कभी समुद्र तट पर न जाएं',
        'चिह्नित सुनामी निकासी मार्गों का पालन करें',
        'सुनामी चेतावनी साइरन सुनें और निर्देशों का पालन करें',
        'सभी जलमार्गों, नदियों और तटीय क्षेत्रों से दूर रहें',
        'यदि लहर आने पर पानी में हैं तो तैरते मलबे को पकड़ें',
        'लहरें घंटों तक जारी रह सकती हैं - सब ठीक होने तक वापस न आएं',
        'सुनामी के बाद: बाढ़ के पानी से बचें, इसमें खतरनाक मलबा हो सकता है'
      ],
      'mr': [
        'किनाऱ्याजवळ भूकंप जाणवल्यास लगेच अंतर्देशाकडे जा',
        'समुद्राचे पाणी असामान्यपणे मागे गेल्यास उंच जागी जा',
        'किमान 2 मैल अंतर्देशात किंवा समुद्र पातळीपासून 100 फूट वर जा',
        'त्सुनामीच्या लाटा पाहण्यासाठी कधीही समुद्रकिनाऱ्यावर जाऊ नका',
        'चिन्हांकित त्सुनामी निकासी मार्गांचे अनुसरण करा',
        'त्सुनामी चेतावनी सायरन ऐका आणि सूचनांचे पालन करा',
        'सर्व जलमार्ग, नद्या आणि किनारी भागांपासून दूर रहा',
        'लाट आदळताना पाण्यात असाल तर तरंगते मोडतोड पकडा',
        'लाटा तासनतास सुरू राहू शकतात - सर्व काही ठीक होईपर्यंत परत येऊ नका',
        'त्सुनामीनंतर: पुराच्या पाण्यापासून दूर रहा, त्यात धोकादायक मोडतोड असू शकते'
      ],
    }
  };
}