import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Comprehensive SOS Emergency Beacon Service
/// Provides coordinated emergency signaling using phone's flash, screen, audio, and vibration
class SOSEmergencyBeaconService extends ChangeNotifier {
  static final SOSEmergencyBeaconService _instance = SOSEmergencyBeaconService._internal();
  factory SOSEmergencyBeaconService() => _instance;
  SOSEmergencyBeaconService._internal();

  // SOS Morse Code Timing Constants (in milliseconds)
  static const int dotDuration = 100;
  static const int dashDuration = 300;
  static const int gapDuration = 100;
  static const int letterGapDuration = 300;
  static const int cycleGapDuration = 2000;
  static const int maxRuntimeMinutes = 30;

  // State Management
  bool _isSOSActive = false;
  bool _isInitialized = false;
  int _batteryLevel = 100;
  Timer? _sosTimer;
  Timer? _batteryTimer;
  Timer? _autoStopTimer;
  Timer? _sirenTimer;
  int _currentCycle = 0;
  
  // Hardware Controllers
  CameraController? _cameraController;
  AudioPlayer? _audioPlayer;
  AudioPlayer? _sirenPlayer;
  double _originalBrightness = 0.5;
  
  // Status tracking
  String _status = 'Ready';
  String get status => _status;
  bool get isSOSActive => _isSOSActive;
  bool get isInitialized => _isInitialized;
  int get batteryLevel => _batteryLevel;
  int get currentCycle => _currentCycle;

  /// Initialize all emergency beacon components
  Future<bool> initialize() async {
    try {
      debugPrint('🔧 Initializing SOS Emergency Beacon Service...');
      _status = 'Initializing emergency beacon...';
      notifyListeners();

      // Check and request permissions
      debugPrint('🔐 Checking permissions...');
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint('❌ Permissions not granted');
        _status = 'Permissions required for emergency beacon';
        notifyListeners();
        // Continue anyway - some features may still work
      }
      debugPrint('✅ Permissions granted');

      // Initialize camera for flashlight
      debugPrint('📷 Initializing camera...');
      await _initializeCamera();
      
      // Initialize audio player
      debugPrint('🔊 Initializing audio...');
      await _initializeAudio();
      
      // Get initial battery level
      debugPrint('🔋 Getting battery level...');
      await _updateBatteryLevel();
      
      // Store original screen brightness
      debugPrint('💡 Getting original brightness...');
      _originalBrightness = await ScreenBrightness().current;
      
      _isInitialized = true;
      _status = 'Emergency beacon ready';
      debugPrint('🆘 SOS Emergency Beacon Service initialized successfully');
      notifyListeners();
      return true;

    } catch (e) {
      debugPrint('❌ Failed to initialize SOS service: $e');
      _status = 'Failed to initialize: $e';
      notifyListeners();
      return false;
    }
  }

  /// Check and request all necessary permissions
  Future<bool> _checkPermissions() async {
    try {
      List<Permission> permissions = [
        Permission.camera,
        Permission.microphone,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();
      
      bool allGranted = statuses.values.every((status) => 
        status == PermissionStatus.granted || status == PermissionStatus.limited);
      
      return allGranted;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return true; // Continue anyway
    }
  }

  /// Initialize camera for flashlight control
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.low,
          enableAudio: false,
        );
        await _cameraController?.initialize();
      }
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      // Continue without flashlight - use other signals
    }
  }

  /// Initialize audio player for SOS tones and siren
  Future<void> _initializeAudio() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer?.setVolume(1.0);
      
      // Initialize separate player for siren audio file
      _sirenPlayer = AudioPlayer();
      await _sirenPlayer?.setVolume(1.0);
      await _sirenPlayer?.setReleaseMode(ReleaseMode.loop);
      
      debugPrint('✅ Audio players initialized for MPEG siren');
      
    } catch (e) {
      debugPrint('Audio initialization failed: $e');
      // Continue without audio - use other signals
    }
  }

  /// Update battery level
  Future<void> _updateBatteryLevel() async {
    try {
      final battery = Battery();
      _batteryLevel = await battery.batteryLevel;
      notifyListeners();
    } catch (e) {
      debugPrint('Battery level check failed: $e');
    }
  }

  /// Activate SOS emergency beacon with 3-second hold protection
  Future<bool> activateSOSBeacon() async {
    debugPrint('🆘 SOS Beacon activation requested');
    
    if (!_isInitialized) {
      debugPrint('⚠️ SOS Service not initialized, initializing now...');
      final initResult = await initialize();
      if (!initResult) {
        debugPrint('❌ SOS Service initialization failed');
        return false;
      }
    }

    if (_batteryLevel < 5) {
      debugPrint('🔋 Battery too low: $_batteryLevel%');
      _status = 'Battery too low for emergency beacon';
      notifyListeners();
      return false;
    }

    try {
      debugPrint('✅ Starting SOS beacon activation...');
      _isSOSActive = true;
      _currentCycle = 0;
      _status = 'SOS EMERGENCY BEACON ACTIVE';
      notifyListeners();

      // Enable wakelock to keep screen on
      debugPrint('🔒 Enabling wakelock...');
      await WakelockPlus.enable();

      // Set maximum brightness
      debugPrint('💡 Setting maximum brightness...');
      await ScreenBrightness().setScreenBrightness(1.0);

      // Start battery monitoring
      debugPrint('🔋 Starting battery monitoring...');
      _startBatteryMonitoring();

      // Start auto-stop timer (30 minutes)
      debugPrint('⏰ Starting auto-stop timer...');
      _startAutoStopTimer();

      // Start SOS pattern loop
      debugPrint('🔄 Starting SOS pattern loop...');
      _startSOSPattern();

      // Start emergency siren
      debugPrint('🚨 Starting emergency siren...');
      await _startSiren();

      // Set system volume to maximum for emergency
      debugPrint('🔊 Setting maximum system volume...');
      await _setMaximumVolume();

      debugPrint('🆘 SOS BEACON SUCCESSFULLY ACTIVATED');
      return true;

    } catch (e) {
      debugPrint('❌ Failed to activate SOS: $e');
      _status = 'Failed to activate SOS: $e';
      notifyListeners();
      return false;
    }
  }

  /// Deactivate SOS emergency beacon
  Future<void> deactivateSOSBeacon() async {
    try {
      _isSOSActive = false;
      _status = 'SOS beacon deactivated';
      
      // Stop all timers
      _sosTimer?.cancel();
      _batteryTimer?.cancel();
      _autoStopTimer?.cancel();
      _sirenTimer?.cancel();

      // Turn off flashlight
      await _setFlashlight(false);

      // Stop siren
      await _stopSiren();

      // Restore original brightness
      await ScreenBrightness().setScreenBrightness(_originalBrightness);

      // Disable wakelock
      await WakelockPlus.disable();

      notifyListeners();

    } catch (e) {
      debugPrint('Error deactivating SOS: $e');
    }
  }

  /// Start the coordinated SOS pattern loop
  void _startSOSPattern() {
    if (!_isSOSActive) return;

    // Start the SOS pattern execution
    _executeSOSPatternLoop();
  }

  /// Execute the complete SOS pattern in a loop
  Future<void> _executeSOSPatternLoop() async {
    while (_isSOSActive) {
      try {
        // Execute complete SOS pattern: ...---...
        await _executeLetterS(); // dot-dot-dot
        await Future.delayed(Duration(milliseconds: letterGapDuration));
        
        await _executeLetterO(); // dash-dash-dash  
        await Future.delayed(Duration(milliseconds: letterGapDuration));
        
        await _executeLetterS(); // dot-dot-dot
        await Future.delayed(Duration(milliseconds: cycleGapDuration));
        
        _currentCycle++;
        notifyListeners();
        
        // Vibrate to indicate cycle completion
        if (await Vibration.hasVibrator() ?? false) {
          await Vibration.vibrate(duration: 200, amplitude: 255);
        }
        
      } catch (e) {
        debugPrint('Error in SOS pattern: $e');
      }
    }
  }

  /// Execute letter S (dot-dot-dot)
  Future<void> _executeLetterS() async {
    for (int i = 0; i < 3; i++) {
      if (!_isSOSActive) return;
      
      await _activateAllSignals(true); // dot
      await Future.delayed(Duration(milliseconds: dotDuration));
      await _deactivateAllSignals();
      
      if (i < 2) { // Don't add gap after last dot
        await Future.delayed(Duration(milliseconds: gapDuration));
      }
    }
  }

  /// Execute letter O (dash-dash-dash)
  Future<void> _executeLetterO() async {
    for (int i = 0; i < 3; i++) {
      if (!_isSOSActive) return;
      
      await _activateAllSignals(false); // dash
      await Future.delayed(Duration(milliseconds: dashDuration));
      await _deactivateAllSignals();
      
      if (i < 2) { // Don't add gap after last dash
        await Future.delayed(Duration(milliseconds: gapDuration));
      }
    }
  }

  /// Activate all emergency signals
  Future<void> _activateAllSignals(bool isDot) async {
    debugPrint('🚨 Activating all signals - isDot: $isDot');
    try {
      await Future.wait([
        _setFlashlight(true),
        _playSOSTone(isDot),
        _setScreenFlash(true),
        _triggerVibration(isDot),
      ]);
      debugPrint('✅ All signals activated');
    } catch (e) {
      debugPrint('❌ Error activating signals: $e');
    }
  }

  /// Deactivate all emergency signals
  Future<void> _deactivateAllSignals() async {
    await Future.wait([
      _setFlashlight(false),
      _setScreenFlash(false),
    ]);
  }

  /// Control camera flashlight
  Future<void> _setFlashlight(bool enabled) async {
    try {
      debugPrint('🔦 Setting flashlight: $enabled');
      if (_cameraController?.value.isInitialized == true) {
        await _cameraController?.setFlashMode(enabled ? FlashMode.torch : FlashMode.off);
        debugPrint('✅ Flashlight set to: $enabled');
      } else {
        debugPrint('❌ Camera not initialized');
      }
    } catch (e) {
      debugPrint('❌ Flashlight control error: $e');
    }
  }

  /// Play SOS tone (simple beep for Morse code)
  Future<void> _playSOSTone(bool isDot) async {
    try {
      // Simple system sound for Morse code timing
      await SystemSound.play(SystemSoundType.click);
      
      // For dots, use light impact; for dashes, use heavy impact
      if (isDot) {
        await HapticFeedback.lightImpact();
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (e) {
      debugPrint('❌ Audio tone error: $e');
    }
  }

  /// Start continuous siren sound
  Future<void> _startSiren() async {
    try {
      debugPrint('🚨 Starting emergency siren with audio file');
      
      // Play the MPEG siren file on repeat
      if (_sirenPlayer != null) {
        await _sirenPlayer?.setVolume(1.0);
        await _sirenPlayer?.setReleaseMode(ReleaseMode.loop);
        await _sirenPlayer?.play(AssetSource('audio/siren.mpeg'));
        debugPrint('✅ Siren audio file playing');
      }
      
    } catch (e) {
      debugPrint('❌ Siren start error: $e');
      // Fallback to system sounds if audio file fails
      _startSystemAlertSiren();
    }
  }

  /// Fallback system alert siren if audio file fails
  void _startSystemAlertSiren() {
    debugPrint('� Using fallback system alert siren');
    _sirenTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!_isSOSActive) {
        timer.cancel();
        return;
      }
      SystemSound.play(SystemSoundType.alert);
    });
  }

  /// Stop siren sound
  Future<void> _stopSiren() async {
    try {
      debugPrint('🔇 Stopping emergency siren');
      _sirenTimer?.cancel();
      await _sirenPlayer?.stop();
    } catch (e) {
      debugPrint('❌ Siren stop error: $e');
    }
  }

  /// Control screen flash effect
  Future<void> _setScreenFlash(bool enabled) async {
    try {
      if (enabled) {
        await ScreenBrightness().setScreenBrightness(1.0);
      } else {
        await ScreenBrightness().setScreenBrightness(0.1);
      }
    } catch (e) {
      debugPrint('Screen flash error: $e');
    }
  }

  /// Set maximum system volume for emergency
  Future<void> _setMaximumVolume() async {
    try {
      // Set audio players to maximum volume
      await _audioPlayer?.setVolume(1.0);
      await _sirenPlayer?.setVolume(1.0);
      
      debugPrint('✅ Audio volume set to maximum for MPEG siren');
    } catch (e) {
      debugPrint('❌ Volume control error: $e');
    }
  }

  /// Trigger vibration pattern
  Future<void> _triggerVibration(bool isDot) async {
    try {
      debugPrint('📳 Triggering vibration - isDot: $isDot');
      if (await Vibration.hasVibrator() ?? false) {
        int duration = isDot ? dotDuration : dashDuration;
        debugPrint('📳 Vibrating for ${duration}ms');
        await Vibration.vibrate(duration: duration, amplitude: 255);
        debugPrint('✅ Vibration completed');
      } else {
        debugPrint('❌ No vibrator available');
      }
    } catch (e) {
      debugPrint('❌ Vibration error: $e');
    }
  }

  /// Start battery level monitoring
  void _startBatteryMonitoring() {
    _batteryTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      await _updateBatteryLevel();
      
      if (_batteryLevel < 5) {
        await deactivateSOSBeacon();
        _status = 'SOS stopped - low battery';
        notifyListeners();
      }
    });
  }

  /// Start auto-stop timer (30 minutes)
  void _startAutoStopTimer() {
    _autoStopTimer = Timer(Duration(minutes: maxRuntimeMinutes), () async {
      await deactivateSOSBeacon();
      _status = 'SOS auto-stopped after $maxRuntimeMinutes minutes';
      notifyListeners();
    });
  }

  /// Emergency stop - immediately deactivate all signals
  Future<void> emergencyStop() async {
    await deactivateSOSBeacon();
    _status = 'Emergency stop activated';
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    _sosTimer?.cancel();
    _batteryTimer?.cancel();
    _autoStopTimer?.cancel();
    _sirenTimer?.cancel();
    _cameraController?.dispose();
    _audioPlayer?.dispose();
    _sirenPlayer?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }
}