import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import 'dart:math';

import '../../core/app_export.dart';

class SpeechQnaScreen extends StatefulWidget {
  const SpeechQnaScreen({super.key});

  @override
  State<SpeechQnaScreen> createState() => _SpeechQnaScreenState();
}

class _SpeechQnaScreenState extends State<SpeechQnaScreen>
    with TickerProviderStateMixin {
  bool _isListening = false;
  bool _hasAnswer = false;
  String _currentLanguage = 'EN';
  String _recognizedText = '';
  Map<String, dynamic>? _currentAnswer;
  int _selectedBottomNavIndex = 3; // Set to 3 for Speech Q&A

  // Custom theme colors as specified
  static const Color primaryOrange = Color(0xFFE65100);
  static const Color secondaryBrown = Color(0xFF4E342E);
  static const Color backgroundCream = Color(0xFFFFF8E1);
  static const Color textBlack = Color(0xFF000000);

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _languages = ['EN', 'HI', 'MR'];

  // Sample Q&A responses
  final Map<String, Map<String, dynamic>> _sampleResponses = {
    'where is shelter': {
      'leadMessage': 'Nearest Emergency Shelter Found',
      'actions': [
        'Head to Community Center immediately',
        'Bring essential items (water, medicine, ID)',
        'Follow evacuation route via Main Street',
        'Register at shelter entrance'
      ],
      'supportingInfo': 'Shelter has capacity for 200 people with medical facilities and food supplies.',
      'nearestShelter': 'Community Center - 0.8 km northeast',
      'sources': 'Data from Emergency Services, Red Cross'
    },
    'what to do flood': {
      'leadMessage': 'Flood Safety Instructions',
      'actions': [
        'Move to higher ground immediately',
        'Avoid walking or driving through flood water',
        'Turn off utilities if safely accessible',
        'Stay tuned to emergency broadcasts'
      ],
      'supportingInfo': 'Current water level is rising. Evacuation recommended for low-lying areas.',
      'nearestShelter': 'High School Gym - 1.2 km north',
      'sources': 'Weather Service, Local Emergency Management'
    },
    'need medical help': {
      'leadMessage': 'Medical Emergency Response',
      'actions': [
        'Call emergency services: 108 or 102',
        'Apply first aid if trained',
        'Keep patient calm and lying down',
        'Prepare medical history and medications list'
      ],
      'supportingInfo': 'Emergency medical teams are active in your area. Response time estimated 8-12 minutes.',
      'nearestShelter': 'District Hospital - 2.1 km southeast',
      'sources': 'Emergency Medical Services, Hospital Network'
    },
    'food and water': {
      'leadMessage': 'Emergency Supplies Available',
      'actions': [
        'Visit nearest relief center',
        'Bring identification documents',
        'Collect daily ration (2L water, meal packets)',
        'Report any special dietary needs'
      ],
      'supportingInfo': 'Relief centers are distributing supplies from 6 AM to 8 PM daily.',
      'nearestShelter': 'Government Relief Center - 0.5 km west',
      'sources': 'District Collector Office, NGO Partners'
    }
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startListening() async {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _hasAnswer = false;
      _recognizedText = '';
      _currentAnswer = null;
    });

    HapticFeedback.mediumImpact();
    _pulseController.repeat(reverse: true);

    // Simulate speech recognition
    await Future.delayed(const Duration(seconds: 3));

    // Simulate speech-to-text conversion
    final queries = _sampleResponses.keys.toList();
    final randomQuery = queries[Random().nextInt(queries.length)];

    setState(() {
      _recognizedText = _convertToQuestion(randomQuery);
      _isListening = false;
    });

    _pulseController.stop();
    _pulseController.reset();

    // Simulate processing and response
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _currentAnswer = _sampleResponses[randomQuery];
      _hasAnswer = true;
    });

    HapticFeedback.lightImpact();
  }

  String _convertToQuestion(String key) {
    switch (key) {
      case 'where is shelter':
        return 'Where is the nearest emergency shelter?';
      case 'what to do flood':
        return 'What should I do during a flood?';
      case 'need medical help':
        return 'I need medical help, what should I do?';
      case 'food and water':
        return 'Where can I get food and water?';
      default:
        return 'How can I stay safe during this disaster?';
    }
  }

  void _replayAnswer() {
    if (_currentAnswer != null) {
      HapticFeedback.lightImpact();
      // In a real app, this would use text-to-speech
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing answer aloud...'),
          backgroundColor: primaryOrange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _switchLanguage() {
    final currentIndex = _languages.indexOf(_currentLanguage);
    final nextIndex = (currentIndex + 1) % _languages.length;
    
    setState(() {
      _currentLanguage = _languages[nextIndex];
    });

    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language switched to $_currentLanguage'),
        backgroundColor: secondaryBrown,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _openHazardMap() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, AppRoutes.interactiveMap);
  }

  void _onBottomNavTap(int index) {
    if (mounted) {
      setState(() => _selectedBottomNavIndex = index);
    }

    switch (index) {
      case 0:
        // OCR tab
        Navigator.pushNamed(context, AppRoutes.ocr);
        break;
      case 1:
        // Bluetooth SOS tab
        Navigator.pushNamed(context, AppRoutes.bluetoothSOS);
        break;
      case 2:
        // Home tab
        Navigator.pushNamed(context, AppRoutes.homeDashboard);
        break;
      case 3:
        // Already on Speech Q&A - do nothing
        break;
      case 4:
        // Response tab
        Navigator.pushNamed(context, AppRoutes.emergencyResponse);
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundCream,
      appBar: AppBar(
        title: Text(
          'Disaster Assistant',
          style: TextStyle(
            color: textBlack,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        backgroundColor: primaryOrange,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: textBlack,
          ),
        ),
        iconTheme: IconThemeData(color: textBlack),
      ),
      body: Container(
        color: backgroundCream,
        child: SafeArea(
          child: Column(
            children: [
              // Main Section
              Expanded(
                child: Container(
                  color: backgroundCream,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        SizedBox(height: 2.h),
                        
                        // Microphone Button
                        Center(
                          child: GestureDetector(
                            onTap: _startListening,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isListening ? _pulseAnimation.value : 1.0,
                                  child: Container(
                                    width: 25.w,
                                    height: 25.w,
                                    decoration: BoxDecoration(
                                      color: primaryOrange,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryOrange.withOpacity(0.3),
                                          blurRadius: 15,
                                          spreadRadius: _isListening ? 8 : 0,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isListening ? Icons.mic : Icons.mic_none,
                                      color: Colors.white,
                                      size: 10.w,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 2.h),
                        
                        // Status Text
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Text(
                            _isListening 
                                ? 'Listening...' 
                                : _recognizedText.isNotEmpty 
                                    ? 'You asked: "$_recognizedText"'
                                    : 'Tap to ask your emergency question',
                            style: TextStyle(
                              color: textBlack,
                              fontSize: 14.sp,
                              fontWeight: _isListening ? FontWeight.w600 : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        SizedBox(height: 3.h),
                        
                        // Answer Section
                        if (_hasAnswer && _currentAnswer != null)
                          _buildAnswerCard(),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: backgroundCream,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedBottomNavIndex,
          onTap: _onBottomNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: backgroundCream,
          selectedItemColor: primaryOrange,
          unselectedItemColor: textBlack.withOpacity(0.6),
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12.sp,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.text_fields, size: 6.w),
              label: 'OCR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bluetooth, size: 6.w),
              label: 'SOS Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 6.w),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mic, size: 6.w),
              label: 'Speech Q&A',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency, size: 6.w),
              label: 'Response',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lead Message
          Text(
            _currentAnswer!['leadMessage'],
            style: TextStyle(
              color: textBlack,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 2.h),
          
          // Actions List
          Text(
            'Actions to take:',
            style: TextStyle(
              color: textBlack,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 1.h),
          
          ...(_currentAnswer!['actions'] as List<String>).map((action) => 
            Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check,
                    color: textBlack,
                    size: 3.5.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      action,
                      style: TextStyle(
                        color: textBlack,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
          
          SizedBox(height: 2.h),
          
          // Supporting Info
          Text(
            _currentAnswer!['supportingInfo'],
            style: TextStyle(
              color: textBlack,
              fontSize: 11.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
          
          SizedBox(height: 2.h),
          
          // Nearest Shelter
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: backgroundCream,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: secondaryBrown.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nearest Location:',
                  style: TextStyle(
                    color: textBlack,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  _currentAnswer!['nearestShelter'],
                  style: TextStyle(
                    color: textBlack,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 2.h),
          
          // Sources
          Text(
            'Sources: ${_currentAnswer!['sources']}',
            style: TextStyle(
              color: textBlack.withOpacity(0.6),
              fontSize: 9.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: backgroundCream,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: backgroundCream,
        border: Border(
          top: BorderSide(color: secondaryBrown.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Replay Answer
          _buildFooterButton(
            icon: Icons.replay,
            label: 'Replay Answer',
            onTap: _replayAnswer,
            enabled: _hasAnswer,
          ),
          
          // Language Switch
          _buildFooterButton(
            icon: Icons.language,
            label: 'Language ($_currentLanguage)',
            onTap: _switchLanguage,
            enabled: true,
          ),
          
          // Hazard Map
          _buildFooterButton(
            icon: Icons.map,
            label: 'Hazard Map',
            onTap: _openHazardMap,
            enabled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: enabled ? textBlack : textBlack.withOpacity(0.4),
              size: 5.w,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(
                color: enabled ? textBlack : textBlack.withOpacity(0.4),
                fontSize: 9.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}