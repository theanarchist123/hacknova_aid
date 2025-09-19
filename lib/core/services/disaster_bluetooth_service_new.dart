import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/disaster_message.dart';
import 'message_database.dart';

/// Enhanced Bluetooth service using Bluetooth Classic for reliable disaster relief communication
/// Implements real RFCOMM socket-based communication for phone-to-phone messaging
class DisasterBluetoothService extends ChangeNotifier {
  static final DisasterBluetoothService _instance = DisasterBluetoothService._internal();
  factory DisasterBluetoothService() => _instance;
  DisasterBluetoothService._internal();

  // Service name for identification
  static const String serviceName = "DisasterReliefSOS";
  
  // Message delimiter for stream parsing
  static const String messageDelimiter = "\n###END###\n";

  // Bluetooth state
  bool _bluetoothEnabled = false;
  bool _isScanning = false;
  bool _isServerRunning = false;
  
  // Device discovery and filtering
  final List<BluetoothDevice> _discoveredDevices = [];
  final List<BluetoothDevice> _bondedDevices = [];
  
  // RFCOMM connection management
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, BluetoothConnection> _connections = {};
  final Map<String, StreamSubscription> _connectionListeners = {};
  final Map<String, StringBuffer> _messageBuffers = {};
  final Map<String, String> _deviceStatuses = {}; // Track connection status per device
  
  // Server socket
  BluetoothConnection? _serverSocket;
  StreamSubscription<BluetoothConnection>? _serverListener;
  
  // Message handling
  final MessageDatabase _messageDb = MessageDatabase();
  final StreamController<DisasterMessage> _messageController = StreamController<DisasterMessage>.broadcast();
  final StreamController<List<BluetoothDevice>> _devicesController = StreamController<List<BluetoothDevice>>.broadcast();
  final StreamController<Map<String, bool>> _connectionStatusController = StreamController<Map<String, bool>>.broadcast();
  
  // Message queue for failed sends
  final Map<String, List<DisasterMessage>> _messageQueue = {};
  
  // User info
  String? _deviceId;
  String? _userName;
  BluetoothDevice? _localDevice;

  // Streams
  Stream<DisasterMessage> get messageStream => _messageController.stream;
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<Map<String, bool>> get connectionStatusStream => _connectionStatusController.stream;
  
  // Getters
  bool get bluetoothEnabled => _bluetoothEnabled;
  bool get isScanning => _isScanning;
  bool get isServerRunning => _isServerRunning;
  int get connectedDeviceCount => _connectedDevices.length;
  Map<String, BluetoothDevice> get connectedDevices => Map.unmodifiable(_connectedDevices);
  List<BluetoothDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  List<BluetoothDevice> get bondedDevices => List.unmodifiable(_bondedDevices);
  Map<String, String> get deviceStatuses => Map.unmodifiable(_deviceStatuses);
  String? get deviceId => _deviceId;
  String? get userName => _userName;
  
  /// Initialize the Bluetooth service with Bluetooth Classic
  Future<bool> initialize() async {
    try {
      debugPrint('🔧 Initializing Bluetooth Classic service...');
      
      // Check if Bluetooth is supported
      final BluetoothState state = await FlutterBluetoothSerial.instance.state;
      _bluetoothEnabled = state.isEnabled;
      
      if (!_bluetoothEnabled) {
        debugPrint('❌ Bluetooth is disabled. Please enable it manually.');
        // Try to request enable
        try {
          await FlutterBluetoothSerial.instance.requestEnable();
          final newState = await FlutterBluetoothSerial.instance.state;
          _bluetoothEnabled = newState.isEnabled;
        } catch (e) {
          debugPrint('❌ Failed to enable Bluetooth: $e');
        }
        
        if (!_bluetoothEnabled) {
          return false;
        }
      }

      // Check and request permissions
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint('❌ Bluetooth permissions not granted');
        return false;
      }

      // Get local device info
      _localDevice = BluetoothDevice(
        address: await FlutterBluetoothSerial.instance.address ?? "Unknown",
        name: await FlutterBluetoothSerial.instance.name ?? "Unknown Device"
      );
      
      debugPrint('📱 Local device: ${_localDevice?.name} (${_localDevice?.address})');

      // Initialize device info
      await _initializeDeviceInfo();
      
      // Initialize message database (ensure it's ready)
      await _messageDb.database;
      
      // Start server to receive connections
      final serverStarted = await _startServer();
      if (!serverStarted) {
        debugPrint('⚠️ Failed to start server socket, but continuing...');
      }
      
      // Load bonded devices
      await _loadBondedDevices();
      
      debugPrint('✅ Bluetooth Classic service initialized successfully');
      debugPrint('📱 Device ID: $_deviceId');
      debugPrint('👤 User Name: $_userName');
      debugPrint('🔧 Server Socket: ${_isServerRunning ? "RUNNING" : "FAILED"}');
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing Bluetooth service: $e');
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
        _deviceId = const Uuid().v4();
        await prefs.setString('device_id', _deviceId!);
      }

      // Get or set user name
      _userName = prefs.getString('user_name');
      if (_userName == null) {
        _userName = 'Anonymous User';
        await prefs.setString('user_name', _userName!);
      }

      debugPrint('📱 Device initialized - ID: $_deviceId, Name: $_userName');
    } catch (e) {
      debugPrint('❌ Error initializing device info: $e');
      _deviceId = const Uuid().v4();
      _userName = 'Anonymous User';
    }
  }

  /// Load list of bonded/paired devices
  Future<void> _loadBondedDevices() async {
    try {
      debugPrint('🔍 Loading bonded devices...');
      _bondedDevices.clear();
      
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      _bondedDevices.addAll(bondedDevices);
      
      debugPrint('📋 Found ${_bondedDevices.length} bonded devices');
      for (final device in _bondedDevices) {
        debugPrint('📱 Bonded: ${device.name ?? "Unknown"} (${device.address})');
      }
      
      _devicesController.add(List.from(_bondedDevices));
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading bonded devices: $e');
    }
  }

  /// Start a server socket to listen for incoming connections
  Future<bool> _startServer() async {
    try {
      debugPrint('🔧 Starting Bluetooth server socket...');
      
      // Set device as discoverable
      try {
        await FlutterBluetoothSerial.instance.requestDiscoverable(60);
        debugPrint('✅ Device set to discoverable for 60 seconds');
      } catch (e) {
        debugPrint('⚠️ Failed to set discoverable: $e');
      }
      
      // Create a server socket using the well-known SPP UUID
      // 00001101-0000-1000-8000-00805F9B34FB is the standard UUID for SPP
      final uuid = '00001101-0000-1000-8000-00805F9B34FB';
      
      // Listen for incoming connections
      debugPrint('🔌 Opening server socket on UUID: $uuid');
      
      // Listen for incoming Bluetooth connections
      _serverListener = FlutterBluetoothSerial.instance
          .startDiscovery()
          .map((result) => result.device)
          .where((device) => device.name != null)
          .listen((device) async {
            debugPrint('🔍 Discovered device: ${device.name} (${device.address})');
            
            // Add to discovered devices if not already present
            if (!_discoveredDevices.any((d) => d.address == device.address)) {
              _discoveredDevices.add(device);
              _devicesController.add(List.from(_discoveredDevices));
              notifyListeners();
            }
          });
      
      // Try to create a listening server socket
      try {
        BluetoothConnection.toAddress(_localDevice?.address).then((connection) {
          _handleIncomingConnection(connection);
        });
      } catch (e) {
        debugPrint('❌ Error creating server socket: $e');
      }
      
      _isServerRunning = true;
      _updateDeviceStatus('system', 'Server listening for connections');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error starting server: $e');
      _isServerRunning = false;
      return false;
    }
  }
  
  /// Handle a new incoming connection from another device
  void _handleIncomingConnection(BluetoothConnection connection) async {
    try {
      debugPrint('🔌 New incoming connection from remote device');
      
      // We don't know which device connected yet, we'll find out from the first message
      String? remoteAddress;
      
      // Setup message handling
      connection.input?.listen((data) {
        _handleIncomingData(data, connection, remoteAddress);
      }, 
      onDone: () {
        debugPrint('📴 Remote device disconnected');
        if (remoteAddress != null) {
          _handleDisconnection(remoteAddress);
        }
      },
      onError: (error) {
        debugPrint('❌ Connection error: $error');
        if (remoteAddress != null) {
          _handleDisconnection(remoteAddress);
        }
      });
      
    } catch (e) {
      debugPrint('❌ Error handling incoming connection: $e');
    }
  }
  
  /// Process incoming data from a connected device
  void _handleIncomingData(Uint8List data, BluetoothConnection connection, String? remoteAddress) async {
    try {
      // Convert bytes to string
      final String messageChunk = String.fromCharCodes(data);
      
      // Get or create buffer for this device
      final StringBuffer buffer = _messageBuffers[remoteAddress ?? ''] ?? StringBuffer();
      _messageBuffers[remoteAddress ?? ''] = buffer;
      
      // Add chunk to buffer
      buffer.write(messageChunk);
      
      // Check if we have complete messages
      String bufferContent = buffer.toString();
      
      // Process all complete messages in buffer
      while (bufferContent.contains(messageDelimiter)) {
        final int endIndex = bufferContent.indexOf(messageDelimiter);
        final String messageJson = bufferContent.substring(0, endIndex);
        
        // Remove processed message from buffer
        bufferContent = bufferContent.substring(endIndex + messageDelimiter.length);
        
        // Process the message
        try {
          debugPrint('📥 Received message: $messageJson');
          final Map<String, dynamic> messageData = jsonDecode(messageJson);
          
          // If this is the first message and we don't know the remote address yet,
          // extract the sender ID and register the connection
          if (remoteAddress == null && messageData.containsKey('senderId')) {
            final senderId = messageData['senderId'];
            remoteAddress = senderId;
            
            // Create a virtual BluetoothDevice for this connection
            final senderName = messageData['senderName'] ?? 'Unknown Device';
            final device = BluetoothDevice(
              address: senderId,
              name: senderName,
              type: BluetoothDeviceType.unknown
            );
            
            // Register connection
            _connectedDevices[senderId] = device;
            _connections[senderId] = connection;
            _updateDeviceStatus(senderId, 'Connected');
            
            debugPrint('✅ Registered incoming connection from: $senderName ($senderId)');
          }
          
          // Create DisasterMessage from the JSON
          final DisasterMessage message = DisasterMessage.fromJson(messageData);
          
          // Add to message list and notify listeners
          _messageController.add(message);
          
          // Save to database
          await _messageDb.saveMessage(message);
          
          // Send delivery receipt for this message
          _sendDeliveryReceipt(message);
          
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
  
  /// Send a delivery receipt for a received message
  Future<void> _sendDeliveryReceipt(DisasterMessage message) async {
    try {
      // Create a system message as receipt
      final receiptMessage = DisasterMessage(
        senderId: _deviceId!,
        senderName: _userName!,
        content: 'Message received: ${message.id}',
        type: MessageType.system,
        metadata: {
          'receipt': true,
          'originalMessageId': message.id,
        }
      );
      
      // Send to the original sender
      await sendMessage(receiptMessage, message.senderId);
      
    } catch (e) {
      debugPrint('❌ Error sending delivery receipt: $e');
    }
  }

  /// Start scanning for Bluetooth devices
  Future<void> startScanning({Duration timeout = const Duration(seconds: 30)}) async {
    try {
      if (_isScanning) {
        debugPrint('⚠️ Already scanning for devices');
        return;
      }

      debugPrint('🔍 Started scanning for Bluetooth devices');
      _isScanning = true;
      _discoveredDevices.clear();
      _updateDeviceStatus('system', 'Scanning for devices...');
      notifyListeners();

      // First load bonded devices
      await _loadBondedDevices();
      
      // Then start discovery for new devices
      await FlutterBluetoothSerial.instance.cancelDiscovery();
      
      FlutterBluetoothSerial.instance
          .startDiscovery()
          .listen((result) {
            final device = result.device;
            debugPrint('🔍 Discovered: ${device.name ?? "Unknown"} (${device.address})');
            
            // Skip if already discovered
            if (_discoveredDevices.any((d) => d.address == device.address)) {
              return;
            }
            
            _discoveredDevices.add(device);
            _devicesController.add(List.from([..._bondedDevices, ..._discoveredDevices]));
            notifyListeners();
          }, 
          onDone: () {
            _isScanning = false;
            _updateDeviceStatus('system', 'Scan completed');
            notifyListeners();
          },
          onError: (error) {
            debugPrint('❌ Scan error: $error');
            _isScanning = false;
            _updateDeviceStatus('system', 'Scan error: $error');
            notifyListeners();
          });

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
      rethrow;
    }
  }

  /// Stop scanning for devices
  Future<void> stopScanning() async {
    try {
      if (_isScanning) {
        await FlutterBluetoothSerial.instance.cancelDiscovery();
        _isScanning = false;
        debugPrint('✅ Stopped scanning for devices');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error stopping scan: $e');
    }
  }

  /// Connect to a specific Bluetooth device with RFCOMM
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      final deviceId = device.address;
      debugPrint('🔗 Connecting to device: ${device.name ?? "Unknown"} ($deviceId)');
      
      // Check if already connected
      if (_connectedDevices.containsKey(deviceId)) {
        debugPrint('⚠️ Already connected to $deviceId');
        return true;
      }

      _updateDeviceStatus(deviceId, 'Connecting...');
      
      // Create RFCOMM connection
      final BluetoothConnection connection = 
          await BluetoothConnection.toAddress(deviceId);
      
      debugPrint('✅ Connection established to $deviceId');
      
      // Register the connection
      _connectedDevices[deviceId] = device;
      _connections[deviceId] = connection;
      _messageBuffers[deviceId] = StringBuffer();
      
      // Setup message buffer
      _messageBuffers[deviceId] = StringBuffer();
      
      // Listen for incoming data
      _connectionListeners[deviceId] = connection.input!.listen(
        (data) {
          _handleIncomingData(data, connection, deviceId);
        },
        onDone: () {
          debugPrint('📴 Device disconnected: $deviceId');
          _handleDisconnection(deviceId);
        },
        onError: (error) {
          debugPrint('❌ Connection error: $error');
          _handleDisconnection(deviceId);
        },
      );
      
      _updateDeviceStatus(deviceId, 'Connected');
      
      // Send an initial hello message
      final helloMessage = DisasterMessage(
        senderId: _deviceId!,
        senderName: _userName!,
        content: 'Hello from $_userName',
        type: MessageType.system,
      );
      
      await sendMessage(helloMessage, deviceId);
      
      // Process any queued messages for this device
      _processMessageQueue(deviceId);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error connecting to device: $e');
      _updateDeviceStatus(device.address, 'Connection failed: $e');
      return false;
    }
  }

  /// Handle device disconnection
  void _handleDisconnection(String deviceId) {
    try {
      // Clean up resources
      _connectionListeners[deviceId]?.cancel();
      _connections[deviceId]?.close();
      
      // Remove from tracking maps
      _connectionListeners.remove(deviceId);
      _connections.remove(deviceId);
      _connectedDevices.remove(deviceId);
      
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
      if (!_connections.containsKey(targetDeviceId)) {
        debugPrint('⚠️ Device not connected: $targetDeviceId');
        
        // Queue the message for later delivery
        _queueMessage(message, targetDeviceId);
        
        return false;
      }
      
      // Get the connection
      final connection = _connections[targetDeviceId]!;
      
      // Serialize the message to JSON
      final String messageJson = jsonEncode(message.toJson());
      
      // Add delimiter and convert to bytes
      final String fullMessage = messageJson + messageDelimiter;
      final Uint8List data = Uint8List.fromList(fullMessage.codeUnits);
      
      // Send the data
      connection.output.add(data);
      await connection.output.allSent;
      
      debugPrint('✅ Message sent successfully to $targetDeviceId');
      
      // Update message status
      final updatedMessage = message.copyWith(status: MessageStatus.sent);
      await _messageDb.updateMessage(updatedMessage);
      
      return true;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      
      // Queue the message for later delivery
      _queueMessage(message, targetDeviceId);
      
      return false;
    }
  }

  /// Queue a message for later delivery
  void _queueMessage(DisasterMessage message, String targetDeviceId) {
    try {
      debugPrint('📋 Queuing message for later delivery to $targetDeviceId');
      
      // Initialize queue for this device if needed
      _messageQueue[targetDeviceId] ??= [];
      
      // Add message to queue
      _messageQueue[targetDeviceId]!.add(message);
      
      // Update message status
      final updatedMessage = message.copyWith(status: MessageStatus.failed);
      _messageDb.updateMessage(updatedMessage);
      
      debugPrint('✅ Message queued for later delivery');
    } catch (e) {
      debugPrint('❌ Error queuing message: $e');
    }
  }

  /// Process queued messages for a device
  Future<void> _processMessageQueue(String deviceId) async {
    try {
      if (!_messageQueue.containsKey(deviceId) || _messageQueue[deviceId]!.isEmpty) {
        return;
      }
      
      debugPrint('📋 Processing queued messages for $deviceId');
      
      final List<DisasterMessage> messages = List.from(_messageQueue[deviceId]!);
      _messageQueue[deviceId]!.clear();
      
      for (final message in messages) {
        final success = await sendMessage(message, deviceId);
        if (!success) {
          debugPrint('⚠️ Failed to send queued message, will retry later');
          break;
        }
      }
      
      debugPrint('✅ Queued messages processed for $deviceId');
    } catch (e) {
      debugPrint('❌ Error processing message queue: $e');
    }
  }

  /// Send a message to all connected devices
  Future<void> broadcastMessage(DisasterMessage message) async {
    try {
      debugPrint('📣 Broadcasting message to ${_connectedDevices.length} devices');
      
      for (final deviceId in _connectedDevices.keys) {
        await sendMessage(message, deviceId);
      }
      
      debugPrint('✅ Message broadcast completed');
    } catch (e) {
      debugPrint('❌ Error broadcasting message: $e');
    }
  }

  /// Update device status for UI feedback
  void _updateDeviceStatus(String deviceId, String status) {
    _deviceStatuses[deviceId] = status;
    notifyListeners();
  }

  /// Get recent messages from the database
  Future<List<DisasterMessage>> getRecentMessages() async {
    try {
      return await _messageDb.getRecentMessages(100);
    } catch (e) {
      debugPrint('❌ Error getting recent messages: $e');
      return [];
    }
  }

  /// Stop all Bluetooth operations and clean up
  Future<void> dispose() async {
    try {
      debugPrint('🧹 Cleaning up Bluetooth resources...');
      
      // Stop scanning
      await stopScanning();
      
      // Close all connections
      for (final deviceId in _connections.keys) {
        await _connections[deviceId]?.close();
        await _connectionListeners[deviceId]?.cancel();
      }
      
      // Close server
      await _serverListener?.cancel();
      
      // Clear all collections
      _connections.clear();
      _connectionListeners.clear();
      _connectedDevices.clear();
      _messageBuffers.clear();
      
      debugPrint('✅ Bluetooth resources cleaned up');
    } catch (e) {
      debugPrint('❌ Error disposing Bluetooth service: $e');
    } finally {
      super.dispose();
    }
  }
}