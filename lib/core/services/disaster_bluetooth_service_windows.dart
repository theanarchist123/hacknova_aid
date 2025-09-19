import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/disaster_message.dart';
import 'bluetooth_compatibility.dart';

// Mock classes for Windows compatibility
class BluetoothDevice {
  final String remoteId;
  final String platformName;
  final BluetoothBondState bondState;
  
  BluetoothDevice({
    required this.remoteId, 
    required this.platformName,
    this.bondState = BluetoothBondState.bonded,
  });
  
  String get name => platformName;
  String get address => remoteId;
}

class BluetoothConnection {
  final String address;
  final bool isConnected;
  
  BluetoothConnection({required this.address, this.isConnected = false});
  
  Stream<Uint8List> get input => Stream.empty();
  void output(List<int> data) {}
  void close() {}
}

enum BluetoothState { STATE_ON, STATE_OFF }
enum BluetoothBondState { bonded, bonding, none }

/// Windows-compatible Bluetooth service with mock implementations
class DisasterBluetoothService extends ChangeNotifier {
  static final DisasterBluetoothService _instance = DisasterBluetoothService._internal();
  factory DisasterBluetoothService() => _instance;
  DisasterBluetoothService._internal();

  // Mock state for Windows
  bool _bluetoothEnabled = false;
  bool _isScanning = false;
  bool _isDiscoverable = false;
  bool _isServerRunning = false;
  
  final List<BluetoothDevice> _discoveredDevices = [];
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final StreamController<List<BluetoothDevice>> _devicesController = 
      StreamController<List<BluetoothDevice>>.broadcast();
  final StreamController<Map<String, bool>> _connectionStatusController = 
      StreamController<Map<String, bool>>.broadcast();
  final StreamController<DisasterMessage> _messageController = 
      StreamController<DisasterMessage>.broadcast();
  
  String? _deviceId;
  String? _userName;

  // Getters
  BluetoothState get bluetoothState => _bluetoothEnabled ? BluetoothState.STATE_ON : BluetoothState.STATE_OFF;
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isDiscoverable;
  bool get isServerRunning => _isServerRunning;
  int get connectedDeviceCount => _connectedDevices.length;
  Map<String, BluetoothDevice> get connectedDevices => Map.unmodifiable(_connectedDevices);
  List<BluetoothDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  String? get deviceId => _deviceId;
  String? get userName => _userName;

  // Streams
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<Map<String, bool>> get connectionStatusStream => _connectionStatusController.stream;
  Stream<DisasterMessage> get messageStream => _messageController.stream;

  /// Initialize the service
  Future<bool> initialize() async {
    if (!BluetoothCompatibility.isBluetoothSupported) {
      debugPrint('📱 Platform ${BluetoothCompatibility.platformName} does not support Bluetooth Serial');
      return false;
    }
    
    // For supported platforms, would initialize real Bluetooth
    debugPrint('🔧 Initializing mock Bluetooth service for ${BluetoothCompatibility.platformName}');
    await _initializeDeviceInfo();
    return true;
  }

  Future<void> _initializeDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final prefs = await SharedPreferences.getInstance();
      
      if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        _deviceId = windowsInfo.computerName;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.model;
      }
      
      _userName = prefs.getString('user_name') ?? 'User';
      debugPrint('📱 Device initialized: $_deviceId, User: $_userName');
    } catch (e) {
      debugPrint('❌ Error initializing device info: $e');
    }
  }

  // Mock methods for Windows compatibility
  Future<void> startScanning() async => await startDiscovery();
  
  Future<void> startDiscovery() async {
    if (!BluetoothCompatibility.isBluetoothSupported) return;
    _isScanning = true;
    notifyListeners();
    
    // Simulate discovery completion
    await Future.delayed(Duration(seconds: 2));
    _isScanning = false;
    notifyListeners();
  }

  Future<void> stopDiscovery() async {
    _isScanning = false;
    notifyListeners();
  }

  Future<bool> connectToDevice(dynamic deviceOrAddress) async {
    if (!BluetoothCompatibility.isBluetoothSupported) return false;
    
    String address;
    if (deviceOrAddress is BluetoothDevice) {
      address = deviceOrAddress.address;
    } else {
      address = deviceOrAddress.toString();
    }
    
    // Mock connection
    final device = BluetoothDevice(remoteId: address, platformName: 'Mock Device');
    _connectedDevices[address] = device;
    notifyListeners();
    return true;
  }

  Future<void> disconnectFromDevice(String address) async {
    _connectedDevices.remove(address);
    notifyListeners();
  }

  Future<void> broadcastMessage(dynamic messageOrString) async {
    if (!BluetoothCompatibility.isBluetoothSupported) return;
    
    String message;
    if (messageOrString is DisasterMessage) {
      message = messageOrString.content;
    } else {
      message = messageOrString.toString();
    }
    
    debugPrint('📤 Broadcasting message: $message');
  }

  Future<void> sendEmergencySOS() async {
    if (!BluetoothCompatibility.isBluetoothSupported) return;
    debugPrint('🆘 Sending emergency SOS');
  }

  Future<List<DisasterMessage>> getRecentMessages({int limit = 50}) async {
    // Return empty list for mock implementation
    return [];
  }

  void dispose() {
    _devicesController.close();
    _connectionStatusController.close();
    _messageController.close();
    super.dispose();
  }
}