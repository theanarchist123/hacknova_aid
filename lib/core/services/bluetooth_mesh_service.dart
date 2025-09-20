import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';

/// Custom UUIDs for our Messaging Service
class MessagingServiceUUIDs {
  // Custom service UUID for mesh messaging
  static const String messagingServiceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  
  // Characteristic for sending/receiving text messages
  static const String messageCharacteristicUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  
  // Characteristic for device identification
  static const String deviceIdCharacteristicUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
}

/// Message model for Bluetooth text chat
class BluetoothMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final int hopCount;
  final Set<String> routedThrough;

  BluetoothMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.pending,
    this.hopCount = 0,
    this.routedThrough = const {},
  });

  factory BluetoothMessage.fromJson(Map<String, dynamic> json) {
    return BluetoothMessage(
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values[json['status'] ?? 0],
      hopCount: json['hopCount'] ?? 0,
      routedThrough: Set<String>.from(json['routedThrough'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
      'hopCount': hopCount,
      'routedThrough': routedThrough.toList(),
    };
  }

  BluetoothMessage copyWith({
    MessageStatus? status,
    int? hopCount,
    Set<String>? routedThrough,
  }) {
    return BluetoothMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: timestamp,
      status: status ?? this.status,
      hopCount: hopCount ?? this.hopCount,
      routedThrough: routedThrough ?? this.routedThrough,
    );
  }

  /// Convert message to bytes for BLE transmission
  Uint8List toBytes() {
    final jsonString = jsonEncode(toJson());
    return Uint8List.fromList(utf8.encode(jsonString));
  }

  /// Create message from bytes received via BLE
  static BluetoothMessage? fromBytes(Uint8List bytes) {
    try {
      final jsonString = utf8.decode(bytes);
      final json = jsonDecode(jsonString);
      return BluetoothMessage.fromJson(json);
    } catch (e) {
      debugPrint('Error parsing message from bytes: $e');
      return null;
    }
  }
}

/// Message status enumeration
enum MessageStatus {
  pending,
  sent,
  delivered,
  failed,
  pendingSync,
}

/// Connected device information
class ConnectedDevice {
  final BluetoothDevice device;
  final String deviceId;
  final String deviceName;
  final DateTime connectedAt;
  BluetoothCharacteristic? messageCharacteristic;
  BluetoothCharacteristic? deviceIdCharacteristic;

  ConnectedDevice({
    required this.device,
    required this.deviceId,
    required this.deviceName,
    required this.connectedAt,
    this.messageCharacteristic,
    this.deviceIdCharacteristic,
  });
}

/// Core Bluetooth mesh messaging service
class BluetoothMeshService extends ChangeNotifier {
  static final BluetoothMeshService _instance = BluetoothMeshService._internal();
  factory BluetoothMeshService() => _instance;
  BluetoothMeshService._internal();

  // Device information
  late String _deviceId;
  late String _deviceName;
  
  // Connection management
  final Map<String, ConnectedDevice> _connectedDevices = {};
  final Set<String> _seenMessageIds = {};
  final Set<String> _knownDevices = {};
  
  // Message management
  final List<BluetoothMessage> _messages = [];
  final List<BluetoothMessage> _pendingMessages = [];
  
  // Bluetooth state
  bool _isScanning = false;
  bool _isAdvertising = false;
  bool _isInitialized = false;

  // Getters
  String get deviceId => _deviceId;
  String get deviceName => _deviceName;
  List<BluetoothMessage> get messages => List.unmodifiable(_messages);
  List<ConnectedDevice> get connectedDevices => _connectedDevices.values.toList();
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;
  bool get isInitialized => _isInitialized;

  /// Initialize the Bluetooth mesh service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Generate unique device ID and name
      _deviceId = const Uuid().v4();
      _deviceName = 'Device_${_deviceId.substring(0, 8)}';

      // Check Bluetooth adapter state
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth not supported by this device');
      }

      // Listen to adapter state changes
      FlutterBluePlus.adapterState.listen(_onAdapterStateChanged);

      // Wait for Bluetooth to be ready
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }

      _isInitialized = true;
      debugPrint('Bluetooth Mesh Service initialized with ID: $_deviceId');
      
      // Start advertising and scanning
      await startAdvertising();
      await startScanning();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing Bluetooth Mesh Service: $e');
      rethrow;
    }
  }

  /// Handle Bluetooth adapter state changes
  void _onAdapterStateChanged(BluetoothAdapterState state) {
    debugPrint('Bluetooth adapter state changed: $state');
    if (state == BluetoothAdapterState.on && _isInitialized) {
      startAdvertising();
      startScanning();
    } else if (state != BluetoothAdapterState.on) {
      _stopAll();
    }
  }

  /// Start advertising this device as a mesh node
  Future<void> startAdvertising() async {
    if (_isAdvertising) return;

    try {
      // Note: flutter_blue_plus doesn't support peripheral mode on all platforms
      // This is a placeholder for when peripheral functionality becomes available
      _isAdvertising = true;
      debugPrint('Started advertising as mesh node: $_deviceName');
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting advertising: $e');
      _isAdvertising = false;
    }
  }

  /// Start scanning for other mesh nodes
  Future<void> startScanning() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      debugPrint('Started scanning for mesh nodes');

      // Listen for scan results
      FlutterBluePlus.scanResults.listen(_onDeviceFound);

      // Start scanning for devices advertising our service
      await FlutterBluePlus.startScan(
        withServices: [Guid(MessagingServiceUUIDs.messagingServiceUuid)],
        timeout: const Duration(seconds: 4),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error starting scan: $e');
      _isScanning = false;
    }
  }

  /// Handle discovered devices
  void _onDeviceFound(List<ScanResult> results) {
    for (ScanResult result in results) {
      final device = result.device;
      
      // Skip if we're already connected to this device
      if (_connectedDevices.containsKey(device.remoteId.toString())) {
        continue;
      }

      // Attempt to connect to the device
      _connectToDevice(device);
    }
  }

  /// Connect to a discovered device
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      debugPrint('Attempting to connect to device: ${device.platformName}');
      
      await device.connect(timeout: const Duration(seconds: 15));
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      BluetoothService? messagingService;
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == 
            MessagingServiceUUIDs.messagingServiceUuid.toLowerCase()) {
          messagingService = service;
          break;
        }
      }

      if (messagingService == null) {
        await device.disconnect();
        return;
      }

      // Find characteristics
      BluetoothCharacteristic? messageChar;
      BluetoothCharacteristic? deviceIdChar;

      for (BluetoothCharacteristic characteristic in messagingService.characteristics) {
        if (characteristic.uuid.toString().toLowerCase() == 
            MessagingServiceUUIDs.messageCharacteristicUuid.toLowerCase()) {
          messageChar = characteristic;
        } else if (characteristic.uuid.toString().toLowerCase() == 
                   MessagingServiceUUIDs.deviceIdCharacteristicUuid.toLowerCase()) {
          deviceIdChar = characteristic;
        }
      }

      if (messageChar == null) {
        await device.disconnect();
        return;
      }

      // Create connected device entry
      final connectedDevice = ConnectedDevice(
        device: device,
        deviceId: device.remoteId.toString(),
        deviceName: device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
        connectedAt: DateTime.now(),
        messageCharacteristic: messageChar,
        deviceIdCharacteristic: deviceIdChar,
      );

      _connectedDevices[device.remoteId.toString()] = connectedDevice;

      // Subscribe to message notifications
      if (messageChar.properties.notify) {
        await messageChar.setNotifyValue(true);
        messageChar.lastValueStream.listen((value) {
          _onMessageReceived(value, connectedDevice);
        });
      }

      // Listen for disconnection
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevices.remove(device.remoteId.toString());
          notifyListeners();
        }
      });

      debugPrint('Successfully connected to device: ${connectedDevice.deviceName}');
      notifyListeners();

      // Send any pending messages to this new device
      _sendPendingMessages(connectedDevice);

    } catch (e) {
      debugPrint('Error connecting to device: $e');
    }
  }

  /// Handle received messages
  void _onMessageReceived(List<int> value, ConnectedDevice fromDevice) {
    final message = BluetoothMessage.fromBytes(Uint8List.fromList(value));
    if (message == null) return;

    // Prevent message loops
    if (_seenMessageIds.contains(message.id)) {
      return;
    }

    _seenMessageIds.add(message.id);
    
    // Don't process our own messages
    if (message.senderId == _deviceId) {
      return;
    }

    // Add to message list
    _messages.add(message);
    debugPrint('Received message from ${message.senderName}: ${message.content}');

    // Rebroadcast to other connected devices (mesh behavior)
    _rebroadcastMessage(message, fromDevice);

    notifyListeners();
  }

  /// Send a text message to all connected devices
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final message = BluetoothMessage(
      id: const Uuid().v4(),
      senderId: _deviceId,
      senderName: _deviceName,
      content: content.trim(),
      timestamp: DateTime.now(),
      status: MessageStatus.pending,
    );

    // Add to our message list
    _messages.add(message);
    _seenMessageIds.add(message.id);
    notifyListeners();

    // Send to all connected devices
    await _broadcastMessage(message);
  }

  /// Broadcast message to all connected devices
  Future<void> _broadcastMessage(BluetoothMessage message) async {
    if (_connectedDevices.isEmpty) {
      // No devices connected, mark as pending
      _pendingMessages.add(message);
      _updateMessageStatus(message.id, MessageStatus.pendingSync);
      return;
    }

    bool sentSuccessfully = false;

    for (ConnectedDevice device in _connectedDevices.values) {
      try {
        if (device.messageCharacteristic?.properties.write == true) {
          await device.messageCharacteristic!.write(message.toBytes());
          sentSuccessfully = true;
          debugPrint('Sent message to ${device.deviceName}');
        }
      } catch (e) {
        debugPrint('Error sending message to ${device.deviceName}: $e');
      }
    }

    _updateMessageStatus(
      message.id, 
      sentSuccessfully ? MessageStatus.sent : MessageStatus.failed
    );
  }

  /// Rebroadcast received message to other devices (mesh behavior)
  Future<void> _rebroadcastMessage(BluetoothMessage originalMessage, ConnectedDevice fromDevice) async {
    // Create a new message with incremented hop count
    final rebroadcastMessage = originalMessage.copyWith(
      hopCount: originalMessage.hopCount + 1,
      routedThrough: {...originalMessage.routedThrough, _deviceId},
    );

    // Don't rebroadcast if hop count is too high (prevent infinite loops)
    if (rebroadcastMessage.hopCount >= 5) {
      return;
    }

    // Rebroadcast to all other connected devices (excluding the sender)
    for (ConnectedDevice device in _connectedDevices.values) {
      if (device.deviceId == fromDevice.deviceId) continue;
      
      // Don't send back to devices that have already routed this message
      if (rebroadcastMessage.routedThrough.contains(device.deviceId)) continue;

      try {
        if (device.messageCharacteristic?.properties.write == true) {
          await device.messageCharacteristic!.write(rebroadcastMessage.toBytes());
          debugPrint('Rebroadcast message to ${device.deviceName} (hop ${rebroadcastMessage.hopCount})');
        }
      } catch (e) {
        debugPrint('Error rebroadcasting message to ${device.deviceName}: $e');
      }
    }
  }

  /// Send pending messages to a newly connected device
  Future<void> _sendPendingMessages(ConnectedDevice device) async {
    for (BluetoothMessage message in _pendingMessages) {
      try {
        if (device.messageCharacteristic?.properties.write == true) {
          await device.messageCharacteristic!.write(message.toBytes());
          debugPrint('Sent pending message to ${device.deviceName}');
        }
      } catch (e) {
        debugPrint('Error sending pending message to ${device.deviceName}: $e');
      }
    }
  }

  /// Update message status
  void _updateMessageStatus(String messageId, MessageStatus status) {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: status);
      notifyListeners();
    }
  }

  /// Stop all Bluetooth operations
  void _stopAll() {
    _isScanning = false;
    _isAdvertising = false;
    
    // Disconnect all devices
    for (ConnectedDevice device in _connectedDevices.values) {
      device.device.disconnect();
    }
    _connectedDevices.clear();
    
    FlutterBluePlus.stopScan();
    notifyListeners();
  }

  /// Dispose of the service
  @override
  void dispose() {
    _stopAll();
    super.dispose();
  }
}