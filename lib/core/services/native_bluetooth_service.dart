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
      
      // Check and request permissions first
      final hasPermissions = await checkAndRequestPermissions();
      if (!hasPermissions) {
        _status = 'Bluetooth permissions required';
        notifyListeners();
        return false;
      }
      
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
      _bondedDevices = devices.map((device) => Map<String, String>.from(device)).toList();
      
      print('🔵 Bluetooth: Found ${_bondedDevices.length} paired devices');
      for (var device in _bondedDevices) {
        print('🔵 Device: ${device['name']} (${device['address']})');
      }
      
      _status = 'Found ${_bondedDevices.length} paired devices';
      _isLoading = false;
      notifyListeners();
      
      return _bondedDevices;
    } catch (e) {
      print('🔴 Bluetooth Error: $e');
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

  /// Discover nearby Bluetooth devices
  Future<List<Map<String, String>>> discoverDevices() async {
    try {
      _isDiscovering = true;
      _status = 'Discovering devices...';
      notifyListeners();

      final List<dynamic> devices = await _channel.invokeMethod('discoverDevices');
      _discoveredDevices = devices.map((device) => Map<String, String>.from(device)).toList();
      
      print('🔍 Bluetooth: Discovered ${_discoveredDevices.length} devices');
      for (var device in _discoveredDevices) {
        print('🔍 Device: ${device['name']} (${device['address']})');
      }
      
      _isDiscovering = false;
      _status = 'Discovery completed';
      notifyListeners();
      
      return _discoveredDevices;
    } catch (e) {
      print('🔴 Discovery Error: $e');
      _isDiscovering = false;
      _status = 'Discovery failed: $e';
      notifyListeners();
      return [];
    }
  }

  /// Cancel device discovery
  Future<void> cancelDiscovery() async {
    try {
      await _channel.invokeMethod('stopDeviceDiscovery');
      _isDiscovering = false;
      _status = 'Discovery cancelled';
      notifyListeners();
    } catch (e) {
      print('🔴 Cancel Discovery Error: $e');
      _status = 'Cancel discovery failed: $e';
      notifyListeners();
    }
  }

  /// Send file via Android Bluetooth system dialog
  Future<bool> sendFileViaBluetoothSystem(String deviceAddress, String message) async {
    try {
      _status = 'Opening Bluetooth transfer...';
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

  /// Send message directly via Bluetooth socket (no user dialog)
  Future<bool> sendDirectToBluetooth(String deviceAddress, String message) async {
    try {
      _status = 'Sending via direct connection...';
      notifyListeners();

      final String result = await _channel.invokeMethod('sendDirectToBluetooth', {
        'deviceAddress': deviceAddress,
        'message': message,
      });
      
      _status = result;
      notifyListeners();
      return result.contains('sent directly') || result.contains('Message sent');
    } catch (e) {
      _status = 'Direct send failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Send message to multiple devices sequentially using direct Bluetooth connection
  Future<Map<String, bool>> sendToMultipleDevices(
    List<Map<String, String>> devices, 
    String message,
    {Function(String deviceAddress, String status)? onDeviceUpdate}
  ) async {
    Map<String, bool> results = {};
    
    try {
      _status = 'Broadcasting to ${devices.length} devices...';
      notifyListeners();

      for (int i = 0; i < devices.length; i++) {
        final device = devices[i];
        final deviceAddress = device['address']!;
        final deviceName = device['name'] ?? 'Unknown';
        
        _status = 'Sending to $deviceName (${i + 1}/${devices.length})...';
        notifyListeners();
        
        // Update individual device status
        onDeviceUpdate?.call(deviceAddress, '📤 Connecting...');
        
        try {
          // Use direct Bluetooth communication for multi-device sends
          final success = await sendDirectToBluetooth(deviceAddress, message);
          results[deviceAddress] = success;
          
          if (success) {
            onDeviceUpdate?.call(deviceAddress, '✅ Sent successfully');
          } else {
            onDeviceUpdate?.call(deviceAddress, '❌ Failed to send');
          }
          
          // Small delay between sends to avoid overwhelming devices
          if (i < devices.length - 1) {
            await Future.delayed(const Duration(milliseconds: 2000));
          }
          
        } catch (e) {
          results[deviceAddress] = false;
          onDeviceUpdate?.call(deviceAddress, '❌ Error: $e');
        }
      }
      
      final successCount = results.values.where((success) => success).length;
      _status = 'Broadcast complete: $successCount/${devices.length} successful';
      notifyListeners();
      
      return results;
    } catch (e) {
      _status = 'Broadcast failed: $e';
      notifyListeners();
      return results;
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
          Permission.location,
          Permission.locationWhenInUse,
        ];
      }

      // Request permissions
      Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();
      
      // Check if all required permissions are granted
      bool allPermissionsGranted = true;
      statuses.forEach((permission, status) {
        if (status != PermissionStatus.granted) {
          allPermissionsGranted = false;
          print('🔴 Permission denied: $permission -> $status');
        } else {
          print('✅ Permission granted: $permission');
        }
      });

      if (allPermissionsGranted) {
        _status = 'All Bluetooth permissions granted';
      } else {
        _status = 'Some Bluetooth permissions denied';
      }
      notifyListeners();
      
      return allPermissionsGranted;
    } catch (e) {
      print('🔴 Permission Error: $e');
      _status = 'Permission check failed: $e';
      notifyListeners();
      return false;
    }
  }
}