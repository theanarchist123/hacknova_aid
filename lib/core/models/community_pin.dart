import 'package:latlong2/latlong.dart';

enum PinType {
  hazard,
  resource,
  safe_zone,
  blocked_road,
  water_source,
  shelter,
  medical,
  food,
  fire,
  flood,
  landslide,
  evacuation_route,
  emergency_contact,
  other
}

enum PinPriority {
  low,
  medium,
  high,
  critical
}

enum PinStatus {
  active,
  resolved,
  verified,
  needs_verification
}

class CommunityPin {
  final String id;
  final PinType type;
  final LatLng location;
  final String title;
  final String description;
  final PinPriority priority;
  final PinStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy; // Device/User ID
  final String? imageUrl; // Local path or future cloud URL
  final Map<String, dynamic>? metadata; // Additional type-specific data
  final bool isSyncedToBluetooth;
  final List<String> verifiedBy; // List of device IDs that verified this pin
  final int syncCount; // How many times this has been synced

  const CommunityPin({
    required this.id,
    required this.type,
    required this.location,
    required this.title,
    required this.description,
    this.priority = PinPriority.medium,
    this.status = PinStatus.active,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.imageUrl,
    this.metadata,
    this.isSyncedToBluetooth = false,
    this.verifiedBy = const [],
    this.syncCount = 0,
  });

  // Create from database map
  factory CommunityPin.fromMap(Map<String, dynamic> map) {
    return CommunityPin(
      id: map['id'] as String,
      type: PinType.values[map['type'] as int],
      location: LatLng(map['latitude'] as double, map['longitude'] as double),
      title: map['title'] as String,
      description: map['description'] as String,
      priority: PinPriority.values[map['priority'] as int],
      status: PinStatus.values[map['status'] as int],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      createdBy: map['created_by'] as String,
      imageUrl: map['image_url'] as String?,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
      isSyncedToBluetooth: (map['is_synced_bluetooth'] as int) == 1,
      verifiedBy: map['verified_by'] != null
          ? (map['verified_by'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      syncCount: map['sync_count'] as int? ?? 0,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'title': title,
      'description': description,
      'priority': priority.index,
      'status': status.index,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'created_by': createdBy,
      'image_url': imageUrl,
      'metadata': metadata,
      'is_synced_bluetooth': isSyncedToBluetooth ? 1 : 0,
      'verified_by': verifiedBy.join(','),
      'sync_count': syncCount,
    };
  }

  // For Bluetooth sync (smaller payload)
  Map<String, dynamic> toBluetoothPayload() {
    return {
      'id': id,
      'type': type.index,
      'lat': location.latitude,
      'lng': location.longitude,
      'title': title,
      'desc': description,
      'priority': priority.index,
      'status': status.index,
      'created': createdAt.millisecondsSinceEpoch,
      'updated': updatedAt.millisecondsSinceEpoch,
      'creator': createdBy,
      'verified': verifiedBy,
      'syncCount': syncCount,
    };
  }

  // Create from Bluetooth payload
  factory CommunityPin.fromBluetoothPayload(Map<String, dynamic> payload) {
    return CommunityPin(
      id: payload['id'] as String,
      type: PinType.values[payload['type'] as int],
      location: LatLng(payload['lat'] as double, payload['lng'] as double),
      title: payload['title'] as String,
      description: payload['desc'] as String,
      priority: PinPriority.values[payload['priority'] as int],
      status: PinStatus.values[payload['status'] as int],
      createdAt: DateTime.fromMillisecondsSinceEpoch(payload['created'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(payload['updated'] as int),
      createdBy: payload['creator'] as String,
      verifiedBy: List<String>.from(payload['verified'] ?? []),
      syncCount: payload['syncCount'] as int? ?? 0,
      isSyncedToBluetooth: true, // If we got it via Bluetooth, it's synced
    );
  }

  // Create a copy with modified fields
  CommunityPin copyWith({
    String? id,
    PinType? type,
    LatLng? location,
    String? title,
    String? description,
    PinPriority? priority,
    PinStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    bool? isSyncedToBluetooth,
    List<String>? verifiedBy,
    int? syncCount,
  }) {
    return CommunityPin(
      id: id ?? this.id,
      type: type ?? this.type,
      location: location ?? this.location,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      isSyncedToBluetooth: isSyncedToBluetooth ?? this.isSyncedToBluetooth,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      syncCount: syncCount ?? this.syncCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityPin && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CommunityPin{id: $id, type: $type, title: $title, location: $location}';
  }
}

// Helper extensions
extension PinTypeExtension on PinType {
  String get displayName {
    switch (this) {
      case PinType.hazard:
        return 'Hazard';
      case PinType.resource:
        return 'Resource';
      case PinType.safe_zone:
        return 'Safe Zone';
      case PinType.blocked_road:
        return 'Blocked Road';
      case PinType.water_source:
        return 'Water Source';
      case PinType.shelter:
        return 'Shelter';
      case PinType.medical:
        return 'Medical';
      case PinType.food:
        return 'Food';
      case PinType.fire:
        return 'Fire';
      case PinType.flood:
        return 'Flood';
      case PinType.landslide:
        return 'Landslide';
      case PinType.evacuation_route:
        return 'Evacuation Route';
      case PinType.emergency_contact:
        return 'Emergency Contact';
      case PinType.other:
        return 'Other';
    }
  }

  String get iconName {
    switch (this) {
      case PinType.hazard:
        return 'warning';
      case PinType.resource:
        return 'inventory';
      case PinType.safe_zone:
        return 'shield';
      case PinType.blocked_road:
        return 'block';
      case PinType.water_source:
        return 'water_drop';
      case PinType.shelter:
        return 'home';
      case PinType.medical:
        return 'medical_services';
      case PinType.food:
        return 'restaurant';
      case PinType.fire:
        return 'local_fire_department';
      case PinType.flood:
        return 'waves';
      case PinType.landslide:
        return 'landslide';
      case PinType.evacuation_route:
        return 'directions_run';
      case PinType.emergency_contact:
        return 'contact_phone';
      case PinType.other:
        return 'place';
    }
  }

  bool get isHazard {
    switch (this) {
      case PinType.hazard:
      case PinType.blocked_road:
      case PinType.fire:
      case PinType.flood:
      case PinType.landslide:
        return true;
      default:
        return false;
    }
  }

  bool get isResource {
    switch (this) {
      case PinType.resource:
      case PinType.water_source:
      case PinType.shelter:
      case PinType.medical:
      case PinType.food:
      case PinType.safe_zone:
      case PinType.evacuation_route:
      case PinType.emergency_contact:
        return true;
      default:
        return false;
    }
  }
}