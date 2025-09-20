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
  
  // Multi-device selection support
  List<Map<String, String>> _selectedDevices = [];
  Map<String, bool> _deviceSelectionState = {};
  Map<String, String> _deliveryStatus = {}; // Track delivery status per device
  bool _isSendingToMultiple = false;

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
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    if (_isSendingToMultiple)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                  ],
                ),
                if (_selectedDevices.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Selected devices: ${_selectedDevices.map((d) => d['name']).join(', ')}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_messages[index]),
                );
              },
            ),
          ),
          // Quick action buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedDevices.isNotEmpty && !_isSendingToMultiple ? _sendSOS : null,
                    icon: const Icon(Icons.emergency),
                    label: const Text('Send SOS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedDevices.isNotEmpty && !_isSendingToMultiple ? _sendLocationUpdate : null,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Share Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type emergency message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _selectedDevices.isNotEmpty && !_isSendingToMultiple ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_isSendingToMultiple) return Colors.purple;
    if (_selectedDevices.isNotEmpty) return Colors.green;
    if (_bluetoothService.isDiscovering) return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon() {
    if (_isSendingToMultiple) return Icons.send;
    if (_selectedDevices.isNotEmpty) return _selectedDevices.length > 1 ? Icons.devices : Icons.bluetooth_connected;
    if (_bluetoothService.isDiscovering) return Icons.bluetooth_searching;
    return Icons.bluetooth_disabled;
  }

  String _getStatusText() {
    if (_isSendingToMultiple) return 'Broadcasting message...';
    if (_selectedDevices.isNotEmpty) {
      return _selectedDevices.length > 1 
          ? 'Ready to broadcast to ${_selectedDevices.length} devices'
          : 'Connected to ${_selectedDevices.first['name']} - Ready to send';
    }
    if (_bluetoothService.isDiscovering) return 'Discovering devices...';
    return 'No devices selected - Tap "Select Device" to choose recipients';
  }

  void _showDeviceSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Bluetooth Devices'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
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
                    Row(
                      children: [
                        Text('Paired Devices (${_bluetoothService.bondedDevices.length}):', 
                             style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('Selected: ${_selectedDevices.length}', 
                             style: TextStyle(color: Colors.blue[600], fontSize: 12)),
                      ],
                    ),
                    Expanded(
                      child: _bluetoothService.bondedDevices.isEmpty
                          ? const Center(child: Text('No paired devices found\nTry pairing devices in Android Settings'))
                          : ListView.builder(
                              itemCount: _bluetoothService.bondedDevices.length,
                              itemBuilder: (context, index) {
                                final device = _bluetoothService.bondedDevices[index];
                                final deviceName = device['name']?.toString() ?? 'Unknown';
                                final deviceAddress = device['address']?.toString() ?? '';
                                final isSelected = _deviceSelectionState[deviceAddress] ?? false;
                                
                                return CheckboxListTile(
                                  secondary: const Icon(Icons.devices, color: Colors.blue),
                                  title: Text(deviceName),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(deviceAddress),
                                      if (_deliveryStatus.containsKey(deviceAddress))
                                        Text(
                                          _deliveryStatus[deviceAddress]!,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _deliveryStatus[deviceAddress]!.contains('✅') 
                                                ? Colors.green 
                                                : _deliveryStatus[deviceAddress]!.contains('❌')
                                                    ? Colors.red
                                                    : Colors.orange,
                                          ),
                                        ),
                                    ],
                                  ),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setDialogState(() {
                                      _deviceSelectionState[deviceAddress] = value ?? false;
                                      if (value == true) {
                                        _selectedDevices.add(device);
                                      } else {
                                        _selectedDevices.removeWhere((d) => d['address'] == deviceAddress);
                                      }
                                    });
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
                                final isSelected = _deviceSelectionState[deviceAddress] ?? false;
                                
                                return CheckboxListTile(
                                  secondary: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        deviceType == 'paired' ? Icons.devices : Icons.devices_other,
                                        color: deviceType == 'paired' ? Colors.blue : Colors.green,
                                      ),
                                      if (deviceType != 'paired')
                                        IconButton(
                                          icon: const Icon(Icons.link, size: 16),
                                          onPressed: () async {
                                            final success = await _bluetoothService.pairDevice(deviceAddress);
                                            if (success) {
                                              _showSnackBar('Device paired successfully');
                                              setDialogState(() {});
                                            } else {
                                              _showSnackBar('Failed to pair device');
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                  title: Text(deviceName),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$deviceAddress ($deviceType)'),
                                      if (_deliveryStatus.containsKey(deviceAddress))
                                        Text(
                                          _deliveryStatus[deviceAddress]!,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _deliveryStatus[deviceAddress]!.contains('✅') 
                                                ? Colors.green 
                                                : _deliveryStatus[deviceAddress]!.contains('❌')
                                                    ? Colors.red
                                                    : Colors.orange,
                                          ),
                                        ),
                                    ],
                                  ),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setDialogState(() {
                                      _deviceSelectionState[deviceAddress] = value ?? false;
                                      if (value == true) {
                                        _selectedDevices.add(device);
                                      } else {
                                        _selectedDevices.removeWhere((d) => d['address'] == deviceAddress);
                                      }
                                    });
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
                  child: const Text('Clear All'),
                  onPressed: () {
                    setDialogState(() {
                      _selectedDevices.clear();
                      _deviceSelectionState.clear();
                    });
                  },
                ),
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
                ElevatedButton(
                  onPressed: _selectedDevices.isEmpty ? null : () {
                    Navigator.of(context).pop();
                    setState(() {});
                  },
                  child: Text('Select ${_selectedDevices.length} Device(s)'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _selectedDevices.isEmpty) return;

    setState(() {
      _isSendingToMultiple = true;
      _deliveryStatus.clear();
    });

    try {
      if (_selectedDevices.length == 1) {
        // Single device - use simple method
        final deviceAddress = _selectedDevices.first['address']!;
        final success = await _bluetoothService.sendFileViaBluetoothSystem(deviceAddress, message);
        
        setState(() {
          _messages.add('📤 $message (to ${_selectedDevices.first['name']})');
          _messageController.clear();
          _deliveryStatus[deviceAddress] = success ? '✅ Delivered' : '❌ Failed';
        });
        
        _showSnackBar(success ? 'Message sent' : 'Failed to send message');
      } else {
        // Multiple devices - use broadcast method
        setState(() {
          _messages.add('📤 Broadcasting: $message (to ${_selectedDevices.length} devices)');
          _messageController.clear();
        });

        final results = await _bluetoothService.sendToMultipleDevices(
          _selectedDevices, 
          message,
          onDeviceUpdate: (deviceAddress, status) {
            setState(() {
              _deliveryStatus[deviceAddress] = status;
            });
          },
        );

        final successCount = results.values.where((success) => success).length;
        _showSnackBar('Broadcast complete: $successCount/${_selectedDevices.length} devices reached');
      }
      
      _scrollToBottom();
    } catch (e) {
      _showSnackBar('Failed to send message: $e');
    } finally {
      setState(() {
        _isSendingToMultiple = false;
      });
    }
  }

  Future<void> _sendSOS() async {
    const sosMessage = '🆘 EMERGENCY SOS - NEED IMMEDIATE ASSISTANCE! 🆘';
    if (_selectedDevices.isEmpty) return;
    
    setState(() {
      _isSendingToMultiple = true;
      _deliveryStatus.clear();
    });
    
    try {
      if (_selectedDevices.length == 1) {
        final deviceAddress = _selectedDevices.first['address']!;
        final success = await _bluetoothService.sendFileViaBluetoothSystem(deviceAddress, sosMessage);
        setState(() {
          _messages.add('📤 $sosMessage (to ${_selectedDevices.first['name']})');
          _deliveryStatus[deviceAddress] = success ? '✅ SOS Delivered' : '❌ SOS Failed';
        });
        _showSnackBar(success ? 'SOS sent' : 'Failed to send SOS');
      } else {
        setState(() {
          _messages.add('📤 Broadcasting SOS to ${_selectedDevices.length} devices');
        });

        final results = await _bluetoothService.sendToMultipleDevices(
          _selectedDevices, 
          sosMessage,
          onDeviceUpdate: (deviceAddress, status) {
            setState(() {
              _deliveryStatus[deviceAddress] = status.replaceAll('Sent', 'SOS Sent');
            });
          },
        );

        final successCount = results.values.where((success) => success).length;
        _showSnackBar('SOS Broadcast: $successCount/${_selectedDevices.length} devices reached');
      }
      
      _scrollToBottom();
    } catch (e) {
      _showSnackBar('Failed to send SOS: $e');
    } finally {
      setState(() {
        _isSendingToMultiple = false;
      });
    }
  }

  Future<void> _sendLocationUpdate() async {
    const locationMessage = '📍 Emergency Location Update - GPS coordinates: Lat: 12.3456, Lng: 78.9012';
    if (_selectedDevices.isEmpty) return;
    
    setState(() {
      _isSendingToMultiple = true;
      _deliveryStatus.clear();
    });
    
    try {
      if (_selectedDevices.length == 1) {
        final deviceAddress = _selectedDevices.first['address']!;
        final success = await _bluetoothService.sendFileViaBluetoothSystem(deviceAddress, locationMessage);
        setState(() {
          _messages.add('📤 $locationMessage (to ${_selectedDevices.first['name']})');
          _deliveryStatus[deviceAddress] = success ? '✅ Location Sent' : '❌ Location Failed';
        });
        _showSnackBar(success ? 'Location sent' : 'Failed to send location');
      } else {
        setState(() {
          _messages.add('📤 Broadcasting location to ${_selectedDevices.length} devices');
        });

        final results = await _bluetoothService.sendToMultipleDevices(
          _selectedDevices, 
          locationMessage,
          onDeviceUpdate: (deviceAddress, status) {
            setState(() {
              _deliveryStatus[deviceAddress] = status.replaceAll('Sent', 'Location Sent');
            });
          },
        );

        final successCount = results.values.where((success) => success).length;
        _showSnackBar('Location Broadcast: $successCount/${_selectedDevices.length} devices reached');
      }
      
      _scrollToBottom();
    } catch (e) {
      _showSnackBar('Failed to send location: $e');
    } finally {
      setState(() {
        _isSendingToMultiple = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}