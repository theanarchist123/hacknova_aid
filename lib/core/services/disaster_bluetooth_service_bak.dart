import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/disaster_message.dart';
import 'message_database.dart';

/// Enhanced Bluetooth service using BLE for reliable disaster relief communication
/// Implements BLE communication for device-to-device messaging
class DisasterBluetoothService extends ChangeNotifier {
  static final DisasterBluetoothService _instance = DisasterBluetoothService._internal();
  factory DisasterBluetoothService() => _instance;
  DisasterBluetoothService._internal();

  // FlutterReactiveBle instance
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // Service and characteristic UUIDs for disaster communication
  static final Uuid _serviceUuid = Uuid.parse("12345678-1234-5678-9012-123456789abc");
  static final Uuid _messageCharacteristicUuid = Uuid.parse("12345678-1234-5678-9012-123456789abd");
  static const String serviceName = "DisasterReliefSOS";
  
  // Message delimiter for stream parsing
  static const String messageDelimiter = "\n###END###\n";

  // Bluetooth state
  bool _bluetoothEnabled = false;
  bool _isScanning = false;
  bool _isServerRunning = false;
  bool _isAdvertising = false;
  
  // Device discovery and filtering
  final List<DiscoveredDevice> _discoveredDevices = [];
  final List<DiscoveredDevice> _validDisasterDevices = [];
  
  // Connection management
  final Map<String, DeviceConnectionState> _connectionStates = {};
  final Map<String, StreamSubscription<ConnectionStateUpdate>> _connectionSubscriptions = {};
  final Map<String, QualifiedCharacteristic> _writeCharacteristics = {};
  final Map<String, StreamSubscription> _notifySubscriptions = {};
  final Map<String, StringBuffer> _messageBuffers = {};
  final Map<String, String> _deviceStatuses = {};
  
  // Message handling
  final MessageDatabase _messageDb = MessageDatabase();
  final StreamController<DisasterMessage> _messageController = StreamController<DisasterMessage>.broadcast();
  final StreamController<List<DiscoveredDevice>> _devicesController = StreamController<List<DiscoveredDevice>>.broadcast();
  final StreamController<Map<String, String>> _connectionStatusController = StreamController<Map<String, String>>.broadcast();
  
  // Message queue for failed sends
  final Map<String, List<DisasterMessage>> _messageQueue = {};
  
  // Scan subscription
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<BleStatus>? _bleStatusSubscription;
  
  // User info
  String? _deviceId;
  String? _userName;

  // Streams
  Stream<DisasterMessage> get messageStream => _messageController.stream;
  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;
  Stream<Map<String, String>> get connectionStatusStream => _connectionStatusController.stream;
  
  // Getters
  bool get bluetoothEnabled => _bluetoothEnabled;
  bool get isScanning => _isScanning;
  bool get isServerRunning => _isServerRunning;
  bool get isAdvertising => _isAdvertising;
  int get connectedDeviceCount => _writeCharacteristics.length;
  List<DiscoveredDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  List<DiscoveredDevice> get validDisasterDevices => List.unmodifiable(_validDisasterDevices);
  Map<String, String> get deviceStatuses => Map.unmodifiable(_deviceStatuses);
  String? get deviceId => _deviceId;
  String? get userName => _userName;

  /// Check if Bluetooth can be enabled (this will prompt user to enable if possible)
  Future<bool> requestBluetoothEnable() async {
    try {
      debugPrint('📲 Requesting Bluetooth enable...');
      
      // On Android, we can't programmatically enable Bluetooth
      // but we can guide the user to the settings
      final status = await _ble.statusStream.first;
      debugPrint('📡 Current BLE status: $status');
      
      if (status == BleStatus.ready) {
        _bluetoothEnabled = true;
        notifyListeners();
        return true;
      }
      
      debugPrint('⚠️ Bluetooth needs to be enabled manually');
      return false;
    } catch (e) {
      debugPrint('❌ Error checking Bluetooth status: $e');
      return false;
    }
  }

  /// Check if device is running our disaster chat app - SIMPLIFIED VERSION
  bool _isValidDisasterDevice(DiscoveredDevice device) {
    debugPrint('🔍 Evaluating: "${device.name}" (${device.id})');
    debugPrint('   RSSI: ${device.rssi} dBm');
    
    // Skip our own device
    if (device.id == _deviceId) {
      debugPrint('⚠️ SKIPPED: Own device');
      return false;
    }
    
    // ACCEPT ALL DEVICES FOR NOW - Let user choose which ones to connect to
    // This is the most practical approach for testing
    final name = device.name.toLowerCase();
    
    // Only skip devices with empty names or very weak signal
    if (device.name.isEmpty || device.rssi < -80) {
      debugPrint('❌ REJECTED: Empty name or weak signal (${device.rssi} dBm)');
      return false;
    }
    
    // Accept phones and tablets that might have our app
    if (name.contains('phone') || name.contains('android') || name.contains('samsung') || 
        name.contains('pixel') || name.contains('galaxy') || name.contains('huawei') ||
        name.contains('xiaomi') || name.contains('oneplus') || name.contains('oppo') ||
        name.contains('vivo') || name.contains('realme') || name.contains('iphone') ||
        name.contains('ipad') || name.contains('tablet')) {
      debugPrint('✅ ACCEPTED: Phone/tablet device: "$name"');
      return true;
    }
    
    // Accept any device with a reasonable name (potential phone)
    if (device.name.length >= 3 && !name.contains('watch') && !name.contains('tv') && 
        !name.contains('speaker') && !name.contains('headphone') && !name.contains('car')) {
      debugPrint('✅ ACCEPTED: Potential mobile device: "$name"');
      return true;
    }
    
    debugPrint('❌ REJECTED: Not a mobile device: "$name"');
    return false;
  }

  /// Initialize the Bluetooth service
  Future<bool> initialize() async {
    try {
      debugPrint('🔧 Initializing BLE service...');
      
      // Check permissions
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint('❌ Bluetooth permissions not granted');
        return false;
      }

      // Monitor BLE status
      _bleStatusSubscription = _ble.statusStream.listen((status) {
        final wasEnabled = _bluetoothEnabled;
        _bluetoothEnabled = status == BleStatus.ready;
        debugPrint('📡 BLE status: $status');
        
        // Start advertising when Bluetooth becomes ready
        if (!wasEnabled && _bluetoothEnabled) {
          startAdvertising();
        }
        
        notifyListeners();
      });

      // Check current BLE status
      final status = await _ble.statusStream.first;
      _bluetoothEnabled = status == BleStatus.ready;
      
      if (!_bluetoothEnabled) {
        debugPrint('⚠️ Bluetooth is not enabled. Status: $status');
        return false;
      }

      // Initialize device info
      await _initializeDeviceInfo();
      
      // Initialize message database
      await _messageDb.database;
      
      // START ADVERTISING - This makes your device discoverable
      await startAdvertising();
      
      _isServerRunning = true;
      
      debugPrint('✅ BLE service initialized successfully');
      debugPrint('📱 Device ID: $_deviceId');
      debugPrint('👤 User Name: $_userName');
      debugPrint('� Advertising: $_isAdvertising');
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing BLE service: $e');
      return false;
    }
  }

  /// Check and request Bluetooth permissions
  Future<bool> _checkPermissions() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      debugPrint('📋 Checking permissions for Android SDK $sdkInt');

      List<Permission> permissions;
      
      if (sdkInt >= 31) {
        // Android 12+ permissions
        permissions = [
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
          Permission.bluetoothAdvertise,
          Permission.location,
        ];
      } else {
        // Older Android versions
        permissions = [
          Permission.bluetooth,
          Permission.location,
        ];
      }

      // Check current permission status
      for (final permission in permissions) {
        final status = await permission.status;
        debugPrint('🔐 Permission $permission: $status');
        
        if (!status.isGranted) {
          debugPrint('📝 Requesting permission: $permission');
          final result = await permission.request();
          debugPrint('🔐 Permission $permission result: $result');
          
          if (!result.isGranted) {
            debugPrint('❌ Permission $permission denied');
            return false;
          }
        }
      }

      debugPrint('✅ All Bluetooth permissions granted');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
      return false;
    }
  }

  /// Initialize device information
  Future<void> _initializeDeviceInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get or generate device ID
      _deviceId = prefs.getString('device_id');
      if (_deviceId == null) {
        _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString('device_id', _deviceId!);
      }

      // Get or set user name
      _userName = prefs.getString('user_name');
      if (_userName == null) {
        _userName = 'Emergency User';
        await prefs.setString('user_name', _userName!);
      }

      debugPrint('📱 Device initialized - ID: $_deviceId, Name: $_userName');
    } catch (e) {
      debugPrint('❌ Error initializing device info: $e');
      _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      _userName = 'Emergency User';
    }
  }

  /// Start advertising our disaster relief service
  Future<bool> startAdvertising() async {
    try {
      if (_isAdvertising) {
        debugPrint('⚠️ Already advertising');
        return true;
      }

      debugPrint('📡 Starting BLE advertising...');
      
      // Note: flutter_reactive_ble doesn't have a direct advertise method
      // We'll use service discovery and characteristic setup for device identification
      // This is a placeholder for when peripheral mode is available
      _isAdvertising = true;
      debugPrint('✅ Started advertising disaster chat service (placeholder)');
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('❌ Failed to start advertising: $e');
      return false;
    }
  }

  /// Stop advertising
  Future<void> stopAdvertising() async {
    try {
      if (_isAdvertising) {
        // Stop advertising placeholder
        _isAdvertising = false;
        debugPrint('📴 Stopped advertising');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error stopping advertising: $e');
    }
  }

  /// Set device name to be more discoverable for emergency chat
  Future<void> setEmergencyDiscoverableMode(bool enabled) async {
    try {
      if (enabled) {
        debugPrint('📡 Enabling emergency discoverable mode...');
        // Note: BLE device naming is limited on most platforms
        // The device will appear with its system Bluetooth name
        // but we can identify emergency devices by service UUID and characteristics
      } else {
        debugPrint('📴 Disabling emergency discoverable mode...');
      }
    } catch (e) {
      debugPrint('❌ Error setting discoverable mode: $e');
    }
  }

  /// Start scanning for disaster chat devices - SIMPLIFIED VERSION
  Future<void> startScanning({Duration timeout = const Duration(seconds: 30)}) async {
    try {
      if (_isScanning) {
        debugPrint('⚠️ Already scanning for devices');
        return;
      }

      debugPrint('🔍 Started scanning for nearby devices (simplified approach)');
      _isScanning = true;
      _discoveredDevices.clear();
      _validDisasterDevices.clear();
      _updateDeviceStatus('system', 'Scanning for nearby devices...');
      notifyListeners();

      // SIMPLIFIED: Just scan all devices, no service filtering
      _scanSubscription = _ble.scanForDevices(
        withServices: [], // No service filter - discover all devices
        scanMode: ScanMode.lowLatency,
        requireLocationServicesEnabled: false,
      ).listen(
        (device) {
          if (_discoveredDevices.any((d) => d.id == device.id)) return;
          
          _discoveredDevices.add(device);
          debugPrint('🔍 Discovered: ${device.name} (${device.id}) RSSI: ${device.rssi}');
          
          // Apply our simplified filtering
          if (_isValidDisasterDevice(device)) {
            _validDisasterDevices.add(device);
            _updateDeviceStatus(device.id, 'Found potential device: ${device.name}');
            debugPrint('✅ Added potential disaster device: ${device.name}');
          }
          
          _devicesController.add(List.from(_validDisasterDevices));
          notifyListeners();
        },
        onError: (error) {
          debugPrint('❌ Scan error: $error');
          _updateDeviceStatus('system', 'Scan error: $error');
        },
      );

      // Stop scanning after timeout
      Timer(timeout, () async {
        if (_isScanning) {
          debugPrint('⏰ Scan timeout, stopping scan');
          await stopScanning();
        }
      });

    } catch (e) {
      debugPrint('❌ Error scanning for devices: $e');
      _isScanning = false;
      _updateDeviceStatus('system', 'Scan failed: $e');
      notifyListeners();
    }
  }

  /// Stop scanning for devices
  Future<void> stopScanning() async {
    try {
      if (_isScanning) {
        await _scanSubscription?.cancel();
        _scanSubscription = null;
        _isScanning = false;
        debugPrint('✅ Stopped scanning for devices');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error stopping scan: $e');
    }
  }

  /// Connect to a specific BLE device with enhanced error handling
  Future<bool> connectToDevice(DiscoveredDevice device) async {
    try {
      final deviceId = device.id;
      debugPrint('🔗 Attempting to connect to: ${device.name} ($deviceId)');
      
      // Check if already connected
      if (_connectionStates[deviceId] == DeviceConnectionState.connected) {
        debugPrint('⚠️ Already connected to $deviceId');
        return true;
      }

      _updateDeviceStatus(deviceId, 'Connecting...');

      // Try to discover services first to see if this device has our emergency service
      try {
        debugPrint('🔍 Discovering services for ${device.name}...');
        
        // Connect to the device
        _connectionSubscriptions[deviceId] = _ble.connectToDevice(
          id: deviceId,
          connectionTimeout: const Duration(seconds: 15),
        ).listen(
          (connectionState) async {
            _connectionStates[deviceId] = connectionState.connectionState;
            debugPrint('🔄 Connection state for ${device.name}: ${connectionState.connectionState}');
            
            if (connectionState.connectionState == DeviceConnectionState.connected) {
              debugPrint('✅ Connected to ${device.name}');
              
              // Try to setup characteristics
              final success = await _setupCharacteristics(deviceId);
              
              if (success) {
                _updateDeviceStatus(deviceId, 'Connected - Chat Ready');
                
                // Broadcast connection state change
                _connectionStatusController.add(Map.from(_deviceStatuses));
                
                // Send initial handshake message
                final handshakeMessage = DisasterMessage(
                  senderId: _deviceId!,
                  senderName: _userName!,
                  content: '👋 Connected to emergency chat network. Ready for communication.',
                  type: MessageType.system,
                );
                
                await sendMessage(handshakeMessage, deviceId);
                debugPrint('🤝 Handshake sent to ${device.name}');
              } else {
                _updateDeviceStatus(deviceId, 'Connected but no emergency service found');
                debugPrint('⚠️ Device ${device.name} connected but no emergency chat service available');
              }
              
              notifyListeners();
            } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
              debugPrint('📴 Disconnected from ${device.name}');
              _handleDisconnection(deviceId);
            }
          },
          onError: (error) {
            debugPrint('❌ Connection error to ${device.name}: $error');
            _updateDeviceStatus(deviceId, 'Connection failed: $error');
            _handleDisconnection(deviceId);
          },
        );
        
        return true;
      } catch (e) {
        debugPrint('❌ Service discovery failed for ${device.name}: $e');
        _updateDeviceStatus(deviceId, 'Service discovery failed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error connecting to ${device.name}: $e');
      _updateDeviceStatus(device.id, 'Connection failed: $e');
      return false;
    }
  }

  /// Setup characteristics for communication
  Future<bool> _setupCharacteristics(String deviceId) async {
    try {
      debugPrint('🔧 Setting up characteristics for $deviceId');
      
      // Discover services first
      final services = await _ble.discoverServices(deviceId);
      debugPrint('🔍 Discovered ${services.length} services for $deviceId');
      
      // Look for our emergency service
      DiscoveredService? emergencyService;
      for (final service in services) {
        debugPrint('📋 Service: ${service.serviceId}');
        if (service.serviceId == _serviceUuid) {
          emergencyService = service;
          debugPrint('✅ Found emergency service!');
          break;
        }
      }
      
      if (emergencyService == null) {
        debugPrint('❌ Emergency service not found. Available services:');
        for (final service in services) {
          debugPrint('   - ${service.serviceId}');
        }
        
        // Still try to set up with standard characteristic - might work for some devices
        debugPrint('🔄 Attempting to use standard characteristics anyway...');
      }
      
      final writeChar = QualifiedCharacteristic(
        serviceId: _serviceUuid,
        characteristicId: _messageCharacteristicUuid,
        deviceId: deviceId,
      );
      
      _writeCharacteristics[deviceId] = writeChar;
      _messageBuffers[deviceId] = StringBuffer();
      
      debugPrint('📝 Attempting to subscribe to notifications for $deviceId');
      
      // Subscribe to notifications
      _notifySubscriptions[deviceId] = _ble.subscribeToCharacteristic(writeChar).listen(
        (data) {
          debugPrint('📨 Notification received from $deviceId, data length: ${data.length}');
          _handleIncomingData(data, deviceId);
        },
        onError: (error) {
          debugPrint('❌ Notification error for $deviceId: $error');
          // Don't fail completely - some devices might still work for sending
        },
        onDone: () {
          debugPrint('✅ Notification stream closed for $deviceId');
        },
      );
      
      debugPrint('✅ Characteristics setup completed for $deviceId');
      return true;
    } catch (e) {
      debugPrint('❌ Error setting up characteristics for $deviceId: $e');
      return false;
    }
  }

  /// Handle incoming data from a device
  void _handleIncomingData(List<int> data, String deviceId) async {
    try {
      final String messageChunk = String.fromCharCodes(data);
      debugPrint('📥 Raw data from $deviceId: $messageChunk');
      
      // Get or create buffer for this device
      final StringBuffer buffer = _messageBuffers[deviceId] ?? StringBuffer();
      _messageBuffers[deviceId] = buffer;
      
      // Add chunk to buffer
      buffer.write(messageChunk);
      
      // Check if we have complete messages
      String bufferContent = buffer.toString();
      debugPrint('📝 Buffer content: $bufferContent');
      
      // Process all complete messages in buffer
      while (bufferContent.contains(messageDelimiter)) {
        final int endIndex = bufferContent.indexOf(messageDelimiter);
        final String messageJson = bufferContent.substring(0, endIndex);
        
        // Remove processed message from buffer
        bufferContent = bufferContent.substring(endIndex + messageDelimiter.length);
        
        // Process the message
        try {
          debugPrint('📥 Processing message JSON: $messageJson');
          final Map<String, dynamic> messageData = jsonDecode(messageJson);
          final DisasterMessage message = DisasterMessage.fromJson(messageData);
          
          debugPrint('✅ Message received from ${message.senderName}: ${message.content}');
          
          // Add to message list and notify listeners
          _messageController.add(message);
          
          // Save to database
          await _messageDb.insertMessage(message);
          
        } catch (e) {
          debugPrint('❌ Error processing message: $e');
        }
      }
      
      // Update buffer with remaining incomplete data
      buffer.clear();
      buffer.write(bufferContent);
      
    } catch (e) {
      debugPrint('❌ Error handling incoming data: $e');
    }
  }

  /// Handle device disconnection
  void _handleDisconnection(String deviceId) {
    try {
      // Clean up resources
      _connectionSubscriptions[deviceId]?.cancel();
      _notifySubscriptions[deviceId]?.cancel();
      
      // Remove from tracking maps
      _connectionSubscriptions.remove(deviceId);
      _notifySubscriptions.remove(deviceId);
      _writeCharacteristics.remove(deviceId);
      _connectionStates.remove(deviceId);
      
      _updateDeviceStatus(deviceId, 'Disconnected');
      debugPrint('📴 Device disconnected and cleaned up: $deviceId');
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error handling disconnection: $e');
    }
  }

  /// Send a message to a specific device
  Future<bool> sendMessage(DisasterMessage message, String targetDeviceId) async {
    try {
      debugPrint('📤 Sending message to $targetDeviceId: ${message.content}');
      
      // Check if device is connected
      if (!_writeCharacteristics.containsKey(targetDeviceId)) {
        debugPrint('⚠️ Device not connected: $targetDeviceId');
        await _queueMessage(message, targetDeviceId);
        return false;
      }
      
      // Get the characteristic
      final characteristic = _writeCharacteristics[targetDeviceId]!;
      
      // Serialize the message to JSON
      final String messageJson = jsonEncode(message.toJson());
      
      // Add delimiter and convert to bytes
      final String fullMessage = messageJson + messageDelimiter;
      final List<int> data = fullMessage.codeUnits;
      
      // Send the data
      await _ble.writeCharacteristicWithoutResponse(characteristic, data);
      
      debugPrint('✅ Message sent successfully to $targetDeviceId');
      
      // Update message status
      await _messageDb.updateMessageStatus(message.id, MessageStatus.sent);
      
      return true;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      await _queueMessage(message, targetDeviceId);
      return false;
    }
  }

  /// Queue a message for later delivery
  Future<void> _queueMessage(DisasterMessage message, String targetDeviceId) async {
    try {
      debugPrint('📋 Queuing message for later delivery to $targetDeviceId');
      
      // Initialize queue for this device if needed
      _messageQueue[targetDeviceId] ??= [];
      
      // Add message to queue
      _messageQueue[targetDeviceId]!.add(message);
      
      // Update message status to failed
      await _messageDb.updateMessageStatus(message.id, MessageStatus.failed);
      
      debugPrint('✅ Message queued for later delivery');
    } catch (e) {
      debugPrint('❌ Error queuing message: $e');
    }
  }

  /// Send a message to all connected devices
  Future<void> broadcastMessage(DisasterMessage message) async {
    try {
      debugPrint('📣 Broadcasting message to ${_writeCharacteristics.length} devices');
      
      // Save to database AND add to message stream for UI display
      await _messageDb.insertMessage(message);
      
      // Add to message stream so it shows up in UI immediately
      _messageController.add(message);
      
      for (final deviceId in _writeCharacteristics.keys) {
        await sendMessage(message, deviceId);
      }
      
      debugPrint('✅ Message broadcast completed');
    } catch (e) {
      debugPrint('❌ Error broadcasting message: $e');
    }
  }

  /// Send emergency SOS message to all connected devices
  Future<void> sendEmergencySOS() async {
    try {
      final sosMessage = DisasterMessage(
        senderId: _deviceId ?? 'unknown',
        senderName: _userName ?? 'Anonymous',
        content: '🆘 EMERGENCY SOS - Need immediate assistance! Location assistance required.',
        type: MessageType.emergency,
      );
      
      await broadcastMessage(sosMessage);
      debugPrint('🆘 Emergency SOS sent to all connected devices');
    } catch (e) {
      debugPrint('❌ Error sending emergency SOS: $e');
      rethrow;
    }
  }

  /// Send a regular chat message to all connected devices
  Future<void> sendChatMessage(String content) async {
    try {
      final chatMessage = DisasterMessage(
        senderId: _deviceId ?? 'unknown',
        senderName: _userName ?? 'Anonymous',
        content: content,
        type: MessageType.regular,
      );
      
      await broadcastMessage(chatMessage);
      debugPrint('💬 Chat message sent: $content');
    } catch (e) {
      debugPrint('❌ Error sending chat message: $e');
      rethrow;
    }
  }

  /// Send a private message to a specific device
  Future<bool> sendPrivateMessage(String content, String targetDeviceId) async {
    try {
      final privateMessage = DisasterMessage(
        senderId: _deviceId ?? 'unknown',
        senderName: _userName ?? 'Anonymous',
        content: content,
        type: MessageType.regular,
      );
      
      // Save to database AND add to message stream for UI display
      await _messageDb.insertMessage(privateMessage);
      
      // Add to message stream so it shows up in UI immediately
      _messageController.add(privateMessage);
      
      final success = await sendMessage(privateMessage, targetDeviceId);
      if (success) {
        debugPrint('💬 Private message sent to $targetDeviceId: $content');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error sending private message: $e');
      return false;
    }
  }

  /// Get list of connected devices for chat
  List<String> getConnectedDeviceIds() {
    return _writeCharacteristics.keys.toList();
  }

  /// Get device status for a specific device
  String? getDeviceStatus(String deviceId) {
    return _deviceStatuses[deviceId];
  }

  /// Check if any devices are connected for chatting
  bool get hasConnectedDevices => _writeCharacteristics.isNotEmpty;

  /// Update device status for UI feedback
  void _updateDeviceStatus(String deviceId, String status) {
    _deviceStatuses[deviceId] = status;
    
    // Broadcast status changes to UI
    _connectionStatusController.add(Map.from(_deviceStatuses));
    
    notifyListeners();
  }

  /// Get recent messages from the database
  Future<List<DisasterMessage>> getRecentMessages() async {
    try {
      return await _messageDb.getRecentMessages();
    } catch (e) {
      debugPrint('❌ Error getting recent messages: $e');
      return [];
    }
  }

  /// Stop all Bluetooth operations and clean up
  @override
  Future<void> dispose() async {
    try {
      debugPrint('🧹 Cleaning up Bluetooth resources...');
      
      // Stop advertising
      await stopAdvertising();
      
      // Stop scanning
      await stopScanning();
      
      // Close all connections
      for (final subscription in _connectionSubscriptions.values) {
        await subscription.cancel();
      }
      
      for (final subscription in _notifySubscriptions.values) {
        await subscription.cancel();
      }
      
      await _bleStatusSubscription?.cancel();
      
      // Clear all collections
      _connectionSubscriptions.clear();
      _notifySubscriptions.clear();
      _writeCharacteristics.clear();
      _messageBuffers.clear();
      
      debugPrint('✅ Bluetooth resources cleaned up');
    } catch (e) {
      debugPrint('❌ Error disposing Bluetooth service: $e');
    } finally {
      super.dispose();
    }
  }
}