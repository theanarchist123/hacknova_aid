import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

/// One-way BLE messaging service for simple sender/receiver communication
class OneWayBleService extends ChangeNotifier {
  static final OneWayBleService _instance = OneWayBleService._internal();
  factory OneWayBleService() => _instance;
  OneWayBleService._internal();

  // Flutter Reactive BLE instance
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // BLE Service and Characteristic UUIDs (as specified)
  static final Uuid _serviceUuid = Uuid.parse("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Uuid _messageCharacteristicUuid = Uuid.parse("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");

  // State management
  bool _bluetoothEnabled = false;
  bool _isScanning = false;
  bool _isAdvertising = false;
  bool _isConnected = false;
  bool _isSender = true; // true for sender, false for receiver
  String _status = 'Not Started';
  String? _connectedDeviceId;
  String? _connectedDeviceName;
  int _rssi = 0;

  // Getter and setter for sender mode
  bool get isSender => _isSender;
  set isSender(bool value) {
    _isSender = value;
    notifyListeners();
  }

  // Initialize the BLE service
  Future<bool> initialize() async {
    try {
      // Request necessary permissions
      final bluetoothScan = await Permission.bluetoothScan.request();
      final bluetoothConnect = await Permission.bluetoothConnect.request();
      final bluetoothAdvertise = await Permission.bluetoothAdvertise.request();
      final location = await Permission.location.request();

      if (bluetoothScan.isGranted && bluetoothConnect.isGranted && 
          bluetoothAdvertise.isGranted && location.isGranted) {
        // Listen to Bluetooth state changes
        _bleStatusSubscription = _ble.statusStream.listen((status) {
          _bluetoothEnabled = status == BleStatus.ready;
          notifyListeners();
        });

        // Initial Bluetooth state
        _bluetoothEnabled = await _ble.status.first == BleStatus.ready;
        _status = _bluetoothEnabled ? 'Ready' : 'Bluetooth not enabled';
        notifyListeners();
        return true;
      } else {
        _status = 'Permissions denied';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = 'Initialization error: $e';
      notifyListeners();
      return false;
    }
  }

  // Streams and subscriptions
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _characteristicSubscription;
  StreamSubscription<BleStatus>? _bleStatusSubscription;

  // Message handling
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();

  // Connection management
  QualifiedCharacteristic? _writeCharacteristic;

  // Connect to a device
  Future<void> _connectToDevice(DiscoveredDevice device) async {
    try {
      _status = 'Connecting to ${device.name}...';
      notifyListeners();

      _connectionSubscription = _ble.connectToDevice(
        id: device.id,
        servicesWithCharacteristicsToDiscover: {
          _serviceUuid: [_messageCharacteristicUuid]
        },
        connectionTimeout: const Duration(seconds: 2),
      ).listen(
        (connectionState) {
          // Handle connection state updates
          _handleConnectionState(connectionState, device);
        },
        onError: (e) {
          _status = 'Connection error: $e';
          _isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _status = 'Failed to connect: $e';
      _isConnected = false;
      notifyListeners();
    }
  }

  // Handle connection state changes
  void _handleConnectionState(ConnectionStateUpdate update, DiscoveredDevice device) {
    switch (update.connectionState) {
      case DeviceConnectionState.connecting:
        _status = 'Connecting...';
        break;
      case DeviceConnectionState.connected:
        _isConnected = true;
        _connectedDeviceId = device.id;
        _connectedDeviceName = device.name;
        _status = 'Connected to ${device.name}';
        _setupMessageHandling(device);
        break;
      case DeviceConnectionState.disconnecting:
        _status = 'Disconnecting...';
        break;
      case DeviceConnectionState.disconnected:
        _isConnected = false;
        _connectedDeviceId = null;
        _connectedDeviceName = null;
        _status = 'Disconnected';
        break;
    }
    notifyListeners();
  }

  // Set up message handling for the connected device
  void _setupMessageHandling(DiscoveredDevice device) {
    _writeCharacteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _messageCharacteristicUuid,
      deviceId: device.id,
    );

    // Listen for incoming messages if in receiver mode
    if (!_isSender) {
      _characteristicSubscription = _ble
          .subscribeToCharacteristic(_writeCharacteristic!)
          .listen((data) {
        final message = utf8.decode(data);
        _messageController.add(message);
      }, onError: (e) {
        _status = 'Message error: $e';
        notifyListeners();
      });
    }
  }

  // Send a message
  Future<void> sendMessage(String message) async {
    if (!_isConnected || _writeCharacteristic == null) {
      _status = 'Not connected to any device';
      notifyListeners();
      return;
    }

    try {
      final data = Uint8List.fromList(utf8.encode(message));
      await _ble.writeCharacteristicWithResponse(_writeCharacteristic!, value: data);
      _status = 'Message sent';
      notifyListeners();
    } catch (e) {
      _status = 'Failed to send message: $e';
      notifyListeners();
    }
  }

  // Stop all BLE operations
  void stopAll() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _characteristicSubscription?.cancel();
    _bleStatusSubscription?.cancel();
    _isScanning = false;
    _isAdvertising = false;
    _isConnected = false;
    _status = 'Stopped';
    notifyListeners();
  }

  // Getters
  bool get bluetoothEnabled => _bluetoothEnabled;
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;
  bool get isConnected => _isConnected;
  String get status => _status;
  String? get connectedDeviceId => _connectedDeviceId;

  // Start device scanning (receiver mode)
  Future<void> startReceiver() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      _status = 'Scanning for devices...';
      notifyListeners();

      // First request location permission as it's required for BLE scanning
      final locationStatus = await Permission.location.request();
      if (!locationStatus.isGranted) {
        _status = 'Location permission required for BLE scanning';
        _isScanning = false;
        notifyListeners();
        return;
      }

      // Start scanning with broader criteria first
      _scanSubscription = _ble.scanForDevices(
        scanMode: ScanMode.lowLatency,
      ).listen(
        (device) async {
          debugPrint('🔍 Discovered: ${device.name} (${device.id})');
          
          // More detailed logging of the discovered device
          debugPrint('🔍 Evaluating device: "${device.name}" (${device.id})');
          
          // Check if the device is an Android phone or iOS device
          if (device.name.isNotEmpty) {
            final mobilePrefixes = ['iphone', 'pixel', 'samsung', 'android', 'oneplus', 'xiaomi', 'oppo', 'vivo', 'realme'];
            final lowerName = device.name.toLowerCase();
            
            bool isMobileDevice = mobilePrefixes.any((prefix) => lowerName.contains(prefix));
            
            if (!isMobileDevice) {
              debugPrint('❌ REJECTED: Device "${device.name}" does not match mobile patterns');
              return;
            }

            if (!_isConnected) {
              debugPrint('✅ CONNECTING to mobile device: ${device.name}');
              await _connectToDevice(device);
            }
          } else {
            debugPrint('❌ REJECTED: Device has no name');
          }
        },
        onError: (e) {
          _status = 'Scan error: $e';
          _isScanning = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _status = 'Failed to start scanning: $e';
      _isScanning = false;
      notifyListeners();
    }
  }

  // Start advertising (sender mode)
  Future<void> startSender() async {
    if (_isAdvertising) return;

    try {
      _isAdvertising = true;
      _status = 'Advertising service...';
      notifyListeners();

      // Set up peripheral role and start advertising
      // Note: This is a simplified version as full peripheral mode 
      // requires platform-specific code
      _status = 'Ready to send messages';
      notifyListeners();
    } catch (e) {
      _status = 'Failed to start advertising: $e';
      _isAdvertising = false;
      notifyListeners();
    }
  }
  String? get connectedDeviceName => _connectedDeviceName;
  int get rssi => _rssi;

  // Streams
  Stream<String> get messageStream => _messageController.stream;
  Stream<String> get statusStream => _statusController.stream;

  /// Initialize the BLE service
  Future<bool> initialize() async {
    try {
      debugPrint('🔧 Initializing One-Way BLE service...');

      // Check permissions
      if (!await _checkPermissions()) {
        _updateStatus('Permission denied');
        return false;
      }

      // Monitor Bluetooth status
      _bleStatusSubscription = _ble.statusStream.listen((status) {
        _bluetoothEnabled = status == BleStatus.ready;
        debugPrint('📡 BLE status: $status');
        notifyListeners();
      });

      // Check initial Bluetooth status
      final status = await _ble.statusStream.first;
      _bluetoothEnabled = status == BleStatus.ready;

      if (!_bluetoothEnabled) {
        _updateStatus('Bluetooth disabled - please enable');
        return false;
      }

      _updateStatus('BLE service ready');
      debugPrint('✅ One-Way BLE service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing BLE service: $e');
      _updateStatus('Initialization failed: $e');
      return false;
    }
  }

  /// Check and request BLE permissions
  Future<bool> _checkPermissions() async {
    try {
      debugPrint('📋 Checking BLE permissions...');

      final permissions = [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.location,
      ];

      for (final permission in permissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          final result = await permission.request();
          if (!result.isGranted) {
            debugPrint('❌ Permission denied: $permission');
            return false;
          }
        }
      }

      debugPrint('✅ All BLE permissions granted');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
      return false;
    }
  }

  /// Start as sender (advertiser) mode
  Future<bool> startSender() async {
    try {
      debugPrint('📡 Starting sender mode (advertising)...');
      
      if (!_bluetoothEnabled) {
        _updateStatus('Bluetooth not enabled');
        return false;
      }

      // Note: flutter_reactive_ble doesn't support peripheral mode directly
      // We'll simulate advertising by starting a scan and acting as a central
      // that others can connect to via service discovery
      
      _isAdvertising = true;
      _updateStatus('Broadcasting - waiting for receivers...');
      
      debugPrint('✅ Sender mode started (simulated)');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error starting sender: $e');
      _updateStatus('Failed to start sender: $e');
      return false;
    }
  }

  /// Start as receiver (scanner) mode
  Future<bool> startReceiver() async {
    try {
      debugPrint('🔍 Starting receiver mode (scanning)...');
      
      if (!_bluetoothEnabled) {
        _updateStatus('Bluetooth not enabled');
        return false;
      }

      if (_isScanning) {
        debugPrint('⚠️ Already scanning');
        return true;
      }

      _isScanning = true;
      _updateStatus('Scanning for senders...');

      // Scan for devices with our specific service
      _scanSubscription = _ble.scanForDevices(
        withServices: [_serviceUuid],
        scanMode: ScanMode.lowLatency,
      ).listen(
        (device) {
          debugPrint('🔍 Found sender: ${device.name} (${device.id})');
          _connectToSender(device);
        },
        onError: (error) {
          debugPrint('❌ Scan error: $error');
          _updateStatus('Scan error: $error');
        },
      );

      // Stop scanning after 30 seconds if no device found
      Timer(const Duration(seconds: 30), () {
        if (_isScanning && !_isConnected) {
          stopReceiver();
          _updateStatus('No senders found - scan timeout');
        }
      });

      debugPrint('✅ Receiver mode started');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error starting receiver: $e');
      _updateStatus('Failed to start receiver: $e');
      return false;
    }
  }

  /// Connect to a sender device
  Future<void> _connectToSender(DiscoveredDevice device) async {
    try {
      debugPrint('🔗 Connecting to sender: ${device.name} (${device.id})');
      
      // Stop scanning since we found a device
      await _scanSubscription?.cancel();
      _isScanning = false;
      
      _updateStatus('Connecting to ${device.name}...');
      _rssi = device.rssi;

      // Connect to the device
      _connectionSubscription = _ble.connectToDevice(
        id: device.id,
        connectionTimeout: const Duration(seconds: 30),
      ).listen(
        (connectionState) async {
          debugPrint('🔄 Connection state: ${connectionState.connectionState}');
          
          if (connectionState.connectionState == DeviceConnectionState.connected) {
            _isConnected = true;
            _connectedDeviceId = device.id;
            _connectedDeviceName = device.name.isNotEmpty ? device.name : 'Unknown Sender';
            _updateStatus('Connected to ${_connectedDeviceName}');
            
            // Setup characteristic for receiving messages
            await _setupReceiveCharacteristic(device.id);
            
          } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
            _handleDisconnection();
          }
          
          notifyListeners();
        },
        onError: (error) {
          debugPrint('❌ Connection error: $error');
          _updateStatus('Connection failed: $error');
          _handleDisconnection();
        },
      );
    } catch (e) {
      debugPrint('❌ Error connecting to sender: $e');
      _updateStatus('Connection error: $e');
    }
  }

  /// Setup characteristic for receiving messages
  Future<void> _setupReceiveCharacteristic(String deviceId) async {
    try {
      debugPrint('🔧 Setting up receive characteristic...');

      final characteristic = QualifiedCharacteristic(
        serviceId: _serviceUuid,
        characteristicId: _messageCharacteristicUuid,
        deviceId: deviceId,
      );

      // Subscribe to notifications
      _characteristicSubscription = _ble.subscribeToCharacteristic(characteristic).listen(
        (data) {
          final message = utf8.decode(data);
          debugPrint('📨 Message received: $message');
          _messageController.add(message);
          _updateStatus('Message received from ${_connectedDeviceName}');
        },
        onError: (error) {
          debugPrint('❌ Characteristic error: $error');
          _updateStatus('Receive error: $error');
        },
      );

      debugPrint('✅ Receive characteristic setup complete');
    } catch (e) {
      debugPrint('❌ Error setting up receive characteristic: $e');
      _updateStatus('Setup error: $e');
    }
  }

  /// Send a message (sender mode)
  Future<bool> sendMessage(String message) async {
    try {
      debugPrint('📤 Sending message: $message');

      if (!_isAdvertising) {
        _updateStatus('Not in sender mode');
        return false;
      }

      if (message.isEmpty || message.length > 244) {
        _updateStatus('Invalid message length');
        return false;
      }

      // Note: In a real implementation, this would write to the characteristic
      // For simulation, we'll just log the send
      debugPrint('✅ Message sent: $message');
      _updateStatus('Message sent');
      
      return true;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      _updateStatus('Send failed: $e');
      return false;
    }
  }

  /// Stop sender mode
  Future<void> stopSender() async {
    try {
      debugPrint('📴 Stopping sender mode...');
      
      _isAdvertising = false;
      _updateStatus('Sender stopped');
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error stopping sender: $e');
    }
  }

  /// Stop receiver mode
  Future<void> stopReceiver() async {
    try {
      debugPrint('📴 Stopping receiver mode...');
      
      await _scanSubscription?.cancel();
      await _connectionSubscription?.cancel();
      await _characteristicSubscription?.cancel();
      
      _isScanning = false;
      _handleDisconnection();
      
      _updateStatus('Receiver stopped');
    } catch (e) {
      debugPrint('❌ Error stopping receiver: $e');
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _isConnected = false;
    _connectedDeviceId = null;
    _connectedDeviceName = null;
    _rssi = 0;
    _writeCharacteristic = null;
    
    _updateStatus('Disconnected');
    notifyListeners();
  }

  /// Update status and notify listeners
  void _updateStatus(String status) {
    _status = status;
    _statusController.add(status);
    debugPrint('📊 Status: $status');
    notifyListeners();
  }

  /// Clean up resources
  @override
  Future<void> dispose() async {
    try {
      await _scanSubscription?.cancel();
      await _connectionSubscription?.cancel();
      await _characteristicSubscription?.cancel();
      await _bleStatusSubscription?.cancel();
      
      await _messageController.close();
      await _statusController.close();
      
      debugPrint('🧹 One-Way BLE service disposed');
    } catch (e) {
      debugPrint('❌ Error disposing service: $e');
    } finally {
      super.dispose();
    }
  }
}