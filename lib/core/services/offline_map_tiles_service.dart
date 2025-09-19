import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

class OfflineMapTilesService {
  static Database? _database;
  static const String _tableName = 'map_tiles';
  
  // Singleton pattern
  static OfflineMapTilesService? _instance;
  OfflineMapTilesService._internal();
  
  static OfflineMapTilesService get instance {
    _instance ??= OfflineMapTilesService._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'offline_tiles.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        z INTEGER NOT NULL,
        x INTEGER NOT NULL,
        y INTEGER NOT NULL,
        tile_data BLOB NOT NULL,
        downloaded_at INTEGER NOT NULL,
        url_template TEXT NOT NULL,
        PRIMARY KEY (z, x, y, url_template)
      )
    ''');

    // Create indices for better performance
    await db.execute('CREATE INDEX idx_tiles_zxy ON $_tableName (z, x, y)');
    await db.execute('CREATE INDEX idx_tiles_downloaded ON $_tableName (downloaded_at)');

    print('✅ Offline tiles database initialized');
  }

  /// Download tiles for a specific area
  Future<void> downloadTilesForArea({
    required LatLng center,
    required double radiusKm,
    int minZoom = 8,
    int maxZoom = 14,
    Function(int downloaded, int total)? onProgress,
  }) async {
    print('📥 Starting tile download for area around ${center.latitude}, ${center.longitude}');
    
    final List<TileCoordinate> tilesToDownload = [];
    
    // Calculate tiles needed for each zoom level
    for (int zoom = minZoom; zoom <= maxZoom; zoom++) {
      final tiles = _getTilesInRadius(center, radiusKm, zoom);
      tilesToDownload.addAll(tiles);
    }
    
    print('📊 Total tiles to download: ${tilesToDownload.length}');
    
    int downloaded = 0;
    const int batchSize = 10; // Download in batches to avoid overwhelming the server
    
    for (int i = 0; i < tilesToDownload.length; i += batchSize) {
      final batch = tilesToDownload.skip(i).take(batchSize).toList();
      
      await Future.wait(
        batch.map((tile) => _downloadTile(tile)),
        eagerError: false, // Continue even if some tiles fail
      );
      
      downloaded += batch.length;
      onProgress?.call(downloaded, tilesToDownload.length);
      
      // Small delay to be respectful to the tile server
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    print('✅ Tile download completed: $downloaded/${tilesToDownload.length}');
  }

  /// Get tiles needed for a circular area
  List<TileCoordinate> _getTilesInRadius(LatLng center, double radiusKm, int zoom) {
    final List<TileCoordinate> tiles = [];
    
    // Convert radius to tile coordinates
    final centerTile = _latLngToTile(center, zoom);
    final radiusInTiles = (radiusKm * 1000) / _getTileSize(zoom); // Rough approximation
    
    final minX = (centerTile.x - radiusInTiles).floor();
    final maxX = (centerTile.x + radiusInTiles).ceil();
    final minY = (centerTile.y - radiusInTiles).floor();
    final maxY = (centerTile.y + radiusInTiles).ceil();
    
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        // Check if tile is within radius
        final tileCenter = _tileToLatLng(x, y, zoom);
        final distance = _calculateDistance(center, tileCenter);
        
        if (distance <= radiusKm) {
          tiles.add(TileCoordinate(x: x, y: y, z: zoom));
        }
      }
    }
    
    return tiles;
  }

  /// Download a single tile
  Future<void> _downloadTile(TileCoordinate tile) async {
    try {
      // Check if tile already exists and is recent (less than 30 days old)
      final existingTile = await _getTileFromDatabase(tile);
      if (existingTile != null) {
        final age = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(existingTile['downloaded_at'])
        );
        if (age.inDays < 30) {
          return; // Tile is recent enough, skip download
        }
      }
      
      // OpenStreetMap tile URL
      const String urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      final String url = urlTemplate
          .replaceAll('{z}', tile.z.toString())
          .replaceAll('{x}', tile.x.toString())
          .replaceAll('{y}', tile.y.toString());
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'DisasterApp/1.0 (Emergency Response App)',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        await _saveTileToDatabase(tile, response.bodyBytes, urlTemplate);
        // print('✅ Downloaded tile: ${tile.z}/${tile.x}/${tile.y}');
      } else {
        print('❌ Failed to download tile ${tile.z}/${tile.x}/${tile.y}: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error downloading tile ${tile.z}/${tile.x}/${tile.y}: $e');
    }
  }

  /// Save tile to database
  Future<void> _saveTileToDatabase(TileCoordinate tile, Uint8List tileData, String urlTemplate) async {
    final db = await database;
    
    await db.insert(
      _tableName,
      {
        'z': tile.z,
        'x': tile.x,
        'y': tile.y,
        'tile_data': tileData,
        'downloaded_at': DateTime.now().millisecondsSinceEpoch,
        'url_template': urlTemplate,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get tile from database
  Future<Map<String, dynamic>?> _getTileFromDatabase(TileCoordinate tile) async {
    final db = await database;
    
    final List<Map<String, dynamic>> results = await db.query(
      _tableName,
      where: 'z = ? AND x = ? AND y = ?',
      whereArgs: [tile.z, tile.x, tile.y],
      limit: 1,
    );
    
    return results.isNotEmpty ? results.first : null;
  }

  /// Get offline tile data for use by map widget
  Future<Uint8List?> getTileData(int z, int x, int y) async {
    final tile = await _getTileFromDatabase(TileCoordinate(x: x, y: y, z: z));
    return tile?['tile_data'];
  }

  /// Check if area has offline tiles available
  Future<bool> hasOfflineTilesForArea(LatLng center, double radiusKm, int zoom) async {
    final tilesNeeded = _getTilesInRadius(center, radiusKm, zoom);
    int tilesAvailable = 0;
    
    for (final tile in tilesNeeded) {
      final existingTile = await _getTileFromDatabase(tile);
      if (existingTile != null) {
        tilesAvailable++;
      }
    }
    
    final coverage = tilesAvailable / tilesNeeded.length;
    return coverage > 0.8; // Consider area covered if 80% of tiles are available
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final db = await database;
    
    final totalTiles = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tableName')
    ) ?? 0;
    
    final totalSize = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(LENGTH(tile_data)) FROM $_tableName')
    ) ?? 0;
    
    final oldestTile = await db.rawQuery(
      'SELECT MIN(downloaded_at) as oldest FROM $_tableName'
    );
    
    final newestTile = await db.rawQuery(
      'SELECT MAX(downloaded_at) as newest FROM $_tableName'
    );
    
    return {
      'totalTiles': totalTiles,
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).round(),
      'oldestTile': oldestTile.isNotEmpty ? oldestTile.first['oldest'] : null,
      'newestTile': newestTile.isNotEmpty ? newestTile.first['newest'] : null,
    };
  }

  /// Clean up old tiles (keep tiles newer than 90 days)
  Future<int> cleanupOldTiles({int maxAgeDays = 90}) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(Duration(days: maxAgeDays));
    
    final deletedCount = await db.delete(
      _tableName,
      where: 'downloaded_at < ?',
      whereArgs: [cutoffTime.millisecondsSinceEpoch],
    );
    
    print('🧹 Cleaned up $deletedCount old tiles');
    return deletedCount;
  }

  /// Clear all offline tiles
  Future<void> clearAllTiles() async {
    final db = await database;
    await db.delete(_tableName);
    print('🗑️ Cleared all offline tiles');
  }

  // Utility methods for tile calculations

  TileCoordinate _latLngToTile(LatLng latLng, int zoom) {
    final n = math.pow(2, zoom);
    final latRad = latLng.latitude * math.pi / 180;
    
    final x = ((latLng.longitude + 180) / 360 * n).floor();
    final y = ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n).floor();
    
    return TileCoordinate(x: x, y: y, z: zoom);
  }

  LatLng _tileToLatLng(int x, int y, int zoom) {
    final n = math.pow(2, zoom);
    final lonDeg = x / n * 360 - 180;
    final latRad = math.atan(_sinh(math.pi * (1 - 2 * y / n)));
    final latDeg = latRad * 180 / math.pi;
    
    return LatLng(latDeg, lonDeg);
  }

  // Helper function for hyperbolic sine
  double _sinh(double x) {
    return (math.exp(x) - math.exp(-x)) / 2;
  }

  double _getTileSize(int zoom) {
    // Approximate tile size in meters at equator
    return 40075016.686 / math.pow(2, zoom);
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final lat1Rad = point1.latitude * math.pi / 180;
    final lat2Rad = point2.latitude * math.pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * math.pi / 180;
    final deltaLonRad = (point2.longitude - point1.longitude) * math.pi / 180;
    
    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Get recommended tiles for current area
  Future<List<LatLng>> getRecommendedDownloadAreas() async {
    // Could be enhanced to suggest areas based on user location history,
    // disaster-prone areas, etc.
    return [
      LatLng(19.0760, 72.8777), // Mumbai
      LatLng(28.6139, 77.2090), // Delhi
      LatLng(12.9716, 77.5946), // Bangalore
      LatLng(13.0827, 80.2707), // Chennai
    ];
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

class TileCoordinate {
  final int x;
  final int y;
  final int z;

  const TileCoordinate({
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TileCoordinate &&
        other.x == x &&
        other.y == y &&
        other.z == z;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ z.hashCode;

  @override
  String toString() => 'TileCoordinate($z/$x/$y)';
}