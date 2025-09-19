import 'package:flutter/material.dart';
import '../core/services/native_bluetooth_service.dart';

class SystemBluetoothScreen extends StatefulWidget {
  const SystemBluetoothScreen({super.key});

  @override
  State<SystemBluetoothScreen> createState() => _SystemBluetoothScreenState();
}

class _SystemBluetoothScreenState extends State<SystemBluetoothScreen> {
  final NativeBluetoothService _bluetoothService = NativeBluetoothService();
  final TextEditingController _messageController = TextEditingController();
  
  List<Map<String, String>> _allDevices = [];
  String? _selectedDeviceAddress;
  String? _selectedDeviceName;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _bluetoothService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _bluetoothService.removeListener(_onServiceUpdate);
    _messageController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {
        _allDevices = [
          ..._bluetoothService.bondedDevices,
          ..._bluetoothService.discoveredDevices,
        ];
      });
    }
  }

  Future<void> _initializeService() async {
    final success = await _bluetoothService.initialize();
    setState(() {
      _isInitialized = success;
    });
    
    if (success) {
      // Load bonded devices immediately
      await _bluetoothService.getBondedDevices();
    }
  }

  Future<void> _startDiscovery() async {
    await _bluetoothService.discoverDevices();
  }

  Future<void> _pairDevice(String deviceAddress, String deviceName) async {
    final success = await _bluetoothService.pairDevice(deviceAddress);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pairing initiated with $deviceName'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_selectedDeviceAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a device first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await _bluetoothService.sendFileViaBluetoothSystem(
      _selectedDeviceAddress!,
      message,
    );

    if (success) {
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message sent to $_selectedDeviceName!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildDeviceCard(Map<String, String> device) {
    final name = device['name'] ?? 'Unknown Device';
    final address = device['address'] ?? '';
    final type = device['type'] ?? '';
    final isPaired = type == 'paired';
    final isSelected = _selectedDeviceAddress == address;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected 
            ? Colors.blue.withOpacity(0.1)
            : (isPaired ? Colors.green.withOpacity(0.05) : Colors.grey.withOpacity(0.02)),
        border: Border.all(
          color: isSelected 
              ? Colors.blue 
              : (isPaired ? Colors.green : Colors.grey.withOpacity(0.3)),
          width: isSelected ? 3 : 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPaired ? Colors.green : Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPaired ? Icons.bluetooth_connected : Icons.bluetooth,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPaired ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPaired ? 'PAIRED' : 'DISCOVERED',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 32,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!isPaired) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pairDevice(address, name),
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text(
                        'Pair Device',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDeviceAddress = address;
                        _selectedDeviceName = name;
                      });
                    },
                    icon: Icon(
                      isSelected ? Icons.check : Icons.radio_button_unchecked,
                      size: 18,
                    ),
                    label: Text(
                      isSelected ? 'Selected' : 'Select',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                      foregroundColor: isSelected ? Colors.white : Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Bluetooth'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _bluetoothService.isDiscovering ? null : _startDiscovery,
            icon: Icon(
              _bluetoothService.isDiscovering ? Icons.hourglass_empty : Icons.search,
            ),
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing Bluetooth...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'System Bluetooth Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _bluetoothService.status,
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (_selectedDeviceName != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Target: $_selectedDeviceName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Discovery Section
                  Row(
                    children: [
                      const Icon(Icons.devices, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Available Devices (${_allDevices.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_bluetoothService.isDiscovering)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Device List
                  Expanded(
                    child: _allDevices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bluetooth_disabled,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No devices found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _startDiscovery,
                                  icon: const Icon(Icons.search),
                                  label: const Text('Discover Devices'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _allDevices.length,
                            itemBuilder: (context, index) {
                              return _buildDeviceCard(_allDevices[index]);
                            },
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Message Sending Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.send, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text(
                              'Send Emergency Message',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Enter your emergency message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          maxLength: 200,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _selectedDeviceAddress != null && 
                                      _messageController.text.trim().isNotEmpty
                                ? _sendMessage
                                : null,
                            icon: const Icon(Icons.send, size: 20),
                            label: Text(
                              _selectedDeviceAddress != null
                                  ? 'Send Message'
                                  : 'Select device first',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedDeviceAddress != null && 
                                              _messageController.text.trim().isNotEmpty
                                  ? Colors.green
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}