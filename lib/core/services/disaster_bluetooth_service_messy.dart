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

/// Enhanced Bluetooth service using BLUETOOTH CLASSIC (RFCOMM) for reliable disaster relief communication
/// Implements true phone-to-phone messaging using Bluetooth Classic sockets
class DisasterBluetoothService extends ChangeNotifier {
  static final DisasterBluetoothService _instance = DisasterBluetoothService._internal();
  factory DisasterBluetoothService() => _instance;
  DisasterBluetoothService._internal();

  /// Initialize the Bluetooth Classic service
  Future<bool> initialize() async {
    try {
      debugPrint('🔧 Initializing Bluetooth Classic service...');
      
      // Check if Bluetooth is available
      final isAvailable = await _bluetooth.isAvailable;
      if (!isAvailable) {
        debugPrint('❌ Bluetooth not available on this device');
        return false;
      }

      // Check and request permissions
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint('❌ Bluetooth permissions not granted');
        return false;
      }

      // Check if Bluetooth is enabled
      final isEnabled = await _bluetooth.isEnabled;
      _bluetoothEnabled = isEnabled ?? false;
      debugPrint('📡 Bluetooth state: ${_bluetoothEnabled ? "ON" : "OFF"}');

      if (!_bluetoothEnabled) {
        debugPrint('❌ Bluetooth is disabled. Attempting to enable...');
        // Request to enable Bluetooth
        final enableResult = await _bluetooth.requestEnable();
        _bluetoothEnabled = enableResult ?? false;
        
        if (!_bluetoothEnabled) {
          debugPrint('❌ User denied Bluetooth enable request');
          return false;
        }
      }

      // Initialize device info
      await _initializeDeviceInfo();
      
      // Initialize message database
      await _messageDb.database;
      
      // Load bonded devices
      await _loadBondedDevices();
      
      debugPrint('✅ Bluetooth Classic service initialized successfully');
      debugPrint('📱 Device ID: $_deviceId');
      debugPrint('👤 User Name: $_userName');
      debugPrint('🔗 Bonded devices: ${_bondedDevices.length}');
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing Bluetooth Classic service: $e');
      return false;
    }
  }

  /// Check and request Bluetooth permissions for Android
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
          Permission.location,
        ];
      } else {
        // Older Android versions
        permissions = [
          Permission.bluetooth,
          Permission.bluetoothAdmin,
          Permission.location,
        ];
      }

      // Check and request permissions
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

  /// Load bonded (paired) devices
  Future<void> _loadBondedDevices() async {
    try {
      debugPrint('🔍 Loading bonded devices...');
      final devices = await _bluetooth.getBondedDevices();
      _bondedDevices.clear();
      _validDisasterDevices.clear();
      
      for (final device in devices) {
        _bondedDevices.add(device);
        debugPrint('📱 Bonded device: ${device.name ?? "Unknown"} (${device.address})');
        
        // Check if bonded device is valid for disaster communication
        if (_isValidDisasterDevice(device)) {
          _validDisasterDevices.add(device);
          _updateDeviceStatus(device.address, 'Bonded - Available for connection');
        }
      }
      
      debugPrint('✅ Loaded ${_bondedDevices.length} bonded devices, ${_validDisasterDevices.length} valid for disaster relief');
      _devicesController.add(List.from(_validDisasterDevices));
    } catch (e) {
      debugPrint('❌ Error loading bonded devices: $e');
    }
  }

  // Bluetooth Classic configuration
  static const String serviceName = "DisasterReliefSOS";
  static const String serviceUuid = "00001101-0000-1000-8000-00805F9B34FB"; // Standard Serial Port Profile UUID
  
  // Message delimiter for stream parsing
  static const String messageDelimiter = "\n###END###\n";

  // Bluetooth Classic instance
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  
  // Bluetooth state
  bool _bluetoothEnabled = false;
  bool _isDiscovering = false;
  bool _isDiscoverable = false;
  bool _isServerRunning = false;
  
  // Device discovery and connection management
  final List<BluetoothDevice> _discoveredDevices = [];
  final List<BluetoothDevice> _bondedDevices = [];
  final List<BluetoothDevice> _validDisasterDevices = [];
  
  // Connection management
  final Map<String, BluetoothConnection> _connections = {};
  final Map<String, StreamSubscription> _connectionListeners = {};
  final Map<String, StringBuffer> _messageBuffers = {};
  final Map<String, String> _deviceStatuses = {};
  
  // Server for incoming connections
  BluetoothConnection? _serverConnection;
  StreamSubscription<BluetoothConnection>? _serverSubscription;
  
  // Message handling
  final MessageDatabase _messageDb = MessageDatabase();
  final StreamController<DisasterMessage> _messageController = StreamController<DisasterMessage>.broadcast();
  final StreamController<List<BluetoothDevice>> _devicesController = StreamController<List<BluetoothDevice>>.broadcast();
  final StreamController<Map<String, bool>> _connectionStatusController = StreamController<Map<String, bool>>.broadcast();
  
  // Message queue for failed sends
  final Map<String, List<DisasterMessage>> _messageQueue = {};
  
  // Discovery subscription
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;
  
  // User info
  String? _deviceId;
  String? _userName;

  // Streams
  Stream<DisasterMessage> get messageStream => _messageController.stream;
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<Map<String, bool>> get connectionStatusStream => _connectionStatusController.stream;
  
  // Getters
  bool get bluetoothEnabled => _bluetoothEnabled;
  bool get isDiscovering => _isDiscovering;
  bool get isDiscoverable => _isDiscoverable;
  bool get isServerRunning => _isServerRunning;
  int get connectedDeviceCount => _connections.length;
  Map<String, BluetoothConnection> get connections => Map.unmodifiable(_connections);
  List<BluetoothDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  List<BluetoothDevice> get bondedDevices => List.unmodifiable(_bondedDevices);
  List<BluetoothDevice> get validDisasterDevices => List.unmodifiable(_validDisasterDevices);
  Map<String, String> get deviceStatuses => Map.unmodifiable(_deviceStatuses);
  String? get deviceId => _deviceId;
  String? get userName => _userName;

  /// Check if a discovered device is a valid disaster relief device (real phone/tablet)
  bool _isValidDisasterDevice(BluetoothDevice device) {
    try {
      final name = device.name?.toLowerCase() ?? '';
      final address = device.address;
      
      debugPrint('🔍 Evaluating Bluetooth Classic device: "${device.name ?? "NO_NAME"}" ($address)');
      
      // Accept devices with our disaster app identifier
      if (name.contains('disaster') || name.contains('sos')) {
        debugPrint('✅ ACCEPTED disaster device: "$name" (disaster/sos identifier)');
        return true;
      }
      
      // Accept devices with clear phone/tablet names
      final phonePatterns = [
        'android', 'iphone', 'samsung', 'pixel', 'galaxy', 'huawei', 
        'xiaomi', 'oneplus', 'oppo', 'vivo', 'realme', 'nokia', 'lg',
        'sony', 'motorola', 'tablet', 'ipad', 'phone'
      ];
      
      for (final pattern in phonePatterns) {
        if (name.contains(pattern)) {
          debugPrint('✅ ACCEPTED phone/tablet: "$name" (pattern: $pattern)');
          return true;
        }
      }
      
      // For bonded devices, be more permissive (user already paired them)
      if (device.isBonded) {
        debugPrint('✅ ACCEPTED bonded device: "$name" (user previously paired)');
        return true;
      }
      
      // Reject known accessories
      final rejectPatterns = [
        'watch', 'buds', 'pods', 'airpods', 'tv', 'speaker', 'headset', 'earphone',
        'fitness', 'tracker', 'band', 'car', 'audio'
      ];
      
      for (final pattern in rejectPatterns) {
        if (name.contains(pattern)) {
          debugPrint('❌ REJECTED accessory: "$name" (pattern: $pattern)');
          return false;
        }
      }
      
      // For devices with no clear indicators, reject to avoid clutter
      debugPrint('❌ REJECTED: Unknown device type "$name"');
      return false;
      
    } catch (e) {
      debugPrint('❌ Error evaluating device ${device.address}: $e');
      return false;
    }
  }
  }

  /// Start disaster mode - begin RFCOMM server and device discovery simultaneously
  Future<void> startDisasterMode({Duration timeout = const Duration(seconds: 30)}) async {
    try {
      debugPrint('🚨 Starting Disaster Mode - RFCOMM Server & Discovery');
      
      // Initialize if not already done
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Failed to initialize Bluetooth Classic service');
      }
      
      // Start RFCOMM server for incoming connections
      await _startServer();
      
      // Make device discoverable
      await _makeDiscoverable();
      
      // Start discovering other devices
      await _startDiscovery(timeout: timeout);
      
      // Try to connect to bonded devices
      await _connectToBondedDevices();
      
      debugPrint('✅ Disaster Mode active - Server running, discoverable, and searching');
    } catch (e) {
      debugPrint('❌ Error starting disaster mode: $e');
      rethrow;
    }
  }

  /// Start RFCOMM server to accept incoming connections
  Future<void> _startServer() async {
    try {
      if (_isServerRunning) {
        debugPrint('⚠️ RFCOMM server already running');
        return;
      }

      debugPrint('🖥️ Starting RFCOMM server...');
      
      // Listen for incoming connections
      _serverSubscription = _bluetooth.listen().listen(
        (BluetoothConnection connection) {
          debugPrint('📞 Incoming RFCOMM connection from ${connection.remoteAddress}');
          _handleIncomingConnection(connection);
        },
        onError: (error) {
          debugPrint('❌ RFCOMM server error: $error');
        },
      );
      
      _isServerRunning = true;
      debugPrint('✅ RFCOMM server started and listening');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error starting RFCOMM server: $e');
      _isServerRunning = false;
    }
  }

  /// Handle incoming RFCOMM connection
  void _handleIncomingConnection(BluetoothConnection connection) {
    try {
      final deviceAddress = connection.remoteAddress;
      debugPrint('🤝 Accepting connection from $deviceAddress');
      
      // Store connection
      _connections[deviceAddress] = connection;
      
      // Setup message listener
      _setupConnectionListener(deviceAddress, connection);
      
      // Update status
      _updateDeviceStatus(deviceAddress, 'Connected (Incoming)');
      _updateConnectionStatus();
      
      debugPrint('✅ Connection established with $deviceAddress');
    } catch (e) {
      debugPrint('❌ Error handling incoming connection: $e');
    }
  }

  /// Make device discoverable to other devices
  Future<void> _makeDiscoverable() async {
    try {
      if (_isDiscoverable) {
        debugPrint('⚠️ Device already discoverable');
        return;
      }

      debugPrint('📡 Making device discoverable...');
      
      // Request discoverability for 300 seconds (5 minutes)
      final result = await _bluetooth.requestDiscoverable(300);
      _isDiscoverable = result ?? false;
      
      if (_isDiscoverable) {
        debugPrint('✅ Device is now discoverable for 5 minutes');
      } else {
        debugPrint('❌ Failed to make device discoverable');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error making device discoverable: $e');
    }
  }

  /// Start Bluetooth Classic device discovery
  Future<void> _startDiscovery({Duration timeout = const Duration(seconds: 30)}) async {
    try {
      if (_isDiscovering) {
        debugPrint('⚠️ Already discovering devices');
        return;
      }

      debugPrint('🔍 Starting Bluetooth Classic device discovery...');
      _isDiscovering = true;
      _discoveredDevices.clear();
      _validDisasterDevices.clear();
      _updateDeviceStatus('system', 'Discovering devices...');
      notifyListeners();

      // Start discovery
      final isStarted = await _bluetooth.startDiscovery();
      if (!isStarted) {
        debugPrint('❌ Failed to start discovery');
        _isDiscovering = false;
        return;
      }

      int rawDeviceCount = 0;
      int rejectedCount = 0;
      int acceptedCount = 0;

      // Listen to discovery results
      _discoverySubscription = _bluetooth.onDiscoveryResult?.listen(
        (BluetoothDiscoveryResult result) {
          final device = result.device;
          
          // Skip if already discovered
          if (_discoveredDevices.any((d) => d.address == device.address)) {
            return;
          }
          
          _discoveredDevices.add(device);
          rawDeviceCount++;
          
          final deviceName = device.name ?? "NO_NAME";
          debugPrint('🆕 CLASSIC DISCOVERY #$rawDeviceCount: "$deviceName" (${device.address})');
          
          // Apply filtering for valid disaster devices
          final isValid = _isValidDisasterDevice(device);
          if (isValid) {
            acceptedCount++;
            _validDisasterDevices.add(device);
            _updateDeviceStatus(device.address, 'Found valid device: $deviceName');
            
            debugPrint('✅ ADDED TO VALID LIST #$acceptedCount: "$deviceName"');
          } else {
            rejectedCount++;
            debugPrint('❌ REJECTED #$rejectedCount: "$deviceName"');
          }
          
          // Log stats every 5 devices
          if (rawDeviceCount % 5 == 0) {
            debugPrint('📊 DISCOVERY STATS: Raw=$rawDeviceCount, Accepted=$acceptedCount, Rejected=$rejectedCount');
          }
          
          // Update UI with discovered devices
          if (_validDisasterDevices.length <= 10) { // Limit to 10 valid devices max for Bluetooth Classic
            debugPrint('📋 Updating UI with ${_validDisasterDevices.length} valid devices');
            _devicesController.add(List.from(_validDisasterDevices));
          } else {
            debugPrint('⚠️ Too many valid devices (${_validDisasterDevices.length}), limiting to first 10');
            _devicesController.add(_validDisasterDevices.take(10).toList());
          }
        },
        onError: (error) {
          debugPrint('❌ Discovery error: $error');
          _isDiscovering = false;
          _updateDeviceStatus('system', 'Discovery error: $error');
          notifyListeners();
        },
      );

      // Stop discovery after timeout
      Timer(timeout, () async {
        if (_isDiscovering) {
          debugPrint('⏰ Discovery timeout, stopping discovery');
          debugPrint('📊 FINAL DISCOVERY STATS: Raw=$rawDeviceCount, Accepted=$acceptedCount, Rejected=$rejectedCount');
          await _stopDiscovery();
        }
      });

      _devicesController.add(List.from(_validDisasterDevices));
    } catch (e) {
      debugPrint('❌ Error starting discovery: $e');
      _isDiscovering = false;
      _updateDeviceStatus('system', 'Discovery failed: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Stop Bluetooth Classic discovery
  Future<void> _stopDiscovery() async {
    try {
      if (_isDiscovering) {
        debugPrint('🛑 Stopping Bluetooth Classic discovery...');
        
        await _bluetooth.cancelDiscovery();
        _discoverySubscription?.cancel();
        _discoverySubscription = null;
        
        _isDiscovering = false;
        debugPrint('✅ Discovery stopped');
        debugPrint('📋 Final discovered devices: ${_discoveredDevices.length}');
        debugPrint('✅ Valid disaster devices: ${_validDisasterDevices.length}');
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error stopping discovery: $e');
      _isDiscovering = false;
      notifyListeners();
    }
  }

  /// Connect to bonded devices that are valid for disaster communication
  Future<void> _connectToBondedDevices() async {
    try {
      debugPrint('🔗 Attempting to connect to bonded disaster devices...');
      
      for (final device in _validDisasterDevices.where((d) => _bondedDevices.any((b) => b.address == d.address))) {
        try {
          debugPrint('🤝 Attempting connection to bonded device: ${device.name ?? "Unknown"} (${device.address})');
          await _connectToDevice(device);
          
          // Small delay between connection attempts
          await Future.delayed(const Duration(milliseconds: 1000));
        } catch (e) {
          debugPrint('❌ Failed to connect to bonded device ${device.address}: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error connecting to bonded devices: $e');
    }
  }

  /// Automatically connect to a discovered disaster device
  Future<void> _autoConnectToDevice(BluetoothDevice device) async {
    try {
      final deviceId = device.remoteId.str;
      
      // Skip if already connected or connecting
      if (_connectedDevices.containsKey(deviceId) || 
          _deviceStatuses[deviceId] == 'Connecting...') {
        return;
      }
      
      _updateDeviceStatus(deviceId, 'Connecting...');
      
      // Small delay to avoid connection conflicts
      await Future.delayed(const Duration(milliseconds: 500));
      
      final success = await connectToDevice(device);
      if (success) {
        debugPrint('✅ Auto-connection successful to ${device.advName}');
      } else {
        debugPrint('❌ Auto-connection failed to ${device.advName}');
      }
    } catch (e) {
      debugPrint('❌ Error in auto-connection to ${device.remoteId}: $e');
      _updateDeviceStatus(device.remoteId.str, 'Connection failed');
    }
  }

  /// Update device status for UI feedback
  void _updateDeviceStatus(String deviceId, String status) {
    _deviceStatuses[deviceId] = status;
    debugPrint('📊 Device status updated - $deviceId: $status');
    notifyListeners();
  }

  /// Connect to a specific Bluetooth Classic device using RFCOMM
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      final deviceAddress = device.address;
      
      // Skip if already connected or connecting
      if (_connections.containsKey(deviceAddress) || 
          _deviceStatuses[deviceAddress] == 'Connecting...') {
        debugPrint('⚠️ Already connected or connecting to $deviceAddress');
        return;
      }
      
      debugPrint('🔗 Connecting to Bluetooth Classic device: ${device.name ?? "Unknown"} ($deviceAddress)');
      _updateDeviceStatus(deviceAddress, 'Connecting...');
      
      // Connect using RFCOMM
      final connection = await BluetoothConnection.toAddress(deviceAddress);
      
      // Store connection
      _connections[deviceAddress] = connection;
      
      // Setup message listener
      _setupConnectionListener(deviceAddress, connection);
      
      // Update status
      _updateDeviceStatus(deviceAddress, 'Connected');
      _updateConnectionStatus();
      
      debugPrint('✅ Successfully connected to $deviceAddress');
    } catch (e) {
      debugPrint('❌ Failed to connect to ${device.address}: $e');
      _updateDeviceStatus(device.address, 'Connection failed');
      _connections.remove(device.address);
    }
  }

  /// Setup message listener for an RFCOMM connection
  void _setupConnectionListener(String deviceAddress, BluetoothConnection connection) {
    // Initialize message buffer for this device
    _messageBuffers[deviceAddress] = StringBuffer();
    
    // Listen for incoming data
    _connectionListeners[deviceAddress] = connection.input?.listen(
      (Uint8List data) {
        try {
          final receivedText = String.fromCharCodes(data);
          _messageBuffers[deviceAddress]!.write(receivedText);
          
          // Check for complete messages
          _processMessageBuffer(deviceAddress);
        } catch (e) {
          debugPrint('❌ Error processing received data from $deviceAddress: $e');
        }
      },
      onError: (error) {
        debugPrint('❌ Connection error with $deviceAddress: $error');
        _handleConnectionError(deviceAddress);
      },
      onDone: () {
        debugPrint('📪 Connection closed with $deviceAddress');
        _handleConnectionClosed(deviceAddress);
      },
    );
  }

  /// Process message buffer to extract complete messages
  void _processMessageBuffer(String deviceAddress) {
    final buffer = _messageBuffers[deviceAddress]!;
    final content = buffer.toString();
    
    while (content.contains(messageDelimiter)) {
      final delimiterIndex = content.indexOf(messageDelimiter);
      final messageJson = content.substring(0, delimiterIndex);
      
      try {
        final messageData = json.decode(messageJson);
        final message = DisasterMessage.fromJson(messageData);
        
        debugPrint('📨 Received message from $deviceAddress: ${message.content}');
        
        // Store message in database
        _messageDb.insertMessage(message);
        
        // Notify listeners
        _messageController.add(message);
        
        // Send acknowledgment
        _sendAcknowledgment(deviceAddress, message.id);
        
      } catch (e) {
        debugPrint('❌ Error parsing message from $deviceAddress: $e');
      }
      
      // Remove processed message from buffer
      buffer.clear();
      buffer.write(content.substring(delimiterIndex + messageDelimiter.length));
    }
  }

  /// Handle connection error
  void _handleConnectionError(String deviceAddress) {
    _updateDeviceStatus(deviceAddress, 'Connection error');
    _cleanupConnection(deviceAddress);
  }

  /// Handle connection closed
  void _handleConnectionClosed(String deviceAddress) {
    _updateDeviceStatus(deviceAddress, 'Disconnected');
    _cleanupConnection(deviceAddress);
  }

  /// Cleanup connection resources
  void _cleanupConnection(String deviceAddress) {
    _connectionListeners[deviceAddress]?.cancel();
    _connectionListeners.remove(deviceAddress);
    _connections.remove(deviceAddress);
    _messageBuffers.remove(deviceAddress);
    _updateConnectionStatus();
  }

  /// Update connection status stream
  void _updateConnectionStatus() {
    final connectionStatus = <String, bool>{};
    for (final address in _connections.keys) {
      connectionStatus[address] = true;
    }
    _connectionStatusController.add(connectionStatus);
  }

  /// Send acknowledgment for received message
  Future<void> _sendAcknowledgment(String deviceAddress, String messageId) async {
    try {
      final ackMessage = {
        'type': 'acknowledgment',
        'messageId': messageId,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceId': _deviceId,
      };
      
      final ackJson = json.encode(ackMessage) + messageDelimiter;
      final connection = _connections[deviceAddress];
      
      if (connection != null) {
        connection.output.add(Uint8List.fromList(ackJson.codeUnits));
        await connection.output.allSent;
        debugPrint('✅ Sent acknowledgment for message $messageId to $deviceAddress');
      }
    } catch (e) {
      debugPrint('❌ Error sending acknowledgment: $e');
    }
  }

  /// Send message to all connected devices using RFCOMM
  Future<void> sendMessage(DisasterMessage message) async {
    try {
      debugPrint('📤 Sending message to ${_connections.length} connected devices: ${message.content}');
      
      // Store message in database
      await _messageDb.insertMessage(message);
      
      if (_connections.isEmpty) {
        debugPrint('⚠️ No connected devices to send message to');
        return;
      }

      // Send to all connected devices
      final futures = <Future>[];
      for (final deviceAddress in _connections.keys) {
        futures.add(_sendMessageToDevice(deviceAddress, message));
      }
      
      await Future.wait(futures);
      debugPrint('✅ Message sent to all connected devices');
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      rethrow;
    }
  }

  /// Send message to a specific device via RFCOMM
  Future<void> _sendMessageToDevice(String deviceAddress, DisasterMessage message) async {
    try {
      final connection = _connections[deviceAddress];
      if (connection == null) {
        debugPrint('❌ No connection to device $deviceAddress');
        return;
      }

      // Prepare message as JSON
      final messageJson = json.encode(message.toJson()) + messageDelimiter;
      final data = Uint8List.fromList(messageJson.codeUnits);

      // Send via RFCOMM
      connection.output.add(data);
      await connection.output.allSent;
      
      debugPrint('✅ Message sent to $deviceAddress: ${message.content}');
    } catch (e) {
      debugPrint('❌ Error sending message to $deviceAddress: $e');
      
      // Queue message for retry if connection failed
      _queueMessage(deviceAddress, message);
    }
  }

  /// Queue message for retry when connection is restored
  void _queueMessage(String deviceAddress, DisasterMessage message) {
    _messageQueue[deviceAddress] ??= [];
    _messageQueue[deviceAddress]!.add(message);
    debugPrint('📝 Message queued for $deviceAddress: ${message.content}');
  }

  /// Send queued messages when connection is restored
  Future<void> _sendQueuedMessages(String deviceAddress) async {
    try {
      final queuedMessages = _messageQueue[deviceAddress];
      if (queuedMessages == null || queuedMessages.isEmpty) {
        return;
      }

      debugPrint('📮 Sending ${queuedMessages.length} queued messages to $deviceAddress');
      
      for (final message in queuedMessages) {
        await _sendMessageToDevice(deviceAddress, message);
        // Small delay between messages
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Clear queue after successful send
      _messageQueue[deviceAddress]?.clear();
      debugPrint('✅ Queued messages sent to $deviceAddress');
    } catch (e) {
      debugPrint('❌ Error sending queued messages to $deviceAddress: $e');
    }
  }

  /// Get all messages from database
  Future<List<DisasterMessage>> getAllMessages() async {
    try {
      return await _messageDb.getAllMessages();
    } catch (e) {
      debugPrint('❌ Error getting messages: $e');
      return [];
    }
  }

  /// Cleanup resources
  void dispose() {
    try {
      debugPrint('🧹 Disposing Bluetooth Classic service...');
      
      // Stop discovery
      _stopDiscovery();
      
      // Stop server
      _stopServer();
      
      // Disconnect all devices
      _disconnectAllDevices();
      
      // Cancel all listeners
      for (final subscription in _connectionListeners.values) {
        subscription.cancel();
      }
      _connectionListeners.clear();
      
      // Close streams
      _messageController.close();
      _devicesController.close();
      _connectionStatusController.close();
      
      // Clear collections
      _connections.clear();
      _messageBuffers.clear();
      _deviceStatuses.clear();
      _messageQueue.clear();
      
      super.dispose();
      debugPrint('✅ Bluetooth Classic service disposed');
    } catch (e) {
      debugPrint('❌ Error disposing service: $e');
    }
  }

  /// Public method to connect to a device (called from UI)
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await _connectToDevice(device);
      return true;
    } catch (e) {
      debugPrint('❌ Public connectToDevice failed: $e');
      return false;
    }
  }

  /// Stop disaster mode
  Future<void> stopDisasterMode() async {
    try {
      debugPrint('🛑 Stopping Disaster Mode...');
      
      // Stop discovery
      await _stopDiscovery();
      
      // Stop server
      await _stopServer();
      
      // Disconnect from all devices
      await _disconnectAllDevices();
      
      // Stop discoverability
      _isDiscoverable = false;
      
      debugPrint('✅ Disaster Mode stopped');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error stopping disaster mode: $e');
    }
  }

  /// Stop RFCOMM server
  Future<void> _stopServer() async {
    try {
      if (_isServerRunning) {
        _serverSubscription?.cancel();
        _serverSubscription = null;
        _serverConnection?.close();
        _serverConnection = null;
        _isServerRunning = false;
        debugPrint('✅ RFCOMM server stopped');
      }
    } catch (e) {
      debugPrint('❌ Error stopping server: $e');
    }
  }

  /// Disconnect from all connected devices
  Future<void> _disconnectAllDevices() async {
    try {
      final addresses = List<String>.from(_connections.keys);
      for (final address in addresses) {
        await _disconnectFromDevice(address);
      }
      debugPrint('✅ Disconnected from all devices');
    } catch (e) {
      debugPrint('❌ Error disconnecting from all devices: $e');
    }
  }

  /// Disconnect from a specific device
  Future<void> _disconnectFromDevice(String deviceAddress) async {
    try {
      final connection = _connections[deviceAddress];
      if (connection != null) {
        await connection.close();
        _cleanupConnection(deviceAddress);
        debugPrint('✅ Disconnected from $deviceAddress');
      }
    } catch (e) {
      debugPrint('❌ Error disconnecting from $deviceAddress: $e');
    }
  }

  /// Connect to a specific BLE device with bidirectional communication setup
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      final deviceId = device.remoteId.str;
      debugPrint('🔗 Connecting to disaster device: ${device.advName.isEmpty ? "Unknown" : device.advName} (${device.remoteId})');
      
      // Check if already connected
      if (_connectedDevices.containsKey(deviceId)) {
        debugPrint('⚠️ Already connected to $deviceId');
        return true;
      }

      _updateDeviceStatus(deviceId, 'Connecting...');

      // Connect to the device with extended timeout
      await device.connect(timeout: const Duration(seconds: 20));
      debugPrint('✅ Physical connection established to $deviceId');
      
      // Discover all services
      final services = await device.discoverServices();
      debugPrint('🔍 Discovered ${services.length} services on $deviceId');
      
      // First, try to find our custom disaster service
      BluetoothService? targetService;
      for (final service in services) {
        debugPrint('📋 Service found: ${service.uuid}');
        if (service.uuid.toString().toUpperCase() == serviceUuid.toUpperCase()) {
          targetService = service;
          debugPrint('✅ Found disaster service on $deviceId');
          break;
        }
      }
      
      // If no custom service, look for standard UART service or create virtual characteristics
      if (targetService == null) {
        debugPrint('⚠️ Custom disaster service not found, looking for standard services...');
        
        // Look for Nordic UART service as fallback
        const String nordicUartService = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
        for (final service in services) {
          if (service.uuid.toString().toUpperCase() == nordicUartService.toUpperCase()) {
            targetService = service;
            debugPrint('✅ Found Nordic UART service as fallback on $deviceId');
            break;
          }
        }
      }
      
      if (targetService == null) {
        debugPrint('❌ No compatible service found on $deviceId');
        await device.disconnect();
        _updateDeviceStatus(deviceId, 'No compatible service');
        return false;
      }
      
      // Find compatible characteristics
      BluetoothCharacteristic? writeChar;
      BluetoothCharacteristic? notifyChar;
      
      for (final characteristic in targetService.characteristics) {
        debugPrint('🔍 Characteristic: ${characteristic.uuid} - Properties: ${characteristic.properties}');
        
        // Look for write characteristic
        if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
          writeChar = characteristic;
          debugPrint('✅ Found write characteristic: ${characteristic.uuid}');
        }
        
        // Look for notify/indicate characteristic
        if (characteristic.properties.notify || characteristic.properties.indicate) {
          notifyChar = characteristic;
          debugPrint('✅ Found notify characteristic: ${characteristic.uuid}');
        }
      }
      
      // For devices without proper characteristics, use the first available ones
      if (writeChar == null && targetService.characteristics.isNotEmpty) {
        writeChar = targetService.characteristics.first;
        debugPrint('⚠️ Using first characteristic as write: ${writeChar.uuid}');
      }
      
      if (notifyChar == null && targetService.characteristics.length > 1) {
        notifyChar = targetService.characteristics[1];
        debugPrint('⚠️ Using second characteristic as notify: ${notifyChar.uuid}');
      } else if (notifyChar == null && writeChar != null) {
        notifyChar = writeChar; // Use same characteristic for bidirectional
        debugPrint('⚠️ Using same characteristic for bidirectional communication');
      }
      
      if (writeChar == null) {
        debugPrint('❌ No writable characteristic found on $deviceId');
        await device.disconnect();
        _updateDeviceStatus(deviceId, 'No writable characteristic');
        return false;
      }
      
      // Store connection info
      _connectedDevices[deviceId] = device;
      _writeCharacteristics[deviceId] = writeChar;
      _messageBuffers[deviceId] = StringBuffer();
      
      // Setup notifications if available
      if (notifyChar != null && (notifyChar.properties.notify || notifyChar.properties.indicate)) {
        try {
          await notifyChar.setNotifyValue(true);
          debugPrint('✅ Notifications enabled on $deviceId');
          
          // Listen for incoming messages
          _notifySubscriptions[deviceId] = notifyChar.lastValueStream.listen(
            (value) {
              if (value.isNotEmpty) {
                debugPrint('📥 Received ${value.length} bytes from $deviceId');
                _handleIncomingData(deviceId, Uint8List.fromList(value));
              }
            },
            onError: (error) {
              debugPrint('❌ Notification error with $deviceId: $error');
              _updateDeviceStatus(deviceId, 'Notification error');
            },
          );
        } catch (e) {
          debugPrint('⚠️ Could not enable notifications on $deviceId: $e');
        }
      }
      
      // Listen for disconnection
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          debugPrint('🔌 Device disconnected: $deviceId');
          _removeConnection(deviceId);
        }
      });
      
      _updateDeviceStatus(deviceId, 'Connected');
      _updateConnectionStatus();
      
      // Send a connection handshake message
      await _sendHandshakeMessage(deviceId);
      
      // Send queued messages if any
      await _sendQueuedMessages(deviceId);
      
      debugPrint('✅ Successfully connected to disaster device: $deviceId');
      return true;
    } catch (e) {
      debugPrint('❌ Error connecting to device ${device.remoteId}: $e');
      _updateDeviceStatus(device.remoteId.str, 'Connection failed: $e');
      return false;
    }
  }

  /// Send handshake message to establish communication protocol
  Future<void> _sendHandshakeMessage(String deviceId) async {
    try {
      final handshakeMessage = DisasterMessage(
        senderId: _deviceId ?? 'unknown',
        senderName: _userName ?? 'Anonymous',
        content: '🤝 Connected to disaster relief network',
        type: MessageType.system,
        metadata: {
          'handshake': true,
          'device_type': 'android', // or detect actual device type
          'app_version': '1.0.0',
        },
      );
      
      await _sendMessageToDevice(deviceId, handshakeMessage);
      debugPrint('🤝 Handshake sent to $deviceId');
    } catch (e) {
      debugPrint('❌ Error sending handshake to $deviceId: $e');
    }
  }

  /// Handle incoming data from a BLE device
  void _handleIncomingData(String deviceId, Uint8List data) {
    try {
      final String dataString = utf8.decode(data);
      debugPrint('📥 Received data from $deviceId: ${dataString.length} bytes');
      
      // Add to message buffer
      _messageBuffers[deviceId]!.write(dataString);
      
      // Check for complete messages
      final buffer = _messageBuffers[deviceId]!.toString();
      final messages = buffer.split(messageDelimiter);
      
      // Process all complete messages
      for (int i = 0; i < messages.length - 1; i++) {
        final messageJson = messages[i].trim();
        if (messageJson.isNotEmpty) {
          _processReceivedMessage(deviceId, messageJson);
        }
      }
      
      // Keep the last incomplete message in buffer
      _messageBuffers[deviceId]!.clear();
      if (messages.isNotEmpty) {
        _messageBuffers[deviceId]!.write(messages.last);
      }
    } catch (e) {
      debugPrint('❌ Error handling incoming data: $e');
    }
  }

  /// Process a received message
  void _processReceivedMessage(String deviceId, String messageJson) {
    try {
      debugPrint('📨 Processing message from $deviceId: $messageJson');
      
      final Map<String, dynamic> data = jsonDecode(messageJson);
      final message = DisasterMessage.fromJson(data);
      
      // Add device info if not present
      final device = _connectedDevices[deviceId];
      if (device != null && message.senderName == 'Unknown') {
        // Try to get device name
        final deviceName = device.advName.isNotEmpty ? device.advName : 'Remote Device';
        // Create a new message with updated sender name
        final updatedMessage = DisasterMessage(
          senderId: message.senderId,
          senderName: deviceName,
          content: message.content,
          type: message.type,
          metadata: message.metadata,
          timestamp: message.timestamp,
        );
        
        // Store updated message in database
        _messageDb.insertMessage(updatedMessage);
        
        // Notify listeners
        _messageController.add(updatedMessage);
      } else {
        // Store original message in database
        _messageDb.insertMessage(message);
        
        // Notify listeners
        _messageController.add(message);
      }
      
      debugPrint('✅ Message processed: ${message.type} from ${message.senderName}');
    } catch (e) {
      debugPrint('❌ Error processing received message: $e');
    }
  }

  /// Remove a BLE connection with proper cleanup
  void _removeConnection(String deviceId) {
    try {
      debugPrint('🗑️ Removing connection: $deviceId');
      
      // Cancel notification subscription
      _notifySubscriptions[deviceId]?.cancel();
      _notifySubscriptions.remove(deviceId);
      
      // Disconnect device
      final device = _connectedDevices[deviceId];
      if (device != null) {
        device.disconnect();
      }
      
      // Remove from collections
      _connectedDevices.remove(deviceId);
      _writeCharacteristics.remove(deviceId);
      _messageBuffers.remove(deviceId);
      
      // Update status
      _updateDeviceStatus(deviceId, 'Disconnected');
      _updateConnectionStatus();
      
      debugPrint('✅ Connection removed: $deviceId');
    } catch (e) {
      debugPrint('❌ Error removing connection: $e');
    }
  }

  /// Update connection status for UI with detailed information
  void _updateConnectionStatus() {
    final status = <String, bool>{};
    for (final deviceId in _connectedDevices.keys) {
      final device = _connectedDevices[deviceId];
      final isConnected = device?.isConnected ?? false;
      status[deviceId] = isConnected;
      
      if (isConnected) {
        _updateDeviceStatus(deviceId, 'Connected');
      }
    }
    _connectionStatusController.add(status);
    notifyListeners();
  }

  /// Disconnect from a specific device
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      debugPrint('🔌 Disconnecting from device: $deviceId');
      _removeConnection(deviceId);
    } catch (e) {
      debugPrint('❌ Error disconnecting from device: $e');
    }
  }

  /// Broadcast message to all connected devices
  Future<void> broadcastMessage(DisasterMessage message) async {
    try {
      debugPrint('📢 Broadcasting message: ${message.type} to ${_connectedDevices.length} devices');
      
      // Store message in database
      await _messageDb.insertMessage(message);
      
      // Notify local listeners
      _messageController.add(message);
      
      // Send to all connected devices
      final futures = _connectedDevices.keys.map((deviceId) => 
          _sendMessageToDevice(deviceId, message));
      
      await Future.wait(futures);
      
      debugPrint('✅ Message broadcast completed');
    } catch (e) {
      debugPrint('❌ Error broadcasting message: $e');
      rethrow;
    }
  }

  /// Send message to a specific device with improved GATT communication
  Future<bool> _sendMessageToDevice(String deviceId, DisasterMessage message) async {
    try {
      final writeChar = _writeCharacteristics[deviceId];
      final device = _connectedDevices[deviceId];
      
      if (writeChar == null || device == null) {
        debugPrint('⚠️ No write characteristic or device for $deviceId, queuing message');
        _queueMessage(deviceId, message);
        return false;
      }

      // Check if device is still connected
      if (!device.isConnected) {
        debugPrint('⚠️ Device $deviceId not connected, queuing message');
        _queueMessage(deviceId, message);
        return false;
      }

      // Serialize message to JSON with metadata
      final messageData = {
        ...message.toJson(),
        'sender_device_id': _deviceId,
        'sender_device_name': await _getDeviceName(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      final messageJson = jsonEncode(messageData);
      final messageWithDelimiter = messageJson + messageDelimiter;
      final data = utf8.encode(messageWithDelimiter);
      
      debugPrint('📤 Sending message to $deviceId: ${data.length} bytes');
      debugPrint('📝 Message content: ${message.content}');
      
      // Get the actual MTU for this device (default to 20 if unknown)
      int mtuSize = 20;
      try {
        mtuSize = await device.mtu.first;
        // Subtract 3 bytes for ATT overhead
        mtuSize = mtuSize - 3;
      } catch (e) {
        debugPrint('⚠️ Could not get MTU for $deviceId, using default 20');
      }
      
      // Split data into chunks based on MTU
      int totalChunks = (data.length / mtuSize).ceil();
      debugPrint('📦 Splitting into $totalChunks chunks (MTU: $mtuSize)');
      
      for (int i = 0; i < data.length; i += mtuSize) {
        final end = (i + mtuSize < data.length) ? i + mtuSize : data.length;
        final chunk = data.sublist(i, end);
        final chunkNum = (i / mtuSize).floor() + 1;
        
        debugPrint('📤 Sending chunk $chunkNum/$totalChunks to $deviceId: ${chunk.length} bytes');
        
        try {
          // Try write with response first, fallback to without response
          if (writeChar.properties.write) {
            await writeChar.write(chunk, withoutResponse: false);
          } else if (writeChar.properties.writeWithoutResponse) {
            await writeChar.write(chunk, withoutResponse: true);
          } else {
            debugPrint('❌ Characteristic $deviceId does not support writing');
            return false;
          }
          
          // Small delay between chunks to avoid overwhelming the receiver
          if (chunkNum < totalChunks) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
          
        } catch (e) {
          debugPrint('❌ Error sending chunk $chunkNum to $deviceId: $e');
          _queueMessage(deviceId, message);
          return false;
        }
      }
      
      debugPrint('✅ Message successfully sent to $deviceId (${message.type})');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error sending message to $deviceId: $e');
      _queueMessage(deviceId, message);
      return false;
    }
  }

  /// Get device name for identification
  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model ?? 'Android Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Queue message for later sending
  void _queueMessage(String deviceId, DisasterMessage message) {
    _messageQueue.putIfAbsent(deviceId, () => []).add(message);
    debugPrint('📝 Message queued for $deviceId (${_messageQueue[deviceId]!.length} in queue)');
  }

  /// Send queued messages to a device
  Future<void> _sendQueuedMessages(String deviceId) async {
    final queue = _messageQueue[deviceId];
    if (queue == null || queue.isEmpty) return;

    debugPrint('📤 Sending ${queue.length} queued messages to $deviceId');
    
    while (queue.isNotEmpty) {
      final message = queue.removeAt(0);
      final success = await _sendMessageToDevice(deviceId, message);
      if (!success) {
        // Re-queue if failed
        queue.insert(0, message);
        break;
      }
    }
    
    if (queue.isEmpty) {
      _messageQueue.remove(deviceId);
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
      return await _messageDb.getAllMessages(limit: limit);
    } catch (e) {
      debugPrint('❌ Error getting recent messages: $e');
      return [];
    }
  }

  /// Dispose of the service with complete cleanup
  @override
  void dispose() {
    debugPrint('🧹 Disposing BLE service...');
    
    // Stop advertising
    _stopAdvertising();
    
    // Close all connections
    for (final deviceId in _connectedDevices.keys.toList()) {
      _removeConnection(deviceId);
    }
    
    // Stop scanning
    stopScanning();
    
    // Clear all collections
    _discoveredDevices.clear();
    _validDisasterDevices.clear();
    _messageQueue.clear();
    _deviceStatuses.clear();
    
    // Close controllers
    _messageController.close();
    _devicesController.close();
    _connectionStatusController.close();
    
    super.dispose();
    debugPrint('✅ BLE service disposed');
  }
}