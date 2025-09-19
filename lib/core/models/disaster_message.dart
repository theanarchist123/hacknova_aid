/// Enum for different types of messages in the disaster relief system
enum MessageType {
  regular,
  emergency,
  sos,
  location,
  system
}

/// Enum for message status
enum MessageStatus {
  sending,
  sent,
  delivered,
  failed
}

/// Message model for Bluetooth communication in disaster relief scenarios
class DisasterMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final Map<String, dynamic>? metadata; // For location, emergency details etc.

  DisasterMessage({
    String? id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    DateTime? timestamp,
    this.status = MessageStatus.sending,
    this.metadata,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       timestamp = timestamp ?? DateTime.now();

  /// Create a copy of the message with updated fields
  DisasterMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return DisasterMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert message to JSON for transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.toString().split('.').last,
      'metadata': metadata,
    };
  }

  /// Create message from JSON
  factory DisasterMessage.fromJson(Map<String, dynamic> json) {
    return DisasterMessage(
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MessageType.regular,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      metadata: json['metadata'],
    );
  }

  /// Convert to database map
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.toString().split('.').last,
      'metadata': metadata != null ? metadata.toString() : null,
    };
  }

  /// Create from database map
  factory DisasterMessage.fromDatabase(Map<String, dynamic> map) {
    return DisasterMessage(
      id: map['id'],
      senderId: map['sender_id'],
      senderName: map['sender_name'],
      content: map['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MessageType.regular,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      metadata: map['metadata'] != null ? {'raw': map['metadata']} : null,
    );
  }

  /// Check if this is an emergency message
  bool get isEmergency => type == MessageType.emergency || type == MessageType.sos;

  /// Check if this is a system message
  bool get isSystem => type == MessageType.system;

  /// Get formatted timestamp for display
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Create an emergency SOS message
  factory DisasterMessage.createSOS({
    required String senderId,
    required String senderName,
    String? location,
    String? emergencyType,
  }) {
    final metadata = <String, dynamic>{};
    if (location != null) metadata['location'] = location;
    if (emergencyType != null) metadata['emergencyType'] = emergencyType;

    return DisasterMessage(
      senderId: senderId,
      senderName: senderName,
      content: '🆘 EMERGENCY SOS - $senderName needs immediate assistance!',
      type: MessageType.sos,
      metadata: metadata,
    );
  }

  /// Create a system notification message
  factory DisasterMessage.createSystem({
    required String content,
    String? senderId,
  }) {
    return DisasterMessage(
      senderId: senderId ?? 'system',
      senderName: 'System',
      content: content,
      type: MessageType.system,
      status: MessageStatus.delivered,
    );
  }

  @override
  String toString() {
    return 'DisasterMessage(id: $id, sender: $senderName, type: $type, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisasterMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}