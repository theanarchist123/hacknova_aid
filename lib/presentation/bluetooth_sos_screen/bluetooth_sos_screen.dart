import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_export.dart';
import '../../core/services/disaster_bluetooth_service.dart';
import '../../core/models/disaster_message.dart';

class BluetoothSosScreen extends StatefulWidget {
  const BluetoothSosScreen({super.key});

  @override
  State<BluetoothSosScreen> createState() => _BluetoothSosScreenState();
}

class _BluetoothSosScreenState extends State<BluetoothSosScreen> with TickerProviderStateMixin {
  late DisasterBluetoothService _bluetoothService;
  late TabController _tabController;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<DisasterMessage> _messages = [];
  List<BluetoothDevice> _devices = [];
  Map<String, bool> _connectionStatus = {};
  
  bool _isInitializing = true;
  String _statusMessage = 'Initializing Bluetooth...';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bluetoothService = DisasterBluetoothService();
    _initializeBluetoothService();
  }

  Future<void> _initializeBluetoothService() async {
    setState(() {
      _statusMessage = 'Checking Bluetooth permissions...';
    });

    try {
      final success = await _bluetoothService.initialize();
      
      if (success) {
        setState(() {
          _statusMessage = 'Setting up message listeners...';
        });

        // Listen to message stream
        _bluetoothService.messageStream.listen((message) {
          setState(() {
            _messages.insert(0, message);
          });
          _scrollToBottom();
        });

        // Listen to devices stream
        _bluetoothService.devicesStream.listen((devices) {
          setState(() {
            _devices = devices;
          });
        });

        // Listen to connection status
        _bluetoothService.connectionStatusStream.listen((status) {
          setState(() {
            _connectionStatus = status;
          });
        });

        setState(() {
          _statusMessage = 'Loading message history...';
        });

        // Load existing messages
        final existingMessages = await _bluetoothService.getRecentMessages();
        setState(() {
          _messages = existingMessages;
          _isInitializing = false;
          _statusMessage = 'Ready';
        });

        setState(() {
          _statusMessage = 'Starting device scan...';
        });

        // Start scanning for devices
        try {
          await _bluetoothService.startScanning();
          setState(() {
            _statusMessage = 'Bluetooth ready';
          });
        } catch (e) {
          setState(() {
            _statusMessage = 'Scan failed: $e';
            _isInitializing = false;
          });
          // Still show the UI even if scan fails
        }
      } else {
        setState(() {
          _isInitializing = false;
          _statusMessage = 'Bluetooth initialization failed - Please enable Bluetooth and grant permissions';
        });
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _statusMessage = 'Error: $e\n\nPlease ensure Bluetooth is enabled and permissions are granted';
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage() {
    try {
      if (_messageController.text.trim().isEmpty) return;

      final message = DisasterMessage(
        senderId: _bluetoothService.deviceId ?? 'unknown',
        senderName: _bluetoothService.userName ?? 'Me',
        content: _messageController.text.trim(),
        type: MessageType.regular,
      );

      _bluetoothService.broadcastMessage(message);
      _messageController.clear();
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendEmergencySOS() {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 2.w),
              Text('Emergency SOS'),
            ],
          ),
          content: Text('Send emergency SOS to all connected devices?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Navigator.pop(context);
                  await _bluetoothService.sendEmergencySOS();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🆘 Emergency SOS sent to all devices'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send SOS: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Send SOS', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error showing SOS dialog: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Bluetooth SOS"),
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: AppTheme.onPrimaryLight,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryLight),
              SizedBox(height: 3.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_statusMessage.contains('permissions') || _statusMessage.contains('Enable Bluetooth'))
                ...[
                  SizedBox(height: 4.h),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 5.w),
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 10.w),
                        SizedBox(height: 2.h),
                        Text(
                          'Required Steps:',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '1. Enable Bluetooth in device settings\n'
                          '2. Grant "Nearby devices" permission\n'
                          '3. Grant "Location" permission\n'
                          '4. Keep Bluetooth discoverable',
                          style: TextStyle(fontSize: 14.sp),
                          textAlign: TextAlign.left,
                        ),
                        SizedBox(height: 3.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                await openAppSettings();
                              },
                              icon: Icon(Icons.settings),
                              label: Text('Settings'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                setState(() {
                                  _isInitializing = true;
                                  _statusMessage = 'Retrying initialization...';
                                });
                                await _initializeBluetoothService();
                              },
                              icon: Icon(Icons.refresh),
                              label: Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryLight,
                                foregroundColor: AppTheme.onPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth SOS"),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: AppTheme.onPrimaryLight,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.onPrimaryLight,
          unselectedLabelColor: AppTheme.onPrimaryLight.withValues(alpha: 0.7),
          indicatorColor: AppTheme.onPrimaryLight,
          tabs: [
            Tab(icon: Icon(Icons.chat), text: "Messages"),
            Tab(icon: Icon(Icons.bluetooth), text: "Devices"),
            Tab(icon: Icon(Icons.warning), text: "Emergency"),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              try {
                await _bluetoothService.startScanning();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Scanning for devices...')),
                  );
                }
              } catch (e) {
                debugPrint('Error starting scan: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to start scanning: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessagesTab(),
          _buildDevicesTab(),
          _buildEmergencyTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 2 
          ? FloatingActionButton.extended(
              onPressed: () {
                try {
                  _sendEmergencySOS();
                } catch (e) {
                  debugPrint('Error in SOS button: $e');
                }
              },
              backgroundColor: Colors.red,
              icon: Icon(Icons.emergency, color: Colors.white),
              label: Text('SOS', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildMessagesTab() {
    return Column(
      children: [
        // Connection status
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(3.w),
          color: _bluetoothService.connectedDeviceCount > 0 
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(
                _bluetoothService.connectedDeviceCount > 0 
                    ? Icons.bluetooth_connected 
                    : Icons.bluetooth_disabled,
                color: _bluetoothService.connectedDeviceCount > 0 
                    ? Colors.green 
                    : Colors.orange,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  _bluetoothService.connectedDeviceCount > 0
                      ? '${_bluetoothService.connectedDeviceCount} device(s) connected'
                      : 'No devices connected',
                  style: TextStyle(
                    color: _bluetoothService.connectedDeviceCount > 0 
                        ? Colors.green.shade700 
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 20.w,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Connect to nearby devices to start messaging',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(3.w),
                  itemCount: _messages.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isFromMe = message.senderId == _bluetoothService.deviceId;
                    
                    return _buildMessageBubble(message, isFromMe);
                  },
                ),
        ),
        
        // Message input
        if (_bluetoothService.connectedDeviceCount > 0)
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 2.w),
                CircleAvatar(
                  backgroundColor: AppTheme.primaryLight,
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send, color: AppTheme.onPrimaryLight),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMessageBubble(DisasterMessage message, bool isFromMe) {
    Color bubbleColor;
    Color textColor;
    
    if (message.isSystem) {
      bubbleColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
    } else if (message.isEmergency) {
      bubbleColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
    } else if (isFromMe) {
      bubbleColor = AppTheme.primaryLight;
      textColor = AppTheme.onPrimaryLight;
    } else {
      bubbleColor = Colors.grey.shade200;
      textColor = Colors.black87;
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: message.isSystem 
            ? MainAxisAlignment.center
            : isFromMe 
                ? MainAxisAlignment.end 
                : MainAxisAlignment.start,
        children: [
          if (!isFromMe && !message.isSystem) ...[
            CircleAvatar(
              radius: 3.w,
              backgroundColor: AppTheme.primaryLight,
              child: Text(
                message.senderName[0].toUpperCase(),
                style: TextStyle(
                  color: AppTheme.onPrimaryLight,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 2.w),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 70.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(15),
                border: message.isEmergency 
                    ? Border.all(color: Colors.red, width: 2)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isFromMe && !message.isSystem)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  
                  if (message.isEmergency)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 4.w),
                        SizedBox(width: 1.w),
                        Text(
                          'EMERGENCY',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  
                  Text(
                    message.content,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13.sp,
                    ),
                  ),
                  
                  SizedBox(height: 0.5.h),
                  
                  Text(
                    message.formattedTime,
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isFromMe && !message.isSystem) ...[
            SizedBox(width: 2.w),
            Icon(
              message.status == MessageStatus.sent 
                  ? Icons.check 
                  : message.status == MessageStatus.delivered
                      ? Icons.done_all
                      : message.status == MessageStatus.failed
                          ? Icons.error
                          : Icons.schedule,
              size: 3.w,
              color: message.status == MessageStatus.failed 
                  ? Colors.red 
                  : Colors.grey,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDevicesTab() {
    return Column(
      children: [
        // Scan status
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(3.w),
          color: _bluetoothService.isScanning 
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          child: Row(
            children: [
              if (_bluetoothService.isScanning)
                SizedBox(
                  width: 5.w,
                  height: 5.w,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.bluetooth_searching),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  _bluetoothService.isScanning 
                      ? 'Scanning for devices...'
                      : 'Found ${_devices.length} device(s)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        
        // Devices list
        Expanded(
          child: _devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bluetooth_disabled,
                        size: 20.w,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        !_bluetoothService.bluetoothEnabled
                            ? 'Bluetooth is turned off'
                            : 'No devices found',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      if (!_bluetoothService.bluetoothEnabled)
                        Text(
                          'Please enable Bluetooth in device settings',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        )
                      else
                        Text(
                          'Make sure nearby devices have Bluetooth enabled\nand are discoverable',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      SizedBox(height: 2.h),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await _bluetoothService.startScanning();
                          } catch (e) {
                            debugPrint('Error scanning for devices: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to scan: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.refresh),
                        label: Text('Scan for Devices'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(3.w),
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isConnected = _bluetoothService.connectedDevices.containsKey(device.remoteId.str);
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 2.h),
                      child: ListTile(
                        leading: Icon(
                          isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                          color: isConnected ? Colors.green : Colors.grey,
                          size: 8.w,
                        ),
                        title: Text(
                          device.advName.isNotEmpty
                              ? device.advName 
                              : 'Unknown Device',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(device.remoteId.str),
                            Text('BLE Device', style: TextStyle(color: Colors.blue, fontSize: 10.sp)),
                          ],
                        ),
                        trailing: isConnected
                            ? TextButton(
                                onPressed: () async {
                                  try {
                                    await _bluetoothService.disconnectFromDevice(device.remoteId.str);
                                  } catch (e) {
                                    debugPrint('Error disconnecting: $e');
                                  }
                                },
                                child: Text('Disconnect'),
                              )
                            : ElevatedButton(
                                onPressed: () async {
                                  try {
                                    final success = await _bluetoothService.connectToDevice(device);
                                    if (mounted) {
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Connected to ${device.advName.isNotEmpty ? device.advName : device.remoteId.str}')),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to connect to ${device.advName.isNotEmpty ? device.advName : device.remoteId.str}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    debugPrint('Error connecting to device: $e');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text('Connect'),
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmergencyTab() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          // Emergency status
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 15.w),
                SizedBox(height: 2.h),
                Text(
                  'Emergency Communication',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Use this tab for emergency situations when cellular networks are down',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.red.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 4.h),
          
          // Emergency actions
          Expanded(
            child: Column(
              children: [
                _buildEmergencyButton(
                  'Send SOS Alert',
                  'Broadcast emergency SOS to all connected devices',
                  Icons.emergency,
                  Colors.red,
                  () {
                    try {
                      _sendEmergencySOS();
                    } catch (e) {
                      debugPrint('Error in SOS alert: $e');
                    }
                  },
                ),
                
                SizedBox(height: 2.h),
                
                _buildEmergencyButton(
                  'Medical Emergency',
                  'Alert for medical assistance needed',
                  Icons.medical_services,
                  Colors.orange,
                  () async {
                    try {
                      await _sendEmergencyMessage('Medical emergency - assistance needed!');
                    } catch (e) {
                      debugPrint('Error in medical emergency: $e');
                    }
                  },
                ),
                
                SizedBox(height: 2.h),
                
                _buildEmergencyButton(
                  'Fire Emergency',
                  'Alert about fire or smoke detected',
                  Icons.local_fire_department,
                  Colors.deepOrange,
                  () async {
                    try {
                      await _sendEmergencyMessage('🔥 Fire emergency detected!');
                    } catch (e) {
                      debugPrint('Error in fire emergency: $e');
                    }
                  },
                ),
                
                SizedBox(height: 2.h),
                
                _buildEmergencyButton(
                  'Need Rescue',
                  'Request rescue or evacuation assistance',
                  Icons.support_agent,
                  Colors.blue,
                  () async {
                    try {
                      await _sendEmergencyMessage('🆘 Rescue needed - please help!');
                    } catch (e) {
                      debugPrint('Error in rescue request: $e');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 7.w),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmergencyMessage(String content) async {
    try {
      final message = DisasterMessage(
        senderId: _bluetoothService.deviceId ?? 'unknown',
        senderName: _bluetoothService.userName ?? 'Me',
        content: content,
        type: MessageType.emergency,
      );

      _bluetoothService.broadcastMessage(message);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency message sent to all devices'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending emergency message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send emergency message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
