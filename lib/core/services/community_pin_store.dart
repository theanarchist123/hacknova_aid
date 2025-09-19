import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart' as sembast_io;
import 'package:sembast_web/sembast_web.dart' as sembast_web;
import 'package:latlong2/latlong.dart';

import '../models/community_pin.dart';

class CommunityPinStore {
  static Database? _database;
  static const String _pinsStore = 'community_pins';
  static const String _syncLogStore = 'pin_sync_log';
  static bool _isInitialized = false;

  // Singleton pattern
  static CommunityPinStore? _instance;
  CommunityPinStore._internal();
  
  static CommunityPinStore get instance {
    _instance ??= CommunityPinStore._internal();
    return _instance!;
  }

  /// Initialize the Sembast database (no databaseFactory issues!)
  static void initialize() {
    // No-op for compatibility - init happens lazily
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (_isInitialized && _database != null) return _database!;
    
    final DatabaseFactory factory = kIsWeb
        ? sembast_web.databaseFactoryWeb
        : sembast_io.databaseFactoryIo;

    String dbPath;
    if (kIsWeb) {
      dbPath = 'community_pins.db';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      dbPath = p.join(dir.path, 'community_pins.db');
    }

    _database = await factory.openDatabase(dbPath);
    _isInitialized = true;
    print('✅ Sembast pin store initialized at: $dbPath');
    return _database!;
  }

  // Main store accessors
  StoreRef<String, Map<String, Object?>> get _pinsStoreRef => 
      stringMapStoreFactory.store(_pinsStore);
  
  StoreRef<String, Map<String, Object?>> get _syncLogStoreRef => 
      stringMapStoreFactory.store(_syncLogStore);

  /// Insert a new community pin
  Future<String> insertPin(CommunityPin pin) async {
    final db = await database;
    await _pinsStoreRef.record(pin.id).put(db, pin.toMap());
    print('✅ Pin inserted with Sembast: ${pin.id}');
    return pin.id;
  }

  /// Get all pins ordered by creation date
  Future<List<CommunityPin>> getAllPins() async {
    final db = await database;
    final finder = Finder(sortOrders: [SortOrder('created_at', false)]);
    final records = await _pinsStoreRef.find(db, finder: finder);
    return records.map((record) => CommunityPin.fromMap(record.value)).toList();
  }

  /// Get pins by type
  Future<List<CommunityPin>> getPinsByType(PinType type) async {
    final db = await database;
    final finder = Finder(
      filter: Filter.equals('type', type.index),
      sortOrders: [SortOrder('created_at', false)]
    );
    final records = await _pinsStoreRef.find(db, finder: finder);
    return records.map((record) => CommunityPin.fromMap(record.value)).toList();
  }

  /// Get pins in a circular area around center point
  Future<List<CommunityPin>> getPinsInArea(LatLng center, double radiusKm) async {
    // Get all pins and filter by distance (Sembast doesn't have built-in geo queries)
    final allPins = await getAllPins();
    
    // Filter pins within radius (using haversine distance)
    return allPins.where((pin) {
      final distance = _calculateDistance(center, pin.location);
      return distance <= radiusKm;
    }).toList();
  }

  /// Calculate distance between two LatLng points using haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final lat1Rad = point1.latitude * (math.pi / 180);
    final lat2Rad = point2.latitude * (math.pi / 180);
    final deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    final deltaLngRad = (point2.longitude - point1.longitude) * (math.pi / 180);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Get pins that need Bluetooth sync
  Future<List<CommunityPin>> getPinsNeedingSync() async {
    final db = await database;
    final finder = Finder(
      filter: Filter.equals('is_synced_bluetooth', 0),
      sortOrders: [SortOrder('created_at', false)]
    );
    final records = await _pinsStoreRef.find(db, finder: finder);
    return records.map((record) => CommunityPin.fromMap(record.value)).toList();
  }

  /// Update an existing pin
  Future<int> updatePin(CommunityPin pin) async {
    final db = await database;
    await _pinsStoreRef.record(pin.id).put(db, pin.toMap());
    return 1; // Return 1 for compatibility (affected rows)
  }

  /// Mark a pin as synced to Bluetooth
  Future<int> markPinAsSynced(String pinId, {int? syncCount}) async {
    final db = await database;
    final record = _pinsStoreRef.record(pinId);
    final existing = await record.get(db);
    
    if (existing != null) {
      final updatedData = Map<String, Object?>.from(existing);
      updatedData['is_synced_bluetooth'] = 1;
      if (syncCount != null) {
        updatedData['sync_count'] = syncCount;
      }
      await record.put(db, updatedData);
      return 1;
    }
    return 0;
  }

  /// Add verification from a device
  Future<int> addVerification(String pinId, String deviceId) async {
    final db = await database;
    final record = _pinsStoreRef.record(pinId);
    final existing = await record.get(db);
    
    if (existing != null) {
      final pin = CommunityPin.fromMap(existing);
      if (!pin.verifiedBy.contains(deviceId)) {
        final updatedVerifiedBy = [...pin.verifiedBy, deviceId];
        final updatedData = Map<String, Object?>.from(existing);
        updatedData['verified_by'] = updatedVerifiedBy.join(',');
        await record.put(db, updatedData);
        return 1;
      }
    }
    return 0;
  }

  /// Delete a pin
  Future<int> deletePin(String pinId) async {
    final db = await database;
    final deletedKey = await _pinsStoreRef.record(pinId).delete(db);
    return deletedKey != null ? 1 : 0;
  }

  /// Insert or update a pin from Bluetooth with conflict resolution
  Future<bool> insertOrUpdateFromBluetooth(CommunityPin pin, String sourceDeviceId) async {
    final db = await database;
    final existingRecord = await _pinsStoreRef.record(pin.id).get(db);
    
    if (existingRecord == null) {
      // New pin from Bluetooth
      await insertPin(pin.copyWith(isSyncedToBluetooth: true));
      await _logSync(pin.id, sourceDeviceId, 'received');
      return true;
    } else {
      // Pin exists - check if we should update
      final existingPin = CommunityPin.fromMap(existingRecord);
      if (pin.updatedAt.isAfter(existingPin.updatedAt)) {
        // Incoming pin is newer
        await updatePin(pin.copyWith(isSyncedToBluetooth: true));
        await _logSync(pin.id, sourceDeviceId, 'updated');
        return true;
      }
      // Existing pin is newer or same - log but don't update
      await _logSync(pin.id, sourceDeviceId, 'ignored');
      return false;
    }
  }

  /// Log sync activity
  Future<void> _logSync(String pinId, String deviceId, String direction) async {
    final db = await database;
    final logEntry = {
      'pin_id': pinId,
      'device_id': deviceId,
      'direction': direction,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final logId = '${pinId}_${deviceId}_${DateTime.now().millisecondsSinceEpoch}';
    await _syncLogStoreRef.record(logId).put(db, logEntry);
  }

  /// Get sync statistics
  Future<Map<String, int>> getSyncStats() async {
    final db = await database;
    final logs = await _syncLogStoreRef.find(db);
    
    final stats = <String, int>{};
    for (final log in logs) {
      final direction = log.value['direction'] as String;
      stats[direction] = (stats[direction] ?? 0) + 1;
    }
    
    // Add pin counts
    final allPins = await getAllPins();
    stats['total_pins'] = allPins.length;
    stats['synced_pins'] = allPins.where((p) => p.isSyncedToBluetooth).length;
    stats['unsynced_pins'] = allPins.where((p) => !p.isSyncedToBluetooth).length;
    
    return stats;
  }

  /// Clean up old sync logs (older than 30 days)
  Future<void> cleanupSyncLogs() async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    
    final finder = Finder(filter: Filter.lessThan('timestamp', cutoffTime));
    await _syncLogStoreRef.delete(db, finder: finder);
  }

  /// Close the database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
    }
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = await database;
    await _pinsStoreRef.delete(db);
    await _syncLogStoreRef.delete(db);
    print('✅ All pin data cleared from Sembast store');
  }
}