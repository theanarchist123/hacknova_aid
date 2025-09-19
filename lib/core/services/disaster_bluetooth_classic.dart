import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/disaster_message.dart';
import 'message_database.dart';

/// Enhanced Bluetooth Classic service using RFCOMM for reliable disaster relief communication
/// Implements Bluetooth Classic communication for device-to-device messaging
class DisasterBluetoothService extends ChangeNotifier {
  static final DisasterBluetoothService _instance = DisasterBluetoothService._internal();
  factory DisasterBluetoothService() => _instance;
  DisasterBluetoothService._internal();

  // Bluetooth Classic instance
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  // Connection state
  BluetoothConnection? _connection;
  bool _bluetoothEnabled = false;
  bool _isScanning = false;
  bool _isConnected = false;
  
  // Device discovery
  final List<BluetoothDevice> _discoveredDevices = [];
  final List<BluetoothDevice> _pairedDevices = [];
  BluetoothDevice? _connectedDevice;
  
  // Message handling
  final MessageDatabase _messageDb = MessageDatabase();
  final StreamController<DisasterMessage> _messageController = StreamController<DisasterMessage>.broadcast();
  final StreamController<List<BluetoothDevice>> _devicesController = StreamController<List<BluetoothDevice>>.broadcast();
  final StreamController<String> _connectionStatusController = StreamController<String>.broadcast();
  
  // Scan subscription
  StreamSubscription<BluetoothDiscoveryResult>? _scanSubscription;
  StreamSubscription<BluetoothState>? _bluetoothStateSubscription;
  
  // User info
  String? _deviceId;
  String? _userName;

  // Streams
  Stream<DisasterMessage> get messageStream => _messageController.stream;
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;
  
  // Getters
  bool get bluetoothEnabled => _bluetoothEnabled;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  int get connectedDeviceCount => _isConnected ? 1 : 0;
  List<BluetoothDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  List<BluetoothDevice> get pairedDevices => List.unmodifiable(_pairedDevices);
  String? get deviceId => _deviceId;
  String? get userName => _userName;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Initialize the Bluetooth service
  Future<bool> initialize() async {
    try {
      debugPrint('🔧 Initializing Bluetooth Classic service...');
      
      // Check permissions
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint('❌ Bluetooth permissions not granted');
        return false;
      }

      // Monitor Bluetooth state
      _bluetoothStateSubscription = _bluetooth.state.listen((state) {
        final wasEnabled = _bluetoothEnabled;
        _bluetoothEnabled = state == BluetoothState.STATE_ON;
        debugPrint('📡 Bluetooth state: $state');
        
        if (!wasEnabled && _bluetoothEnabled) {
          _loadPairedDevices();
        }
        
        notifyListeners();
      });

      // Check current Bluetooth state
      final state = await _bluetooth.state;
      _bluetoothEnabled = state == BluetoothState.STATE_ON;
      
      if (!_bluetoothEnabled) {
        debugPrint('⚠️ Bluetooth is not enabled. State: $state');
        return false;
      }

      // Initialize device info
      await _initializeDeviceInfo();
      
      // Initialize message database
      await _messageDb.database;
      
      // Load paired devices
      await _loadPairedDevices();
      
      debugPrint('✅ Bluetooth Classic service initialized successfully');
      debugPrint('📱 Device ID: $_deviceId');
      debugPrint('👤 User Name: $_userName');
      debugPrint('📡 Bluetooth enabled: $_bluetoothEnabled');
      
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

  /// Load paired devices
  Future<void> _loadPairedDevices() async {
    try {
      debugPrint('📱 Loading paired devices...');
      final pairedDevices = await _bluetooth.getBondedDevices();
      _pairedDevices.clear();
      _pairedDevices.addAll(pairedDevices);
      
      debugPrint('✅ Found ${_pairedDevices.length} paired devices');
      for (final device in _pairedDevices) {
        debugPrint('   - ${device.name} (${device.address})');
      }
      
      _devicesController.add(_getAllDevices());
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading paired devices: $e');
    }
  }

  /// Get all devices (discovered + paired)
  List<BluetoothDevice> _getAllDevices() {
    final allDevices = <BluetoothDevice>[];
    
    // Add paired devices first
    allDevices.addAll(_pairedDevices);
    
    // Add discovered devices that aren't already paired
    for (final device in _discoveredDevices) {
      if (!_pairedDevices.any((paired) => paired.address == device.address)) {
        allDevices.add(device);
      }
    }
    
    return allDevices;
  }

  /// Start scanning for devices
  Future<void> startScanning({Duration timeout = const Duration(seconds: 30)}) async {
    try {
      if (_isScanning) {
        debugPrint('⚠️ Already scanning for devices');
        return;
      }

      debugPrint('🔍 Started scanning for Bluetooth devices');
      _isScanning = true;
      _discoveredDevices.clear();
      _connectionStatusController.add('Scanning for devices...');
      notifyListeners();

      // Start discovery
      _scanSubscription = _bluetooth.startDiscovery().listen(
        (result) {
          final device = result.device;
          
          // Skip if already discovered
          if (_discoveredDevices.any((d) => d.address == device.address)) {
            return;
          }
          
          _discoveredDevices.add(device);
          debugPrint('🔍 Discovered: ${device.name ?? 'Unknown'} (${device.address})');
          
          _devicesController.add(_getAllDevices());
          notifyListeners();
        },
        onError: (error) {
          debugPrint('❌ Scan error: $error');
          _isScanning = false;
          _connectionStatusController.add('Scan error: $error');
          notifyListeners();
        },
        onDone: () {
          debugPrint('✅ Device discovery completed');
          _isScanning = false;
          _connectionStatusController.add('Discovery completed');
          notifyListeners();
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
      _connectionStatusController.add('Scan failed: $e');
      notifyListeners();
    }
  }

  /// Stop scanning for devices
  Future<void> stopScanning() async {
    try {
      if (_isScanning) {
        await _scanSubscription?.cancel();
        await _bluetooth.cancelDiscovery();
        _scanSubscription = null;
        _isScanning = false;
        debugPrint('✅ Stopped scanning for devices');
        _connectionStatusController.add('Scan stopped');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error stopping scan: $e');
    }
  }

  /// Connect to a device using hybrid approach
  Future<bool> connectToDevice(BluetoothDevice device, BuildContext context) async {
    try {
      debugPrint('🔗 Attempting to connect to: ${device.name} (${device.address})');
      
      if (_isConnected) {
        await disconnect();
      }
      
      _connectionStatusController.add('Connecting to ${device.name}...');

      try {
        // Method 1: Try direct RFCOMM connection
        debugPrint('📡 Attempting direct RFCOMM connection...');
        _connection = await BluetoothConnection.toAddress(device.address);
        
        if (_connection != null && _connection!.isConnected) {
          debugPrint('✅ Direct connection successful!');
          _setupConnection(device);
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ Direct connection failed: $e');
        
        // Method 2: Check if device is paired
        if (!device.isBonded) {
          debugPrint('📱 Device not paired, prompting user...');
          return await _promptSystemPairing(device, context);
        } else {
          debugPrint('📱 Device is paired but connection failed, retrying...');
          // Try one more time for paired devices
          try {
            await Future.delayed(const Duration(seconds: 2));
            _connection = await BluetoothConnection.toAddress(device.address);
            
            if (_connection != null && _connection!.isConnected) {
              debugPrint('✅ Retry connection successful!');
              _setupConnection(device);
              return true;
            }
          } catch (e2) {
            debugPrint('❌ Retry connection also failed: $e2');
          }
        }
      }
      
      _connectionStatusController.add('Connection failed');
      return false;
    } catch (e) {
      debugPrint('❌ Error connecting to device: $e');
      _connectionStatusController.add('Connection error: $e');
      return false;
    }
  }

  /// Prompt user to pair device through system settings
  Future<bool> _promptSystemPairing(BluetoothDevice device, BuildContext context) async {
    debugPrint('💬 Showing pairing dialog for ${device.name}');
    
    final completer = Completer<bool>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Device Pairing Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('To connect to "${device.name ?? 'Unknown Device'}", please:'),
            const SizedBox(height: 16),
            const Text('1. Pair this device in Android Bluetooth settings'),
            const Text('2. Return to this app'),
            const Text('3. Try connecting again'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Open Bluetooth settings
              await _bluetooth.openSettings();
              completer.complete(false);
            },
            child: const Text('Open Bluetooth Settings'),
          ),
        ],
      ),
    );
    
    return completer.future;
  }

  /// Setup connection and message listener
  void _setupConnection(BluetoothDevice device) {
    _isConnected = true;
    _connectedDevice = device;
    _connectionStatusController.add('Connected to ${device.name}');
    
    debugPrint('🤝 Setting up message listener...');
    
    // Listen for incoming messages
    _connection!.input!.listen(
      (Uint8List data) {
        try {
          final message = utf8.decode(data).trim();
          if (message.isNotEmpty) {
            debugPrint('📨 Received message: $message');
            _handleIncomingMessage(message);
          }
        } catch (e) {
          debugPrint('❌ Error decoding message: $e');
        }
      },
      onError: (error) {
        debugPrint('❌ Connection error: $error');
        disconnect();
      },
      onDone: () {
        debugPrint('📴 Connection closed');
        disconnect();
      },
    );
    
    // Send initial handshake
    final handshakeMessage = DisasterMessage(
      senderId: _deviceId!,
      senderName: _userName!,
      content: '👋 Connected to emergency chat network. Ready for communication.',
      type: MessageType.system,
    );
    
    sendMessage(handshakeMessage);
    notifyListeners();
  }

  /// Handle incoming message
  void _handleIncomingMessage(String messageData) async {
    try {
      debugPrint('📥 Processing incoming message: $messageData');
      
      // Try to parse as JSON
      final Map<String, dynamic> messageJson = jsonDecode(messageData);
      final DisasterMessage message = DisasterMessage.fromJson(messageJson);
      
      debugPrint('✅ Message received from ${message.senderName}: ${message.content}');
      
      // Add to message stream and save to database
      _messageController.add(message);
      await _messageDb.insertMessage(message);
      
    } catch (e) {
      debugPrint('❌ Error processing message: $e');
      
      // If JSON parsing fails, treat as plain text message
      final plainMessage = DisasterMessage(
        senderId: 'unknown',
        senderName: _connectedDevice?.name ?? 'Unknown Device',
        content: messageData,
        type: MessageType.regular,
      );
      
      _messageController.add(plainMessage);
      await _messageDb.insertMessage(plainMessage);
    }
  }

  /// Send a message
  Future<bool> sendMessage(DisasterMessage message) async {
    try {
      if (_connection == null || !_connection!.isConnected) {
        debugPrint('⚠️ No active connection');
        return false;
      }
      
      debugPrint('📤 Sending message: ${message.content}');
      
      // Convert message to JSON and send
      final messageJson = jsonEncode(message.toJson());
      final data = utf8.encode(messageJson + '\n');
      
      _connection!.output.add(Uint8List.fromList(data));
      await _connection!.output.allSent;
      
      debugPrint('✅ Message sent successfully');
      
      // Save to database and add to stream
      await _messageDb.insertMessage(message);
      _messageController.add(message);
      
      return true;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      return false;
    }
  }

  /// Send a chat message
  Future<bool> sendChatMessage(String content) async {
    final chatMessage = DisasterMessage(
      senderId: _deviceId ?? 'unknown',
      senderName: _userName ?? 'Emergency User',
      content: content,
      type: MessageType.regular,
    );
    
    return await sendMessage(chatMessage);
  }

  /// Send emergency SOS message
  Future<bool> sendEmergencySOS() async {
    final sosMessage = DisasterMessage(
      senderId: _deviceId ?? 'unknown',
      senderName: _userName ?? 'Emergency User',
      content: '🆘 EMERGENCY SOS - Need immediate assistance! Location assistance required.',
      type: MessageType.emergency,
    );
    
    return await sendMessage(sosMessage);
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      if (_connection != null) {
        await _connection!.close();
        _connection = null;
      }
      
      _isConnected = false;
      _connectedDevice = null;
      _connectionStatusController.add('Disconnected');
      
      debugPrint('📴 Disconnected from device');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error disconnecting: $e');
    }
  }

  /// Get recent messages from database
  Future<List<DisasterMessage>> getRecentMessages() async {
    try {
      return await _messageDb.getRecentMessages();
    } catch (e) {
      debugPrint('❌ Error getting recent messages: $e');
      return [];
    }
  }

  /// Request Bluetooth enable
  Future<bool> requestBluetoothEnable() async {
    try {
      debugPrint('📲 Requesting Bluetooth enable...');
      
      final result = await _bluetooth.requestEnable();
      if (result == true) {
        _bluetoothEnabled = true;
        await _loadPairedDevices();
        notifyListeners();
        return true;
      }
      
      debugPrint('⚠️ Bluetooth enable request denied');
      return false;
    } catch (e) {
      debugPrint('❌ Error requesting Bluetooth enable: $e');
      return false;
    }
  }

  /// Clean up and dispose
  @override
  Future<void> dispose() async {
    try {
      debugPrint('🧹 Cleaning up Bluetooth resources...');
      
      // Stop scanning
      await stopScanning();
      
      // Disconnect
      await disconnect();
      
      // Cancel subscriptions
      await _bluetoothStateSubscription?.cancel();
      
      debugPrint('✅ Bluetooth resources cleaned up');
    } catch (e) {
      debugPrint('❌ Error disposing Bluetooth service: $e');
    } finally {
      super.dispose();
    }
  }
}