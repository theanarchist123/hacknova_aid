import 'package:flutter/material.dart';
import '../core/services/native_bluetooth_service.dart';

class BluetoothClassicMessengerScreen extends StatefulWidget {
  const BluetoothClassicMessengerScreen({super.key});

  @override
  State<BluetoothClassicMessengerScreen> createState() => _BluetoothClassicMessengerScreenState();
}

class _BluetoothClassicMessengerScreenState extends State<BluetoothClassicMessengerScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late NativeBluetoothService _bluetoothService;
  List<String> _messages = [];
  String? _connectedDeviceAddress;
  String? _connectedDeviceName;

  @override
  void initState() {
    super.initState();
    _bluetoothService = NativeBluetoothService();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    try {
      await _bluetoothService.initialize();
      // Load bonded devices automatically
      await _bluetoothService.getBondedDevices();
      setState(() {});
    } catch (e) {
      _showSnackBar('Failed to initialize Bluetooth: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Messenger'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _connectedDeviceAddress != null ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: _connectedDeviceAddress != null ? Colors.green : Colors.grey,
            ),
            onPressed: () => _showDeviceSelectionDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _bluetoothService.discoverDevices();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: _getStatusColor(),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_connectedDeviceName != null)
                  Text(
                    _connectedDeviceName!,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isOutgoing = !message.startsWith('📨');
                
                return Align(
                  alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isOutgoing ? Colors.blue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: isOutgoing ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Quick action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _connectedDeviceAddress != null ? _sendSOS : null,
                    icon: const Icon(Icons.warning, color: Colors.white),
                    label: const Text('SOS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _connectedDeviceAddress != null ? _sendLocationUpdate : null,
                    icon: const Icon(Icons.location_on, color: Colors.white),
                    label: const Text('Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type emergency message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _connectedDeviceAddress != null ? _sendMessage : null,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_connectedDeviceAddress != null) return Colors.green;
    if (_bluetoothService.isDiscovering) return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon() {
    if (_connectedDeviceAddress != null) return Icons.bluetooth_connected;
    if (_bluetoothService.isDiscovering) return Icons.bluetooth_searching;
    return Icons.bluetooth_disabled;
  }

  String _getStatusText() {
    if (_connectedDeviceAddress != null) return 'Connected - Ready to send messages';
    if (_bluetoothService.isDiscovering) return 'Discovering devices...';
    return 'Disconnected - Tap Bluetooth icon to connect';
  }

  void _showDeviceSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Bluetooth Device'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: Column(
                  children: [
                    // Status display
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.grey[100],
                      child: Text(
                        _bluetoothService.status,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bonded devices section
                    Text('Paired Devices (${_bluetoothService.bondedDevices.length}):', 
                         style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: _bluetoothService.bondedDevices.isEmpty
                          ? const Center(child: Text('No paired devices found\nTry pairing devices in Android Settings'))
                          : ListView.builder(
                              itemCount: _bluetoothService.bondedDevices.length,
                              itemBuilder: (context, index) {
                                final device = _bluetoothService.bondedDevices[index];
                                final deviceName = device['name']?.toString() ?? 'Unknown';
                                final deviceAddress = device['address']?.toString() ?? '';
                                return ListTile(
                                  leading: const Icon(Icons.devices, color: Colors.blue),
                                  title: Text(deviceName),
                                  subtitle: Text(deviceAddress),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _connectToDevice(deviceName, deviceAddress);
                                  },
                                );
                              },
                            ),
                    ),
                    const Divider(),
                    // Discovered devices section
                    Text('Discovered Devices (${_bluetoothService.discoveredDevices.length}):', 
                         style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: _bluetoothService.discoveredDevices.isEmpty
                          ? const Center(child: Text('No devices discovered\nTap "Discover" to scan'))
                          : ListView.builder(
                              itemCount: _bluetoothService.discoveredDevices.length,
                              itemBuilder: (context, index) {
                                final device = _bluetoothService.discoveredDevices[index];
                                final deviceName = device['name']?.toString() ?? 'Unknown';
                                final deviceAddress = device['address']?.toString() ?? '';
                                final deviceType = device['type']?.toString() ?? 'unknown';
                                return ListTile(
                                  leading: Icon(
                                    deviceType == 'paired' ? Icons.devices : Icons.devices_other,
                                    color: deviceType == 'paired' ? Colors.blue : Colors.green,
                                  ),
                                  title: Text(deviceName),
                                  subtitle: Text('$deviceAddress ($deviceType)'),
                                  trailing: deviceType != 'paired' ? IconButton(
                                    icon: const Icon(Icons.link),
                                    onPressed: () async {
                                      final success = await _bluetoothService.pairDevice(deviceAddress);
                                      if (success) {
                                        _showSnackBar('Device paired successfully');
                                        setDialogState(() {});
                                      } else {
                                        _showSnackBar('Failed to pair device');
                                      }
                                    },
                                  ) : null,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _connectToDevice(deviceName, deviceAddress);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Refresh Paired'),
                  onPressed: () async {
                    await _bluetoothService.getBondedDevices();
                    setDialogState(() {});
                  },
                ),
                TextButton(
                  child: Text(_bluetoothService.isDiscovering ? 'Discovering...' : 'Discover'),
                  onPressed: _bluetoothService.isDiscovering ? null : () async {
                    _showSnackBar('Scanning for nearby devices...');
                    try {
                      await _bluetoothService.discoverDevices();
                      setDialogState(() {});
                      _showSnackBar('Device discovery completed');
                    } catch (e) {
                      _showSnackBar('Discovery failed: $e');
                    }
                  },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _connectToDevice(String deviceName, String deviceAddress) async {
    try {
      setState(() {}); // Update UI to show connecting state
      // For this demo, we'll just store the connection info
      // In a real implementation, you'd establish a socket connection
      _connectedDeviceAddress = deviceAddress;
      _connectedDeviceName = deviceName;
      _showSnackBar('Connected to $deviceName');
      setState(() {});
    } catch (e) {
      _showSnackBar('Failed to connect: $e');
      setState(() {});
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _connectedDeviceAddress == null) return;

    try {
      // Use the native Bluetooth service to send the message
      await _bluetoothService.sendFileViaBluetoothSystem(_connectedDeviceAddress!, message);
      setState(() {
        _messages.add('📤 $message');
        _messageController.clear();
      });
      _scrollToBottom();
      _showSnackBar('Message sent');
    } catch (e) {
      _showSnackBar('Failed to send message: $e');
    }
  }

  Future<void> _sendSOS() async {
    const sosMessage = '🆘 EMERGENCY SOS - NEED IMMEDIATE ASSISTANCE! 🆘';
    if (_connectedDeviceAddress == null) return;
    
    try {
      await _bluetoothService.sendFileViaBluetoothSystem(_connectedDeviceAddress!, sosMessage);
      setState(() {
        _messages.add('📤 $sosMessage');
      });
      _scrollToBottom();
      _showSnackBar('SOS sent');
    } catch (e) {
      _showSnackBar('Failed to send SOS: $e');
    }
  }

  Future<void> _sendLocationUpdate() async {
    // In a real app, you would get actual GPS coordinates
    const locationMessage = '📍 Location Update: Emergency at current position - GPS coordinates needed';
    if (_connectedDeviceAddress == null) return;
    
    try {
      await _bluetoothService.sendFileViaBluetoothSystem(_connectedDeviceAddress!, locationMessage);
      setState(() {
        _messages.add('📤 $locationMessage');
      });
      _scrollToBottom();
      _showSnackBar('Location update sent');
    } catch (e) {
      _showSnackBar('Failed to send location: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}