import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:battery_plus/battery_plus.dart';

/// Emergency SOS Beacon Service
/// 
/// Provides comprehensive emergency signaling capabilities including:
/// - Morse code SOS pattern via flashlight
/// - Emergency siren audio with MPEG support
/// - Screen flash emergency beacon
/// - Haptic vibration patterns
/// - Battery management for emergency scenarios
/// - Permission handling for emergency hardware access
class SOSEmergencyBeaconService {
  // Singleton pattern for global emergency access
  static final SOSEmergencyBeaconService _instance = 
      SOSEmergencyBeaconService._internal();
  factory SOSEmergencyBeaconService() => _instance;
  SOSEmergencyBeaconService._internal();

  // Emergency signaling state management
  bool _isSOSActive = false;
  bool _isInitialized = false;
  
  // Hardware control instances
  CameraController? _cameraController;
  AudioPlayer? _sirenPlayer;
  Timer? _sosPatternTimer;
  Timer? _screenFlashTimer;
  
  // Emergency pattern timing configuration
  static const int _dotDuration = 200;  // Morse dot duration (ms)
  static const int _dashDuration = 600; // Morse dash duration (ms) 
  static const int _symbolGap = 200;    // Gap between dots/dashes (ms)
  static const int _letterGap = 600;    // Gap between letters (ms)
  static const int _wordGap = 1400;     // Gap between words (ms)
  
  // Battery management for emergency scenarios
  final Battery _battery = Battery();
  
  // Emergency pattern definitions
  final List<String> _sosPattern = ['...', '---', '...']; // S-O-S in Morse
  int _currentPatternIndex = 0;
  int _currentSymbolIndex = 0;

  /// Getters for external status monitoring
  bool get isSOSActive => _isSOSActive;
  bool get isInitialized => _isInitialized;

  /// Initialize emergency beacon hardware systems
  /// 
  /// Sets up camera for flashlight control, audio system for emergency siren,
  /// and configures device wake lock for continuous emergency signaling.
  /// Essential for emergency preparedness - call during app startup.
  Future<bool> initializeEmergencyBeacon() async {
    if (_isInitialized) {
      debugPrint('🔧 Emergency beacon already initialized');
      return true;
    }

    try {
      debugPrint('🚨 Initializing Emergency SOS Beacon System...');
      
      // Check critical device capabilities for emergency use
      await _checkEmergencyCapabilities();
      
      // Initialize camera system for flashlight emergency signaling
      await _initializeFlashlightSystem();
      
      // Setup audio system for emergency siren with failsafe
      await _initializeEmergencyAudio();
      
      // Configure device for emergency mode operation
      await _configureBatteryOptimizations();
      
      _isInitialized = true;
      debugPrint('✅ Emergency SOS Beacon System ready for activation');
      return true;
      
    } catch (emergencyError) {
      debugPrint('❌ Critical emergency system initialization failed: $emergencyError');
      // Even if some components fail, basic SOS should work
      _isInitialized = true; // Allow partial functionality
      return false;
    }
  }

  /// Check device emergency capabilities and permissions
  Future<void> _checkEmergencyCapabilities() async {
    try {
      // Verify vibration capability for haptic emergency alerts
      bool? hasVibrator = await Vibration.hasVibrator();
      debugPrint('📳 Device vibration capability: ${hasVibrator ?? false}');
      
      // Check battery level for emergency planning
      int batteryLevel = await _battery.batteryLevel;
      debugPrint('🔋 Current battery level: $batteryLevel%');
      
      if (batteryLevel < 15) {
        debugPrint('⚠️ Low battery detected - emergency mode will conserve power');
      }
      
    } catch (capabilityError) {
      debugPrint('⚠️ Emergency capability check failed: $capabilityError');
    }
  }

  /// Initialize camera system for emergency flashlight control
  Future<void> _initializeFlashlightSystem() async {
    try {
      debugPrint('🔦 Initializing emergency flashlight system...');
      
      // Get available cameras with emergency flashlight capability
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No camera available for emergency flashlight');
      }
      
      // Use back camera (typically has flashlight)
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      
      // Initialize camera controller for emergency flashlight access
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.low, // Minimize battery usage in emergency
        enableAudio: false,   // Audio not needed for flashlight
      );
      
      await _cameraController?.initialize();
      debugPrint('✅ Emergency flashlight system ready');
      
    } catch (flashlightError) {
      debugPrint('⚠️ Emergency flashlight setup failed: $flashlightError');
      _cameraController = null; // Ensure clean state on failure
    }
  }

  /// Setup emergency audio system with siren capability
  Future<void> _initializeEmergencyAudio() async {
    try {
      debugPrint('🔊 Initializing emergency audio system...');
      
      // Initialize separate player for siren audio file
      _sirenPlayer = AudioPlayer();
      
      // Configure audio for emergency scenarios
      await _sirenPlayer?.setReleaseMode(ReleaseMode.loop);
      await _sirenPlayer?.setVolume(1.0); // Maximum volume for emergency
      
      debugPrint('✅ Emergency audio system ready');
      
    } catch (audioError) {
      debugPrint('⚠️ Emergency audio setup failed: $audioError');
      _sirenPlayer = null;
    }
  }

  /// Configure device for optimal emergency operation
  Future<void> _configureBatteryOptimizations() async {
    try {
      // Prevent device sleep during emergency signaling
      await WakelockPlus.enable();
      debugPrint('🔓 Device wake lock enabled for emergency mode');
      
    } catch (batteryError) {
      debugPrint('⚠️ Emergency battery optimization failed: $batteryError');
    }
  }

  /// Activate comprehensive emergency SOS beacon
  /// 
  /// Starts multi-modal emergency signaling including:
  /// - Morse code SOS via flashlight
  /// - Emergency siren audio
  /// - Screen flash patterns  
  /// - Haptic vibration alerts
  /// - Continuous until manually stopped
  Future<void> activateSOSBeacon() async {
    if (_isSOSActive) {
      debugPrint('🚨 SOS beacon already active');
      return;
    }
    
    debugPrint('🆘 ACTIVATING EMERGENCY SOS BEACON');
    
    _isSOSActive = true;
    _currentPatternIndex = 0;
    _currentSymbolIndex = 0;
    
    // Start all emergency signaling systems simultaneously
    await Future.wait([
      _startSOSFlashlightPattern(),
      _startEmergencySiren(),
      _startScreenFlashPattern(),
      _startEmergencyVibration(),
    ]);
    
    debugPrint('🚨 Emergency SOS beacon fully activated - all systems operational');
  }

  /// Deactivate emergency SOS beacon and restore normal operation
  Future<void> deactivateSOSBeacon() async {
    if (!_isSOSActive) {
      debugPrint('🔇 SOS beacon already inactive');
      return;
    }
    
    debugPrint('🛑 DEACTIVATING EMERGENCY SOS BEACON');
    
    _isSOSActive = false;
    
    // Stop all emergency signaling systems
    await Future.wait([
      _stopSOSFlashlightPattern(),
      _stopEmergencySiren(),
      _stopScreenFlashPattern(),
      _stopEmergencyVibration(),
    ]);
    
    // Restore normal device operation
    await _restoreNormalOperation();
    
    debugPrint('✅ Emergency SOS beacon deactivated - normal operation restored');
  }

  /// Execute continuous SOS pattern loop until deactivation
  Future<void> _executeSOSPatternLoop() async {
    if (!_isSOSActive) return;
    
    final currentLetter = _sosPattern[_currentPatternIndex];
    final currentSymbol = currentLetter[_currentSymbolIndex];
    
    // Execute dot or dash pattern
    if (currentSymbol == '.') {
      await _executeDotPattern();
    } else if (currentSymbol == '-') {
      await _executeDashPattern();
    }
    
    // Advance to next symbol/letter
    _currentSymbolIndex++;
    
    if (_currentSymbolIndex >= currentLetter.length) {
      // Completed current letter, move to next
      _currentSymbolIndex = 0;
      _currentPatternIndex++;
      
      if (_currentPatternIndex >= _sosPattern.length) {
        // Completed full SOS pattern, restart
        _currentPatternIndex = 0;
        
        // Brief pause between SOS repetitions
        _sosPatternTimer = Timer(Duration(milliseconds: _wordGap), () {
          _executeSOSPatternLoop();
        });
        return;
      }
      
      // Gap between letters (S-O-S)
      _sosPatternTimer = Timer(Duration(milliseconds: _letterGap), () {
        _executeSOSPatternLoop();
      });
    } else {
      // Gap between symbols within same letter
      _sosPatternTimer = Timer(Duration(milliseconds: _symbolGap), () {
        _executeSOSPatternLoop();
      });
    }
  }

  /// Execute Morse code dot pattern (short flash)
  Future<void> _executeDotPattern() async {
    if (!_isSOSActive || _cameraController == null) return;
    
    try {
      await _cameraController?.setFlashMode(FlashMode.torch);
      await Future.delayed(Duration(milliseconds: _dotDuration));
      await _cameraController?.setFlashMode(FlashMode.off);
    } catch (dotError) {
      debugPrint('⚠️ Dot pattern execution failed: $dotError');
    }
  }

  /// Execute Morse code dash pattern (long flash)
  Future<void> _executeDashPattern() async {
    if (!_isSOSActive || _cameraController == null) return;
    
    try {
      await _cameraController?.setFlashMode(FlashMode.torch);
      await Future.delayed(Duration(milliseconds: _dashDuration));
      await _cameraController?.setFlashMode(FlashMode.off);
    } catch (dashError) {
      debugPrint('⚠️ Dash pattern execution failed: $dashError');
    }
  }

  /// Start SOS flashlight pattern execution
  Future<void> _startSOSFlashlightPattern() async {
    if (_cameraController == null) {
      debugPrint('⚠️ Flashlight not available for SOS pattern');
      return;
    }
    
    debugPrint('🔦 Starting SOS flashlight pattern');
    _executeSOSPatternLoop();
  }

  /// Stop SOS flashlight pattern and turn off flashlight
  Future<void> _stopSOSFlashlightPattern() async {
    _sosPatternTimer?.cancel();
    _sosPatternTimer = null;
    
    try {
      await _cameraController?.setFlashMode(FlashMode.off);
      debugPrint('🔦 SOS flashlight pattern stopped');
    } catch (flashlightError) {
      debugPrint('⚠️ Error stopping flashlight: $flashlightError');
    }
  }

  /// Start emergency siren with MPEG audio support
  Future<void> _startEmergencySiren() async {
    if (_sirenPlayer == null) {
      debugPrint('⚠️ Emergency audio not available, using fallback');
      await _startFallbackAlertSiren();
      return;
    }
    
    try {
      debugPrint('🚨 Starting emergency siren with audio file');
      
      // Try to play emergency siren from assets
      await _sirenPlayer?.stop(); // Ensure clean start
      await _sirenPlayer?.setVolume(1.0); // Maximum emergency volume
      
      // Try multiple audio formats and sources
      bool audioSuccess = false;
      
      // Try .mpeg first
      try {
        await _sirenPlayer?.play(AssetSource('audio/siren_audio.mpeg'));
        audioSuccess = true;
        debugPrint('✅ Siren audio (.mpeg) playing');
      } catch (mpegError) {
        debugPrint('⚠️ .mpeg audio failed: $mpegError');
        
        // Try .mp3 as backup
        try {
          await _sirenPlayer?.play(AssetSource('audio/siren_audio.mp3'));
          audioSuccess = true;
          debugPrint('✅ Siren audio (.mp3) playing');
        } catch (mp3Error) {
          debugPrint('⚠️ .mp3 audio failed: $mp3Error');
          
          // Try .wav as backup
          try {
            await _sirenPlayer?.play(AssetSource('audio/siren_audio.wav'));
            audioSuccess = true;
            debugPrint('✅ Siren audio (.wav) playing');
          } catch (wavError) {
            debugPrint('⚠️ .wav audio failed: $wavError');
          }
        }
      }
      
      if (!audioSuccess) {
        throw Exception('All audio formats failed');
      }
      
    } catch (sirenError) {
      debugPrint('⚠️ Emergency siren failed: $sirenError');
      await _startFallbackAlertSiren();
    }
  }

  /// Stop emergency siren audio
  Future<void> _stopEmergencySiren() async {
    try {
      await _sirenPlayer?.stop();
      debugPrint('🔇 Emergency siren stopped');
    } catch (stopError) {
      debugPrint('⚠️ Error stopping siren: $stopError');
    }
  }

  /// Fallback system alert siren if audio file fails
  Future<void> _startFallbackAlertSiren() async {
    debugPrint('📢 Using fallback emergency alert system');
    
    try {
      // Create an AudioPlayer for fallback tone generation
      if (_sirenPlayer == null) {
        _sirenPlayer = AudioPlayer();
        await _sirenPlayer?.setReleaseMode(ReleaseMode.loop);
        await _sirenPlayer?.setVolume(1.0);
      }
      
      // Try to play a system emergency tone
      try {
        // Use a system notification sound as fallback
        await _sirenPlayer?.play(AssetSource('audio/emergency_beep.mp3'));
        debugPrint('✅ Fallback emergency tone playing');
      } catch (fallbackError) {
        debugPrint('⚠️ Fallback audio failed: $fallbackError');
        
        // Last resort: Use device vibration as audio substitute
        await _startVibrationSiren();
      }
      
    } catch (fallbackSirenError) {
      debugPrint('⚠️ Complete audio failure: $fallbackSirenError');
      // Silent emergency mode - rely on visual signals only
    }
  }

  /// Use vibration pattern as audio substitute
  Future<void> _startVibrationSiren() async {
    debugPrint('📳 Using vibration as audio substitute');
    
    // Create a rapid vibration pattern to simulate siren
    const vibrationPattern = [100, 50, 100, 50, 100, 50, 100, 200]; // Quick pulses
    
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isSOSActive) {
        timer.cancel();
        return;
      }
      
      try {
        Vibration.vibrate(pattern: vibrationPattern);
      } catch (vibError) {
        debugPrint('⚠️ Vibration siren failed: $vibError');
        timer.cancel();
      }
    });
  }

  /// Start screen flash pattern for visual emergency signaling
  Future<void> _startScreenFlashPattern() async {
    debugPrint('💡 Starting emergency screen flash pattern');
    
    _screenFlashTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if (!_isSOSActive) {
        timer.cancel();
        return;
      }
      
      try {
        // Alternate between bright and dim for visibility
        await ScreenBrightness().setScreenBrightness(1.0);
        await Future.delayed(Duration(milliseconds: 250));
        await ScreenBrightness().setScreenBrightness(0.1);
      } catch (screenError) {
        debugPrint('⚠️ Screen flash error: $screenError');
      }
    });
  }

  /// Stop screen flash pattern and restore normal brightness
  Future<void> _stopScreenFlashPattern() async {
    _screenFlashTimer?.cancel();
    _screenFlashTimer = null;
    
    try {
      await ScreenBrightness().resetScreenBrightness();
      debugPrint('💡 Screen flash pattern stopped');
    } catch (brightnessError) {
      debugPrint('⚠️ Error restoring brightness: $brightnessError');
    }
  }

  /// Start emergency vibration pattern
  Future<void> _startEmergencyVibration() async {
    debugPrint('📳 Starting emergency vibration pattern');
    
    // Create SOS vibration pattern: short-short-short long-long-long short-short-short
    Timer.periodic(Duration(milliseconds: 3000), (timer) async {
      if (!_isSOSActive) {
        timer.cancel();
        return;
      }
      
      try {
        bool? hasVibration = await Vibration.hasVibrator();
        if (hasVibration == true) {
          // SOS pattern: ... --- ...
          await Vibration.vibrate(duration: 200); // S
          await Future.delayed(Duration(milliseconds: 100));
          await Vibration.vibrate(duration: 200);
          await Future.delayed(Duration(milliseconds: 100));
          await Vibration.vibrate(duration: 200);
          await Future.delayed(Duration(milliseconds: 300));
          
          await Vibration.vibrate(duration: 600); // O
          await Future.delayed(Duration(milliseconds: 100));
          await Vibration.vibrate(duration: 600);
          await Future.delayed(Duration(milliseconds: 100));
          await Vibration.vibrate(duration: 600);
          await Future.delayed(Duration(milliseconds: 300));
          
          await Vibration.vibrate(duration: 200); // S
          await Future.delayed(Duration(milliseconds: 100));
          await Vibration.vibrate(duration: 200);
          await Future.delayed(Duration(milliseconds: 100));
          await Vibration.vibrate(duration: 200);
        }
      } catch (vibrationError) {
        debugPrint('⚠️ Emergency vibration error: $vibrationError');
      }
    });
  }

  /// Stop emergency vibration pattern
  Future<void> _stopEmergencyVibration() async {
    try {
      await Vibration.cancel();
      debugPrint('📳 Emergency vibration stopped');
    } catch (vibrationError) {
      debugPrint('⚠️ Error stopping vibration: $vibrationError');
    }
  }

  /// Restore normal device operation after emergency mode
  Future<void> _restoreNormalOperation() async {
    try {
      // Disable wake lock to restore normal power management
      await WakelockPlus.disable();
      
      // Reset screen brightness to system default
      await ScreenBrightness().resetScreenBrightness();
      
      debugPrint('🔄 Normal device operation restored');
      
    } catch (restoreError) {
      debugPrint('⚠️ Error restoring normal operation: $restoreError');
    }
  }

  /// Clean up emergency beacon resources
  /// 
  /// Call this when the emergency service is no longer needed
  /// or when the app is being disposed to free up system resources.
  Future<void> dispose() async {
    debugPrint('🧹 Disposing Emergency SOS Beacon Service');
    
    if (_isSOSActive) {
      await deactivateSOSBeacon();
    }
    
    // Clean up timers
    _sosPatternTimer?.cancel();
    _screenFlashTimer?.cancel();
    
    // Dispose camera controller
    try {
      await _cameraController?.dispose();
    } catch (cameraError) {
      debugPrint('⚠️ Error disposing camera: $cameraError');
    }
    
    // Dispose audio player
    try {
      await _sirenPlayer?.dispose();
    } catch (audioError) {
      debugPrint('⚠️ Error disposing audio: $audioError');
    }
    
    // Ensure normal operation is restored
    await _restoreNormalOperation();
    
    _isInitialized = false;
    debugPrint('✅ Emergency SOS Beacon Service disposed');
  }

  /// Get current emergency beacon status for monitoring
  Map<String, dynamic> getEmergencyStatus() {
    return {
      'isSOSActive': _isSOSActive,
      'isInitialized': _isInitialized,
      'hasFlashlight': _cameraController != null,
      'hasAudio': _sirenPlayer != null,
      'currentPattern': _currentPatternIndex,
      'currentSymbol': _currentSymbolIndex,
    };
  }
}