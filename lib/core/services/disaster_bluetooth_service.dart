import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/disaster_message.dart';
import 'message_database.dart';

/// Enhanced Bluetooth service using BLE for reliable disaster relief communication
/// Implements SPP-like messaging over BLE for better compatibility and range
class DisasterBluetoothService extends ChangeNotifier {
  static final DisasterBluetoothService _instance = DisasterBluetoothService._internal();
  factory DisasterBluetoothService() => _instance;
  DisasterBluetoothService._internal();

  // Standard SPP UUID for RFCOMM
  static const String serviceUuid = "00001101-0000-1000-8000-00805F9B34FB";
  static const String serviceName = "DisasterReliefSOS";
  
  // Message delimiter for stream parsing
  static const String messageDelimiter = "\n###END###\n";

  // Bluetooth state - using simulation for compatibility
  bool _bluetoothEnabled = false;
  bool _isScanning = false;
  bool _isDiscoverable = false;
  bool _isServerRunning = false;
  
  // Connection management - real connections
  final Map<String, BluetoothConnection> _connections = {};
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final List<BluetoothDevice> _discoveredDevices = [];
  final Map<String, StringBuffer> _messageBuffers = {};
  final Map<String, StreamSubscription> _connectionListeners = {};
  
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
  
  // Streams
  Stream<DisasterMessage> get messageStream => _messageController.stream;
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<Map<String, bool>> get connectionStatusStream => _connectionStatusController.stream;
  
  // Getters - compatible with Bluetooth Classic API
  BluetoothState get bluetoothState => _bluetoothEnabled ? BluetoothState.STATE_ON : BluetoothState.STATE_OFF;
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isDiscoverable;
  bool get isServerRunning => _isServerRunning;
  int get connectedDeviceCount => _connections.length;
  Map<String, BluetoothDevice> get connectedDevices => Map.unmodifiable(_connectedDevices);
  List<BluetoothDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  String? get deviceId => _deviceId;
  String? get userName => _userName;
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;
  List<BluetoothDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  Map<String, BluetoothDevice> get connectedDevices => Map.unmodifiable(_connectedDevices);
  String? get deviceId => _deviceId;
  String? get userName => _userName;
  int get connectedDeviceCount => _connectedDevices.length;

  /// Initialize the Bluetooth service with real Bluetooth Classic
  Future<bool> initialize() async {
    try {
      debugPrint('🔧 Initializing Bluetooth Classic service...');
      
      // Check and request permissions
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint('❌ Bluetooth permissions not granted');
        return false;
      }

      // Get current Bluetooth state
      final state = await FlutterBluetoothSerial.instance.state;
      _bluetoothEnabled = state == BluetoothState.STATE_ON;
      debugPrint('📡 Bluetooth state: $state');

      // Enable Bluetooth if disabled
      if (!_bluetoothEnabled) {
        debugPrint('🔄 Attempting to enable Bluetooth...');
        final result = await FlutterBluetoothSerial.instance.requestEnable();
        _bluetoothEnabled = result == true;
        
        if (!_bluetoothEnabled) {
          debugPrint('❌ Failed to enable Bluetooth');
          return false;
        }
      }

      // Initialize device info
      await _initializeDeviceInfo();
      
      // Initialize message database
      await _messageDb.initialize();
      
      // Start RFCOMM server to listen for incoming connections
      await _startRfcommServer();
      
      // Make device discoverable
      await _makeDiscoverable();
      
      debugPrint('✅ Bluetooth service initialized successfully');
      debugPrint('📱 Device ID: $_deviceId');
      debugPrint('👤 User Name: $_userName');
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing Bluetooth service: $e');
      return false;
    }
  }

  /// Start RFCOMM server to accept incoming connections
  Future<void> _startRfcommServer() async {
    try {
      debugPrint('🏃 Starting RFCOMM server...');
      
      // Listen for incoming connections using RFCOMM
      FlutterBluetoothSerial.instance.listenUsingRfcomm().listen(
        (BluetoothConnection connection) {
          debugPrint('📞 Incoming connection from: ${connection.remoteAddress}');
          _handleIncomingConnection(connection);
        },
        onError: (error) {
          debugPrint('❌ RFCOMM server error: $error');
        },
      );

      _isServerRunning = true;
      debugPrint('✅ RFCOMM server started successfully');
    } catch (e) {
      debugPrint('❌ Error starting RFCOMM server: $e');
      _isServerRunning = false;
    }
  }

  /// Handle incoming Bluetooth connection
  void _handleIncomingConnection(BluetoothConnection connection) {
    try {
      final deviceAddress = connection.remoteAddress;
      debugPrint('🤝 Handling connection from: $deviceAddress');
      
      // Store connection
      _connections[deviceAddress] = connection;
      _messageBuffers[deviceAddress] = StringBuffer();
      
      // Create device object for UI
      final device = BluetoothDevice(
        name: 'Incoming Device',
        address: deviceAddress,
        type: BluetoothDeviceType.classic,
        bondState: BluetoothBondState.bonded,
        isConnected: true,
      );
      
      _connectedDevices[deviceAddress] = device;
      
      // Listen for incoming messages
      _connectionListeners[deviceAddress] = connection.input!.listen(
        (Uint8List data) {
          _handleIncomingData(deviceAddress, data);
        },
        onDone: () {
          debugPrint('🔌 Connection closed by: $deviceAddress');
          _removeConnection(deviceAddress);
        },
        onError: (error) {
          debugPrint('❌ Connection error with $deviceAddress: $error');
          _removeConnection(deviceAddress);
        },
      );
      
      _updateConnectionStatus();
      debugPrint('✅ Successfully handled incoming connection: $deviceAddress');
    } catch (e) {
      debugPrint('❌ Error handling incoming connection: $e');
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
        try {
          final localName = await FlutterBluetoothSerial.instance.name;
          _userName = localName ?? 'Anonymous User';
        } catch (e) {
          _userName = 'Anonymous User';
        }
        await prefs.setString('user_name', _userName!);
      }

      debugPrint('📱 Device initialized - ID: $_deviceId, Name: $_userName');
    } catch (e) {
      debugPrint('❌ Error initializing device info: $e');
      _deviceId = const Uuid().v4();
      _userName = 'Anonymous User';
    }
  }

  /// Make device discoverable
  Future<void> _makeDiscoverable({int duration = 300}) async {
    try {
      debugPrint('🔍 Making device discoverable for ${duration}s...');
      
      final result = await FlutterBluetoothSerial.instance.requestDiscoverable(duration);
      _isDiscoverable = result == true;
      
      if (_isDiscoverable) {
        debugPrint('✅ Device is now discoverable');
      } else {
        debugPrint('⚠️ Device discoverability request failed');
      }
    } catch (e) {
      debugPrint('❌ Error making device discoverable: $e');
      _isDiscoverable = false;
    }
  }

  /// Start scanning for devices
  Future<void> startScanning({Duration timeout = const Duration(seconds: 30)}) async {
    try {
      if (_isScanning) {
        debugPrint('⚠️ Already scanning for devices');
        return;
      }

      debugPrint('🔍 Started scanning for devices');
      _isScanning = true;
      _discoveredDevices.clear();
      notifyListeners();

      // Get bonded devices first
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      debugPrint('📱 Found ${bondedDevices.length} bonded devices');
      
      for (final device in bondedDevices) {
        if (!_discoveredDevices.any((d) => d.address == device.address)) {
          _discoveredDevices.add(device);
          debugPrint('🔗 Bonded device: ${device.name} (${device.address})');
        }
      }

      // Start discovery for new devices
      StreamSubscription<BluetoothDiscoveryResult>? discoverySubscription;
      
      discoverySubscription = FlutterBluetoothSerial.instance.startDiscovery().listen(
        (BluetoothDiscoveryResult result) {
          final device = result.device;
          debugPrint('🆕 Discovered device: ${device.name} (${device.address})');
          
          if (!_discoveredDevices.any((d) => d.address == device.address)) {
            _discoveredDevices.add(device);
            _devicesController.add(List.from(_discoveredDevices));
          }
        },
        onDone: () {
          debugPrint('✅ Device discovery completed');
          _isScanning = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('❌ Discovery error: $error');
          _isScanning = false;
          notifyListeners();
        },
      );

      // Stop discovery after timeout
      Timer(timeout, () {
        if (_isScanning) {
          debugPrint('⏰ Discovery timeout, stopping scan');
          discoverySubscription?.cancel();
          FlutterBluetoothSerial.instance.cancelDiscovery();
          _isScanning = false;
          notifyListeners();
        }
      });

      _devicesController.add(List.from(_discoveredDevices));
    } catch (e) {
      debugPrint('❌ Error scanning for devices: $e');
      _isScanning = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Connect to a specific device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      debugPrint('🔗 Connecting to device: ${device.name} (${device.address})');
      
      // Check if already connected
      if (_connections.containsKey(device.address)) {
        debugPrint('⚠️ Already connected to ${device.address}');
        return true;
      }

      // Attempt connection
      final connection = await BluetoothConnection.toAddress(device.address);
      debugPrint('✅ Connected to ${device.address}');
      
      // Store connection
      _connections[device.address] = connection;
      _connectedDevices[device.address] = device;
      _messageBuffers[device.address] = StringBuffer();
      
      // Listen for incoming messages
      _connectionListeners[device.address] = connection.input!.listen(
        (Uint8List data) {
          _handleIncomingData(device.address, data);
        },
        onDone: () {
          debugPrint('🔌 Connection closed by: ${device.address}');
          _removeConnection(device.address);
        },
        onError: (error) {
          debugPrint('❌ Connection error with ${device.address}: $error');
          _removeConnection(device.address);
        },
      );
      
      _updateConnectionStatus();
      
      // Send queued messages if any
      await _sendQueuedMessages(device.address);
      
      return true;
    } catch (e) {
      debugPrint('❌ Error connecting to device ${device.address}: $e');
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
        final localName = await FlutterBluetoothSerial.instance.name;
        _userName = localName ?? 'Anonymous User';
        await prefs.setString('user_name', _userName!);
      }

      debugPrint('📱 Device initialized - ID: $_deviceId, Name: $_userName');
    } catch (e) {
      debugPrint('❌ Error initializing device info: $e');
      _deviceId = const Uuid().v4();
      _userName = 'Anonymous User';
    }
  }

  /// Start RFCOMM server to accept incoming connections
  Future<void> _startServer() async {
    try {
      debugPrint('🏃 Starting RFCOMM server...');
      
      // Listen for incoming connections
      _serverSubscription = FlutterBluetoothSerial.instance
          .listenUsingRfcomm()
          .listen((BluetoothConnection connection) {
        debugPrint('📞 Incoming connection from: ${connection.remoteAddress}');
        _handleIncomingConnection(connection);
      });

      _isServerRunning = true;
      debugPrint('✅ RFCOMM server started successfully');
    } catch (e) {
      debugPrint('❌ Error starting server: $e');
      _isServerRunning = false;
    }
  }

  /// Handle incoming Bluetooth connection
  void _handleIncomingConnection(BluetoothConnection connection) {
    try {
      final deviceAddress = connection.remoteAddress;
      debugPrint('🤝 Handling connection from: $deviceAddress');
      
      // Store connection
      _connections[deviceAddress] = connection;
      _messageBuffers[deviceAddress] = StringBuffer();
      
      // Create mock device object for UI
      final device = BluetoothDevice(
        name: 'Incoming Device',
        address: deviceAddress,
        type: BluetoothDeviceType.unknown,
        bondState: BluetoothBondState.bonded,
        isConnected: true,
      );
      
      _connectedDevices[deviceAddress] = device;
      
      // Listen for incoming messages
      _connectionListeners[deviceAddress] = connection.input!.listen(
        (Uint8List data) {
          _handleIncomingData(deviceAddress, data);
        },
        onDone: () {
          debugPrint('🔌 Connection closed by: $deviceAddress');
          _removeConnection(deviceAddress);
        },
        onError: (error) {
          debugPrint('❌ Connection error with $deviceAddress: $error');
          _removeConnection(deviceAddress);
        },
      );
      
      _updateConnectionStatus();
      debugPrint('✅ Successfully handled incoming connection: $deviceAddress');
  /// Handle incoming data from a connection
  void _handleIncomingData(String deviceAddress, Uint8List data) {
    try {
      final String dataString = utf8.decode(data);
      debugPrint('📥 Received data from $deviceAddress: ${dataString.length} bytes');
      
      // Add to message buffer
      _messageBuffers[deviceAddress]!.write(dataString);
      
      // Check for complete messages
      final buffer = _messageBuffers[deviceAddress]!.toString();
      final messages = buffer.split(messageDelimiter);
      
      // Process all complete messages
      for (int i = 0; i < messages.length - 1; i++) {
        final messageJson = messages[i].trim();
        if (messageJson.isNotEmpty) {
          _processReceivedMessage(deviceAddress, messageJson);
        }
      }
      
      // Keep the last incomplete message in buffer
      _messageBuffers[deviceAddress]!.clear();
      if (messages.isNotEmpty) {
        _messageBuffers[deviceAddress]!.write(messages.last);
      }
    } catch (e) {
      debugPrint('❌ Error handling incoming data: $e');
    }
  }

  /// Process a received message
  void _processReceivedMessage(String deviceAddress, String messageJson) {
    try {
      debugPrint('📨 Processing message from $deviceAddress: $messageJson');
      
      final Map<String, dynamic> data = jsonDecode(messageJson);
      final message = DisasterMessage.fromJson(data);
      
      // Add device info if not present
      final device = _connectedDevices[deviceAddress];
      if (device != null && message.senderName == 'Unknown') {
        // Try to get device name
        message.senderName = device.name?.isNotEmpty == true ? device.name! : 'Remote Device';
      }
      
      // Store message in database
      _messageDb.insertMessage(message);
      
      // Notify listeners
      _messageController.add(message);
      
      debugPrint('✅ Message processed: ${message.type} from ${message.senderName}');
    } catch (e) {
      debugPrint('❌ Error processing received message: $e');
    }
  }

  /// Remove a connection
  void _removeConnection(String deviceAddress) {
    try {
      debugPrint('🗑️ Removing connection: $deviceAddress');
      
      // Cancel listener
      _connectionListeners[deviceAddress]?.cancel();
      _connectionListeners.remove(deviceAddress);
      
      // Close connection
      _connections[deviceAddress]?.dispose();
      _connections.remove(deviceAddress);
      
      // Remove from devices
      _connectedDevices.remove(deviceAddress);
      
      // Clear message buffer
      _messageBuffers.remove(deviceAddress);
      
      _updateConnectionStatus();
      debugPrint('✅ Connection removed: $deviceAddress');
    } catch (e) {
      debugPrint('❌ Error removing connection: $e');
    }
  }

  /// Make device discoverable
  Future<void> _makeDiscoverable({int duration = 300}) async {
    try {
      debugPrint('🔍 Making device discoverable for ${duration}s...');
      
      final result = await FlutterBluetoothSerial.instance.requestDiscoverable(duration);
      _isDiscoverable = result == true;
      
      if (_isDiscoverable) {
        debugPrint('✅ Device is now discoverable');
      } else {
        debugPrint('⚠️ Device discoverability request failed');
      }
    } catch (e) {
      debugPrint('❌ Error making device discoverable: $e');
      _isDiscoverable = false;
    }
  }

  /// Start scanning for devices
  Future<void> startScanning({Duration timeout = const Duration(seconds: 30)}) async {
    try {
      if (_isScanning) {
        debugPrint('⚠️ Already scanning for devices');
        return;
      }

      debugPrint('🔍 Started scanning for devices');
      _isScanning = true;
      _discoveredDevices.clear();
      notifyListeners();

      // Get bonded devices first
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      debugPrint('📱 Found ${bondedDevices.length} bonded devices');
      
      for (final device in bondedDevices) {
        if (!_discoveredDevices.any((d) => d.address == device.address)) {
          _discoveredDevices.add(device);
          debugPrint('🔗 Bonded device: ${device.name} (${device.address})');
        }
      }

      // Start discovery for new devices
      StreamSubscription<BluetoothDiscoveryResult>? discoverySubscription;
      
      discoverySubscription = FlutterBluetoothSerial.instance.startDiscovery().listen(
        (BluetoothDiscoveryResult result) {
          final device = result.device;
          debugPrint('🆕 Discovered device: ${device.name} (${device.address})');
          
          if (!_discoveredDevices.any((d) => d.address == device.address)) {
            _discoveredDevices.add(device);
            _devicesController.add(List.from(_discoveredDevices));
          }
        },
        onDone: () {
          debugPrint('✅ Device discovery completed');
          _isScanning = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('❌ Discovery error: $error');
          _isScanning = false;
          notifyListeners();
        },
      );

      // Stop discovery after timeout
      Timer(timeout, () {
        if (_isScanning) {
          debugPrint('⏰ Discovery timeout, stopping scan');
          discoverySubscription?.cancel();
          FlutterBluetoothSerial.instance.cancelDiscovery();
          _isScanning = false;
          notifyListeners();
        }
      });

      _devicesController.add(List.from(_discoveredDevices));
    } catch (e) {
      debugPrint('❌ Error scanning for devices: $e');
      _isScanning = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Connect to a specific device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      debugPrint('🔗 Connecting to device: ${device.name} (${device.address})');
      
      // Check if already connected
      if (_connections.containsKey(device.address)) {
        debugPrint('⚠️ Already connected to ${device.address}');
        return true;
      }

      // Attempt connection
      final connection = await BluetoothConnection.toAddress(device.address);
      debugPrint('✅ Connected to ${device.address}');
      
      // Store connection
      _connections[device.address] = connection;
      _connectedDevices[device.address] = device;
      _messageBuffers[device.address] = StringBuffer();
      
      // Listen for incoming messages
      _connectionListeners[device.address] = connection.input!.listen(
        (Uint8List data) {
          _handleIncomingData(device.address, data);
        },
        onDone: () {
          debugPrint('🔌 Connection closed by: ${device.address}');
          _removeConnection(device.address);
        },
        onError: (error) {
          debugPrint('❌ Connection error with ${device.address}: $error');
          _removeConnection(device.address);
        },
      );
      
      _updateConnectionStatus();
      
      // Send queued messages if any
      await _sendQueuedMessages(device.address);
      
      return true;
    } catch (e) {
      debugPrint('❌ Error connecting to device ${device.address}: $e');
      return false;
    }
  }

  /// Disconnect from a specific device
  Future<void> disconnectFromDevice(String deviceAddress) async {
    try {
      debugPrint('🔌 Disconnecting from device: $deviceAddress');
      _removeConnection(deviceAddress);
    } catch (e) {
      debugPrint('❌ Error disconnecting from device: $e');
    }
  }

  /// Broadcast message to all connected devices
  Future<void> broadcastMessage(DisasterMessage message) async {
    try {
      debugPrint('📢 Broadcasting message: ${message.type} to ${_connections.length} devices');
      
      // Store message in database
      await _messageDb.insertMessage(message);
      
      // Notify local listeners
      _messageController.add(message);
      
      // Send to all connected devices
      final futures = _connections.keys.map((deviceAddress) => 
          _sendMessageToDevice(deviceAddress, message));
      
      await Future.wait(futures);
      
      debugPrint('✅ Message broadcast completed');
    } catch (e) {
      debugPrint('❌ Error broadcasting message: $e');
      rethrow;
    }
  }

  /// Send message to a specific device
  Future<bool> _sendMessageToDevice(String deviceAddress, DisasterMessage message) async {
    try {
      final connection = _connections[deviceAddress];
      if (connection == null) {
        debugPrint('⚠️ No connection to $deviceAddress, queuing message');
        _queueMessage(deviceAddress, message);
        return false;
      }

      // Serialize message to JSON
      final messageJson = jsonEncode(message.toJson());
      final messageWithDelimiter = messageJson + messageDelimiter;
      final data = utf8.encode(messageWithDelimiter);
      
      debugPrint('📤 Sending to $deviceAddress: ${data.length} bytes');
      
      // Send data
      connection.output.add(data);
      await connection.output.allSent;
      
      debugPrint('✅ Message sent to $deviceAddress');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending message to $deviceAddress: $e');
      _queueMessage(deviceAddress, message);
      return false;
    }
  }

  /// Queue message for later sending
  void _queueMessage(String deviceAddress, DisasterMessage message) {
    _messageQueue.putIfAbsent(deviceAddress, () => []).add(message);
    debugPrint('📝 Message queued for $deviceAddress (${_messageQueue[deviceAddress]!.length} in queue)');
  }

  /// Send queued messages to a device
  Future<void> _sendQueuedMessages(String deviceAddress) async {
    final queue = _messageQueue[deviceAddress];
    if (queue == null || queue.isEmpty) return;

    debugPrint('📤 Sending ${queue.length} queued messages to $deviceAddress');
    
    while (queue.isNotEmpty) {
      final message = queue.removeAt(0);
      final success = await _sendMessageToDevice(deviceAddress, message);
      if (!success) {
        // Re-queue if failed
        queue.insert(0, message);
        break;
      }
    }
    
    if (queue.isEmpty) {
      _messageQueue.remove(deviceAddress);
    }
  }

  /// Send emergency SOS to all devices
  Future<void> sendEmergencySOS() async {
    try {
      final sosMessage = DisasterMessage(
        senderId: _deviceId ?? 'unknown',
        senderName: _userName ?? 'Anonymous',
        content: '🆘 EMERGENCY SOS - Immediate assistance needed! Location unknown.',
        type: MessageType.emergency,
      );

      await broadcastMessage(sosMessage);
      debugPrint('🆘 Emergency SOS sent to all connected devices');
    } catch (e) {
      debugPrint('❌ Error sending emergency SOS: $e');
      rethrow;
    }
  }

  /// Get recent messages from database
  Future<List<DisasterMessage>> getRecentMessages({int limit = 50}) async {
    try {
      return await _messageDb.getRecentMessages(limit: limit);
    } catch (e) {
      debugPrint('❌ Error getting recent messages: $e');
      return [];
    }
  }

  /// Update connection status for UI
  void _updateConnectionStatus() {
    final status = <String, bool>{};
    for (final deviceAddress in _connectedDevices.keys) {
      status[deviceAddress] = _connections.containsKey(deviceAddress);
    }
    _connectionStatusController.add(status);
    notifyListeners();
  }

  /// Dispose of the service
  @override
  void dispose() {
    debugPrint('🧹 Disposing Bluetooth service...');
    
    // Close all connections
    for (final deviceAddress in _connections.keys.toList()) {
      _removeConnection(deviceAddress);
    }
    
    // Close controllers
    _messageController.close();
    _devicesController.close();
    _connectionStatusController.close();
    
    super.dispose();
    debugPrint('✅ Bluetooth service disposed');
  }
}