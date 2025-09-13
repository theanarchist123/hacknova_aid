import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import 'dart:math';

import '../../core/app_export.dart';

class BluetoothSOSScreen extends StatefulWidget {
  const BluetoothSOSScreen({super.key});

  @override
  State<BluetoothSOSScreen> createState() => _BluetoothSOSScreenState();
}

class _BluetoothSOSScreenState extends State<BluetoothSOSScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _nearbyMessages = [];
  
  bool _isBluetoothEnabled = true;
  bool _isMeshRelayEnabled = false;
  bool _isSendingMessage = false;
  bool _isListening = false;
  String _deviceId = "Device_A123";
  int _selectedBottomNavIndex = 1; // Set to 1 for Bluetooth SOS
  
  late AnimationController _highlightController;
  late Animation<Color?> _highlightAnimation;
  int _highlightedIndex = -1;

  final List<String> _quickMessages = [
    "Need Food",
    "Need Medical Help", 
    "Trapped / Rescue Needed"
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generateSampleMessages();
    
    // Simulate receiving messages periodically
    Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted && _isBluetoothEnabled) {
        _addRandomMessage();
      }
    });
  }

  void _setupAnimations() {
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _highlightAnimation = ColorTween(
      begin: Colors.transparent,
      end: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    ));
  }

  void _generateSampleMessages() {
    final sampleMessages = [
      {
        'senderId': 'Device_B456',
        'message': 'Family safe at shelter on Oak Street',
        'distance': '~150m away',
        'status': 'Delivered',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      },
      {
        'senderId': 'Device_C789',
        'message': 'Road blocked at Main St intersection',
        'distance': '~300m away',
        'status': 'Pending Sync',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 12)),
      },
      {
        'senderId': 'Device_D012',
        'message': 'Medical help needed at community center',
        'distance': '~200m away',
        'status': 'Delivered',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 8)),
      },
    ];
    
    setState(() {
      _nearbyMessages.addAll(sampleMessages);
    });
  }

  void _addRandomMessage() {
    final random = Random();
    final messages = [
      'Water available at fire station',
      'Evacuation route clear via Highway 9',
      'Emergency supplies at school gym',
      'All family members accounted for',
      'Power restored in downtown area',
    ];
    
    final deviceIds = ['Device_E345', 'Device_F678', 'Device_G901'];
    final distances = ['~100m away', '~250m away', '~180m away', '~320m away'];
    
    final newMessage = {
      'senderId': deviceIds[random.nextInt(deviceIds.length)],
      'message': messages[random.nextInt(messages.length)],
      'distance': distances[random.nextInt(distances.length)],
      'status': random.nextBool() ? 'Delivered' : 'Pending Sync',
      'timestamp': DateTime.now(),
    };
    
    setState(() {
      _nearbyMessages.insert(0, newMessage);
      _highlightedIndex = 0;
    });
    
    _highlightController.forward().then((_) {
      _highlightController.reverse();
    });
  }

  void _sendMessage(String message) async {
    if (!_isBluetoothEnabled) {
      _showSnackBar('Enable Bluetooth to send messages', isError: true);
      return;
    }
    
    if (message.trim().isEmpty) {
      _showSnackBar('Please enter a message', isError: true);
      return;
    }
    
    setState(() => _isSendingMessage = true);
    
    HapticFeedback.mediumImpact();
    
    // Simulate sending delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    setState(() => _isSendingMessage = false);
    
    _showSnackBar('Broadcasting message... Sent!', isSuccess: true);
    _messageController.clear();
  }

  void _simulateInternetSync() async {
    final pendingMessages = _nearbyMessages.where((msg) => msg['status'] == 'Pending Sync').toList();
    
    if (pendingMessages.isEmpty) {
      _showSnackBar('No messages to sync');
      return;
    }
    
    _showSnackBar('Syncing ${pendingMessages.length} messages...');
    
    // Simulate sync delay
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      for (var message in _nearbyMessages) {
        if (message['status'] == 'Pending Sync') {
          message['status'] = 'Synced to Dashboard';
        }
      }
    });
    
    _showSnackBar('All messages synced to dashboard!', isSuccess: true);
  }

  void _toggleSpeechToText() async {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      _showSnackBar('Listening for speech...');
      // Simulate speech recognition
      await Future.delayed(const Duration(seconds: 3));
      
      // Simulate speech-to-text conversion
      final simulatedSpeechTexts = [
        "Help me, I'm trapped in a building!",
        "Need medical assistance urgently",
        "Food and water required at location",
        "Emergency evacuation needed",
        "Building collapse, people trapped"
      ];
      
      final randomText = simulatedSpeechTexts[Random().nextInt(simulatedSpeechTexts.length)];
      
      setState(() {
        _messageController.text = randomText;
        _isListening = false;
      });
      
      _showSnackBar('Speech converted to text', isSuccess: true);
    } else {
      _showSnackBar('Speech recognition stopped');
    }
  }

  void _onBottomNavTap(int index) {
    if (mounted) {
      setState(() => _selectedBottomNavIndex = index);
    }

    switch (index) {
      case 0:
        // OCR tab - navigate to OCR screen
        Navigator.pushNamed(context, AppRoutes.ocr);
        break;
      case 1:
        // Already on Bluetooth SOS - do nothing
        break;
      case 2:
        // Home tab - navigate back to home
        Navigator.pushNamed(context, AppRoutes.homeDashboard);
        break;
      case 3:
        // Speech QnA tab - navigate to Speech QnA screen
        Navigator.pushNamed(context, AppRoutes.speechQna);
        break;
      case 4:
        // Response tab - navigate to emergency response screen
        Navigator.pushNamed(context, AppRoutes.emergencyResponse);
        break;
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? Colors.red 
            : isSuccess 
                ? AppTheme.successLight 
                : AppTheme.lightTheme.primaryColor,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offline SOS Messaging',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Send or receive messages without internet (Simulation)',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(179),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        elevation: 0,
        toolbarHeight: 8.h,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Send SOS Section
            _buildSendSOSSection(),
            
            SizedBox(height: 4.h),
            
            // Nearby Messages Section
            _buildNearbyMessagesSection(),
            
            SizedBox(height: 4.h),
            
            // Sync Simulation Section
            _buildSyncSection(),
            
            SizedBox(height: 4.h),
            
            // Settings Section
            _buildSettingsSection(),
            
            SizedBox(height: 2.h),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedBottomNavIndex,
          onTap: _onBottomNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
          unselectedItemColor:
              AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
          selectedLabelStyle:
              AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTheme.lightTheme.textTheme.labelSmall,
          items: [
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: 'text_fields',
                color: _selectedBottomNavIndex == 0
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                size: 6.w,
              ),
              label: 'OCR',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: 'bluetooth',
                color: _selectedBottomNavIndex == 1
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                size: 6.w,
              ),
              label: 'SOS Chat',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: 'home',
                color: _selectedBottomNavIndex == 2
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                size: 6.w,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: 'mic',
                color: _selectedBottomNavIndex == 3
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                size: 6.w,
              ),
              label: 'Speech Q&A',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: 'emergency',
                color: _selectedBottomNavIndex == 4
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                size: 6.w,
              ),
              label: 'Response',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendSOSSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.send,
                color: AppTheme.lightTheme.primaryColor,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Send SOS Message',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 3.h),
          
          // Custom message input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter custom SOS message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.outlineLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.lightTheme.primaryColor),
                    ),
                    contentPadding: EdgeInsets.all(3.w),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              GestureDetector(
                onTap: _toggleSpeechToText,
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: _isListening 
                        ? AppTheme.lightTheme.colorScheme.primary.withAlpha(51)
                        : AppTheme.lightTheme.colorScheme.surface,
                    border: Border.all(
                      color: _isListening 
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.outlineLight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening 
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurface.withAlpha(153),
                    size: 6.w,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 3.h),
          
          // Quick action buttons
          Text(
            'Quick Messages:',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 2.h),
          
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _quickMessages.map((message) => 
              OutlinedButton(
                onPressed: () => _sendMessage(message),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.lightTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  message,
                  style: TextStyle(color: AppTheme.lightTheme.primaryColor),
                ),
              ),
            ).toList(),
          ),
          
          SizedBox(height: 3.h),
          
          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSendingMessage 
                  ? null 
                  : () => _sendMessage(_messageController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSendingMessage
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 4.w,
                          height: 4.w,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          'Broadcasting...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    )
                  : Text(
                      'Send via Bluetooth',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyMessagesSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.message,
                color: AppTheme.lightTheme.primaryColor,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Nearby Messages',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_nearbyMessages.length}',
                  style: TextStyle(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 3.h),
          
          if (_nearbyMessages.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.bluetooth_searching,
                      size: 12.w,
                      color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'No nearby messages',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _nearbyMessages.length,
              separatorBuilder: (context, index) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
                final message = _nearbyMessages[index];
                return AnimatedBuilder(
                  animation: _highlightAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: index == _highlightedIndex 
                            ? _highlightAnimation.value 
                            : Colors.transparent,
                        border: Border.all(color: AppTheme.outlineLight.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.device_hub,
                                size: 4.w,
                                color: AppTheme.lightTheme.primaryColor,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                message['senderId'],
                                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.lightTheme.primaryColor,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(message['status']).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  message['status'],
                                  style: TextStyle(
                                    color: _getStatusColor(message['status']),
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 1.h),
                          
                          Text(
                            message['message'],
                            style: AppTheme.lightTheme.textTheme.bodyMedium,
                          ),
                          
                          SizedBox(height: 1.h),
                          
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 3.w,
                                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                message['distance'],
                                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatTimestamp(message['timestamp']),
                                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSyncSection() {
    final pendingCount = _nearbyMessages.where((msg) => msg['status'] == 'Pending Sync').length;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sync,
                color: AppTheme.lightTheme.primaryColor,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Internet Sync',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (pendingCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pendingCount pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          Text(
            'Sync offline messages to the main dashboard when internet is available',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          
          SizedBox(height: 3.h),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: pendingCount > 0 ? _simulateInternetSync : null,
              icon: Icon(Icons.cloud_upload, color: Colors.white),
              label: Text(
                'Simulate Internet Sync',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: pendingCount > 0 
                    ? AppTheme.secondaryLight 
                    : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.3),
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: AppTheme.lightTheme.primaryColor,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Connection Settings',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 3.h),
          
          // Bluetooth toggle
          Row(
            children: [
              Icon(
                Icons.bluetooth,
                color: _isBluetoothEnabled 
                    ? AppTheme.successLight 
                    : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bluetooth',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _isBluetoothEnabled ? 'Connected and discoverable' : 'Disconnected',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isBluetoothEnabled,
                onChanged: (value) => setState(() => _isBluetoothEnabled = value),
                activeColor: AppTheme.successLight,
              ),
            ],
          ),
          
          SizedBox(height: 3.h),
          
          // Mesh relay toggle
          Row(
            children: [
              Icon(
                Icons.device_hub,
                color: _isMeshRelayEnabled 
                    ? AppTheme.successLight 
                    : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable Mesh Relay',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Relay messages through this device',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isMeshRelayEnabled,
                onChanged: _isBluetoothEnabled 
                    ? (value) => setState(() => _isMeshRelayEnabled = value)
                    : null,
                activeColor: AppTheme.successLight,
              ),
            ],
          ),
          
          SizedBox(height: 3.h),
          
          // Device ID
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              border: Border.all(color: AppTheme.outlineLight.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.smartphone,
                  color: AppTheme.lightTheme.primaryColor,
                  size: 5.w,
                ),
                SizedBox(width: 3.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device ID',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _deviceId,
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppTheme.successLight;
      case 'Pending Sync':
        return Colors.orange;
      case 'Synced to Dashboard':
        return AppTheme.lightTheme.primaryColor;
      default:
        return AppTheme.lightTheme.colorScheme.onSurface;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}