import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

import '../../core/app_export.dart';
import '../../core/utils/responsive.dart';

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
      'leadMessage': 'Flood Safety Protocol Activated',
      'actions': [
        'Move to higher ground immediately',
        'Avoid walking through flood water',
        'Stay away from electrical equipment',
        'Call 911 if trapped'
      ],
      'supportingInfo': 'Current flood level: 3 feet and rising. Emergency services are active in your area.',
      'nearestShelter': 'High School Gymnasium - 1.2 km west',
      'sources': 'National Weather Service, Local Emergency Management'
    },
    'emergency contact': {
      'leadMessage': 'Emergency Contacts Ready',
      'actions': [
        'Police: 911 (immediate)',
        'Fire Department: 911',
        'Medical Emergency: 911',
        'Emergency Management: (555) 123-4567'
      ],
      'supportingInfo': 'All emergency services are currently operational. Your location has been shared.',
      'nearestShelter': 'Fire Station #3 - 0.5 km south',
      'sources': 'Emergency Services Directory'
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
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startListening() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isListening = !_isListening;
      _hasAnswer = false;
      _currentAnswer = null;
      _recognizedText = '';
    });

    if (_isListening) {
      _pulseController.repeat(reverse: true);
      _simulateSpeechRecognition();
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _simulateSpeechRecognition() {
    Timer(const Duration(seconds: 2), () {
      if (_isListening) {
        setState(() {
          _recognizedText = _getRandomQuestion();
          _isListening = false;
          _hasAnswer = true;
          _currentAnswer = _getResponseForText(_recognizedText);
        });
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  String _getRandomQuestion() {
    final questions = _sampleResponses.keys.toList();
    return questions[Random().nextInt(questions.length)];
  }

  Map<String, dynamic>? _getResponseForText(String text) {
    final key = _sampleResponses.keys.firstWhere(
      (key) => text.toLowerCase().contains(key.toLowerCase()),
      orElse: () => 'where is shelter',
    );
    return _sampleResponses[key];
  }

  void _switchLanguage() {
    HapticFeedback.lightImpact();
    setState(() {
      int currentIndex = _languages.indexOf(_currentLanguage);
      _currentLanguage = _languages[(currentIndex + 1) % _languages.length];
    });
  }

  void _replayAnswer() {
    HapticFeedback.lightImpact();
    // Simulate replay functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing answer in $_currentLanguage'),
        backgroundColor: primaryOrange,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openMaps() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, AppRoutes.interactiveMap);
  }

  void _onBottomNavTap(int index) {
    if (mounted) {
      setState(() => _selectedBottomNavIndex = index);
    }

    switch (index) {
      case 0:
        Navigator.pushNamed(context, AppRoutes.ocr);
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.bluetoothSOS);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.homeDashboard);
        break;
      case 3:
        // Already on Speech Q&A - do nothing
        break;
      case 4:
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
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        return Scaffold(
          backgroundColor: backgroundCream,
          appBar: _buildAppBar(context),
          body: ResponsiveContainer(
            child: SafeScrollView(
              child: _buildMainContent(context),
            ),
          ),
          bottomNavigationBar: _buildBottomNavigation(context),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Disaster Assistant',
        style: TextStyle(
          color: textBlack,
          fontWeight: FontWeight.bold,
          fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.title),
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
          size: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
        ),
      ),
      iconTheme: IconThemeData(
        color: textBlack,
        size: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            children: [
              SizedBox(height: ResponsiveUtils.getSpacing(context, SpacingSize.lg)),
              _buildMicrophoneSection(context),
              SizedBox(height: ResponsiveUtils.getSpacing(context, SpacingSize.lg)),
              _buildContentArea(context),
            ],
          ),
        ),
        _buildFooterActions(context),
      ],
    );
  }

  Widget _buildMicrophoneSection(BuildContext context) {
    final micSize = ResponsiveUtils.getDeviceType(context) == DeviceType.mobile ? 120.0 : 140.0;
    
    return Center(
      child: GestureDetector(
        onTap: _startListening,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _pulseAnimation.value : 1.0,
              child: Container(
                width: micSize,
                height: micSize,
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
                  size: ResponsiveUtils.getIconSize(context, IconSizeType.xl),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentArea(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getSpacing(context, SpacingSize.md),
        ),
        child: _hasAnswer && _currentAnswer != null
            ? _buildAnswerCard(context)
            : _buildPromptText(context),
      ),
    );
  }

  Widget _buildPromptText(BuildContext context) {
    return Center(
      child: Text(
        _isListening
            ? 'Listening... Ask your emergency question'
            : 'Tap the microphone to ask your emergency question',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textBlack,
          fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.subtitle),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAnswerCard(BuildContext context) {
    final answer = _currentAnswer!;
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, BorderRadiusSize.medium),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, SpacingSize.md)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lead Message
              Text(
                answer['leadMessage'] ?? '',
                style: TextStyle(
                  color: primaryOrange,
                  fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.title),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context, SpacingSize.sm)),
              
              // Action Items
              if (answer['actions'] != null) ...[
                Text(
                  'Immediate Actions:',
                  style: TextStyle(
                    color: secondaryBrown,
                    fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.subtitle),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, SpacingSize.sm)),
                ...List<Widget>.from(
                  (answer['actions'] as List).map((action) => Padding(
                    padding: EdgeInsets.only(bottom: ResponsiveUtils.getSpacing(context, SpacingSize.xs)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 8, right: 12),
                          decoration: const BoxDecoration(
                            color: primaryOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            action,
                            style: TextStyle(
                              color: textBlack,
                              fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.body),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, SpacingSize.md)),
              ],
              
              // Supporting Info
              if (answer['supportingInfo'] != null) ...[
                Container(
                  padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, SpacingSize.sm)),
                  decoration: BoxDecoration(
                    color: backgroundCream,
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getBorderRadius(context, BorderRadiusSize.small),
                    ),
                  ),
                  child: Text(
                    answer['supportingInfo'],
                    style: TextStyle(
                      color: textBlack,
                      fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.body),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context, SpacingSize.sm)),
              ],
              
              // Sources
              if (answer['sources'] != null)
                Text(
                  'Source: ${answer['sources']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.caption),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    return Container(
      color: secondaryBrown,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getSpacing(context, SpacingSize.md),
        vertical: ResponsiveUtils.getSpacing(context, SpacingSize.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFooterButton(
            context,
            icon: Icons.replay,
            label: 'Replay',
            onTap: _replayAnswer,
          ),
          _buildFooterButton(
            context,
            icon: Icons.language,
            label: _currentLanguage,
            onTap: _switchLanguage,
          ),
          _buildFooterButton(
            context,
            icon: Icons.map,
            label: 'Map',
            onTap: _openMaps,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: backgroundCream,
            size: ResponsiveUtils.getIconSize(context, IconSizeType.medium),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, SpacingSize.xs)),
          Text(
            label,
            style: TextStyle(
              color: backgroundCream,
              fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.caption),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final iconSize = ResponsiveUtils.getIconSize(context, IconSizeType.medium);
    
    return BottomNavigationBar(
      currentIndex: _selectedBottomNavIndex,
      onTap: _onBottomNavTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: primaryOrange,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(
        fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.caption),
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: ResponsiveUtils.getFontSize(context, FontSizeType.caption),
      ),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.text_fields, size: iconSize),
          label: 'OCR',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bluetooth, size: iconSize),
          label: 'Bluetooth',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: iconSize),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.mic, size: iconSize),
          label: 'Speech Q&A',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emergency, size: iconSize),
          label: 'Response',
        ),
      ],
    );
  }
}