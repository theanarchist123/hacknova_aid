package com.hacknova_aid.app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileWriter
import android.content.Context
import android.widget.Toast
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.app.Activity

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "bluetooth_file_transfer"
    private lateinit var bluetoothAdapter: BluetoothAdapter
    private val discoveredDevices = mutableListOf<BluetoothDevice>()
    private val BLUETOOTH_PERMISSION_REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null

    // Broadcast receiver for device discovery
    private val discoveryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                BluetoothDevice.ACTION_FOUND -> {
                    val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    }
                    
                    device?.let {
                        if (!discoveredDevices.contains(it)) {
                            discoveredDevices.add(it)
                        }
                    }
                }
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                    // Discovery finished, return results
                    pendingResult?.let { result ->
                        returnDiscoveredDevices(result)
                        pendingResult = null
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startDeviceDiscovery" -> {
                    startDeviceDiscovery(result)
                }
                "stopDeviceDiscovery" -> {
                    stopDeviceDiscovery(result)
                }
                "pairDevice" -> {
                    val deviceAddress = call.argument<String>("deviceAddress")
                    if (deviceAddress != null) {
                        pairWithDevice(deviceAddress, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Device address is required", null)
                    }
                }
                "sendFileViaBluetoothSystem" -> {
                    val deviceAddress = call.argument<String>("deviceAddress")
                    val message = call.argument<String>("message")
                    if (deviceAddress != null && message != null) {
                        sendFileViaBluetoothSystem(deviceAddress, message, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Device address and message are required", null)
                    }
                }
                "getBondedDevices" -> {
                    getBondedDevices(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun pairWithDevice(deviceAddress: String, result: MethodChannel.Result) {
        try {
            val device = bluetoothAdapter.getRemoteDevice(deviceAddress)
            
            if (device.bondState == BluetoothDevice.BOND_NONE) {
                // Device is not paired, initiate pairing
                val pairResult = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                    device.createBond()
                } else {
                    // For older versions, use reflection
                    val method = device.javaClass.getMethod("createBond")
                    method.invoke(device) as Boolean
                }
                
                if (pairResult) {
                    result.success("Pairing initiated. Please accept the pairing request on both devices.")
                } else {
                    result.error("PAIR_FAILED", "Failed to initiate pairing", null)
                }
            } else if (device.bondState == BluetoothDevice.BOND_BONDED) {
                result.success("Device is already paired")
            } else {
                result.success("Pairing is in progress")
            }
        } catch (e: Exception) {
            result.error("PAIR_ERROR", "Error during pairing: ${e.message}", null)
        }
    }

    private fun sendFileViaBluetoothSystem(deviceAddress: String, message: String, result: MethodChannel.Result) {
        try {
            // Create a temporary text file with the message
            val fileName = "DisasterMessage_${System.currentTimeMillis()}.txt"
            val file = File(applicationContext.cacheDir, fileName)
            
            FileWriter(file).use { writer ->
                writer.write("Disaster Aid Message\n")
                writer.write("Time: ${java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(java.util.Date())}\n")
                writer.write("Message: $message\n")
                writer.write("\nSent via HackNova Disaster Aid App")
            }

            // Get the device
            val device = bluetoothAdapter.getRemoteDevice(deviceAddress)
            
            // Check if device is paired
            if (device.bondState != BluetoothDevice.BOND_BONDED) {
                result.error("NOT_PAIRED", "Device is not paired. Please pair first.", null)
                return
            }

            // Create intent to share file via Bluetooth
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_STREAM, androidx.core.content.FileProvider.getUriForFile(
                    applicationContext,
                    "${applicationContext.packageName}.fileprovider",
                    file
                ))
                putExtra("bluetooth_device", device)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            // Try to send specifically via Bluetooth
            val bluetoothIntent = Intent().apply {
                action = Intent.ACTION_SEND
                type = "text/plain"
                setPackage("com.android.bluetooth")
                putExtra(Intent.EXTRA_STREAM, androidx.core.content.FileProvider.getUriForFile(
                    applicationContext,
                    "${applicationContext.packageName}.fileprovider",
                    file
                ))
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            try {
                startActivity(bluetoothIntent)
                result.success("File transfer initiated via Bluetooth system")
            } catch (e: Exception) {
                // Fallback to general share intent
                startActivity(Intent.createChooser(intent, "Send message via Bluetooth"))
                result.success("File sharing dialog opened")
            }

        } catch (e: Exception) {
            result.error("SEND_ERROR", "Error sending file: ${e.message}", null)
        }
    }

    private fun getBondedDevices(result: MethodChannel.Result) {
        try {
            val bondedDevices = bluetoothAdapter.bondedDevices
            val deviceList = mutableListOf<Map<String, String>>()
            
            for (device in bondedDevices) {
                deviceList.add(mapOf(
                    "name" to (device.name ?: "Unknown"),
                    "address" to device.address
                ))
            }
            
            result.success(deviceList)
        } catch (e: Exception) {
            result.error("GET_DEVICES_ERROR", "Error getting bonded devices: ${e.message}", null)
        }
    }

    private fun startDeviceDiscovery(result: MethodChannel.Result) {
        try {
            if (!bluetoothAdapter.isEnabled) {
                result.error("BLUETOOTH_DISABLED", "Bluetooth is not enabled", null)
                return
            }

            // Check permissions
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED) {
                    result.error("PERMISSION_DENIED", "Bluetooth scan permission not granted", null)
                    return
                }
            }

            // Register discovery receiver
            val filter = IntentFilter().apply {
                addAction(BluetoothDevice.ACTION_FOUND)
                addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
            }
            registerReceiver(discoveryReceiver, filter)

            // Clear previous discoveries
            discoveredDevices.clear()
            pendingResult = result

            // Start discovery
            if (bluetoothAdapter.isDiscovering) {
                bluetoothAdapter.cancelDiscovery()
            }
            
            val discoveryStarted = bluetoothAdapter.startDiscovery()
            if (!discoveryStarted) {
                result.error("DISCOVERY_FAILED", "Failed to start device discovery", null)
                pendingResult = null
            }
            // Note: result will be called when discovery finishes via the receiver
            
        } catch (e: Exception) {
            result.error("DISCOVERY_ERROR", "Error starting discovery: ${e.message}", null)
        }
    }

    private fun stopDeviceDiscovery(result: MethodChannel.Result) {
        try {
            if (bluetoothAdapter.isDiscovering) {
                bluetoothAdapter.cancelDiscovery()
            }
            
            try {
                unregisterReceiver(discoveryReceiver)
            } catch (e: Exception) {
                // Receiver might not be registered
            }
            
            result.success("Discovery stopped")
        } catch (e: Exception) {
            result.error("STOP_DISCOVERY_ERROR", "Error stopping discovery: ${e.message}", null)
        }
    }

    private fun returnDiscoveredDevices(result: MethodChannel.Result) {
        try {
            val deviceList = mutableListOf<Map<String, String>>()
            
            // Add discovered devices
            for (device in discoveredDevices) {
                if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED || 
                    Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                    deviceList.add(mapOf(
                        "name" to (device.name ?: "Unknown Device"),
                        "address" to device.address,
                        "type" to "discovered"
                    ))
                }
            }
            
            // Also add bonded devices
            val bondedDevices = bluetoothAdapter.bondedDevices
            for (device in bondedDevices) {
                if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED || 
                    Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                    deviceList.add(mapOf(
                        "name" to (device.name ?: "Unknown Device"),
                        "address" to device.address,
                        "type" to "paired"
                    ))
                }
            }
            
            result.success(deviceList)
        } catch (e: Exception) {
            result.error("GET_DISCOVERED_DEVICES_ERROR", "Error getting discovered devices: ${e.message}", null)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(discoveryReceiver)
        } catch (e: Exception) {
            // Receiver might not be registered
        }
    }
}