import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Native Bluetooth file transfer service using Android system
class NativeBluetoothService extends ChangeNotifier {
  static final NativeBluetoothService _instance = NativeBluetoothService._internal();
  factory NativeBluetoothService() => _instance;
  NativeBluetoothService._internal();

  static const MethodChannel _channel = MethodChannel('bluetooth_file_transfer');

  String _status = 'Ready';
  List<Map<String, String>> _bondedDevices = [];
  List<Map<String, String>> _discoveredDevices = [];
  bool _isLoading = false;
  bool _isDiscovering = false;

  // Getters
  String get status => _status;
  List<Map<String, String>> get bondedDevices => _bondedDevices;
  List<Map<String, String>> get discoveredDevices => _discoveredDevices;
  bool get isLoading => _isLoading;
  bool get isDiscovering => _isDiscovering;

  /// Initialize the native Bluetooth service
  Future<bool> initialize() async {
    try {
      _status = 'Initializing native Bluetooth...';
      notifyListeners();
      
      // Load bonded devices on initialization
      await getBondedDevices();
      
      _status = 'Native Bluetooth ready';
      notifyListeners();
      return true;
    } catch (e) {
      _status = 'Failed to initialize: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get list of already paired devices
  Future<List<Map<String, String>>> getBondedDevices() async {
    try {
      _isLoading = true;
      _status = 'Getting paired devices...';
      notifyListeners();

      final List<dynamic> devices = await _channel.invokeMethod('getBondedDevices');
      _bondedDevices = devices.cast<Map<String, String>>();
      
      _status = 'Found ${_bondedDevices.length} paired devices';
      _isLoading = false;
      notifyListeners();
      
      return _bondedDevices;
    } catch (e) {
      _status = 'Error getting devices: $e';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  /// Pair with a device (shows system pairing dialog)
  Future<bool> pairDevice(String deviceAddress) async {
    try {
      _status = 'Initiating pairing...';
      notifyListeners();

      final String result = await _channel.invokeMethod('pairDevice', {
        'deviceAddress': deviceAddress,
      });
      
      _status = result;
      notifyListeners();
      return result.contains('Pairing initiated') || result.contains('already paired');
    } catch (e) {
      _status = 'Pairing failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Discover nearby devices
  Future<bool> discoverDevices() async {
    try {
      _isDiscovering = true;
      _status = 'Discovering devices...';
      _discoveredDevices.clear();
      notifyListeners();

      final List<dynamic> devices = await _channel.invokeMethod('startDeviceDiscovery');
      _discoveredDevices = devices.cast<Map<String, String>>();
      
      _status = 'Found ${_discoveredDevices.length} devices';
      _isDiscovering = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = 'Discovery failed: $e';
      _isDiscovering = false;
      notifyListeners();
      return false;
    }
  }

  /// Send file via system Bluetooth sharing
  Future<bool> sendFileViaBluetoothSystem(String deviceAddress, String message) async {
    try {
      _status = 'Sending message...';
      notifyListeners();

      final String result = await _channel.invokeMethod('sendFileViaBluetoothSystem', {
        'deviceAddress': deviceAddress,
        'message': message,
      });
      
      _status = result;
      notifyListeners();
      return result.contains('transfer initiated') || result.contains('dialog opened');
    } catch (e) {
      _status = 'Send failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Check and request all necessary Bluetooth permissions
  Future<bool> checkAndRequestPermissions() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      _status = 'Checking permissions for Android SDK $sdkInt';
      notifyListeners();

      List<Permission> permissionsToRequest = [];

      if (sdkInt >= 31) {
        // Android 12 and above
        permissionsToRequest = [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
          Permission.nearbyWifiDevices,
        ];
      } else {
        // Android 11 and below
        permissionsToRequest = [
          Permission.bluetooth,
          Permission.bluetoothAdmin,
          Permission.location,
          Permission.accessCoarseLocation,
          Permission.accessFineLocation,
        ];
      }

      Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();

      bool allGranted = true;
      for (var entry in statuses.entries) {
        final permission = entry.key;
        final status = entry.value;
        
        if (status != PermissionStatus.granted) {
          allGranted = false;
        }
      }

      if (allGranted) {
        _status = 'All permissions granted';
        notifyListeners();
        return true;
      } else {
        _status = 'Some permissions were denied';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = 'Permission error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Stop device discovery
  Future<bool> stopDiscovery() async {
    try {
      await _channel.invokeMethod('stopDeviceDiscovery');
      _isDiscovering = false;
      _status = 'Discovery stopped';
      notifyListeners();
      return true;
    } catch (e) {
      _status = 'Stop discovery error: $e';
      _isDiscovering = false;
      notifyListeners();
      return false;
    }
  }
}