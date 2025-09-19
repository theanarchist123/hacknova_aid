/// Message model for one-way BLE messaging
class DirectMessage {
  final String id;
  final String content;
  final String senderName;
  final DateTime timestamp;
  final bool isSent; // true if sent by this device, false if received

  DirectMessage({
    required this.id,
    required this.content,
    required this.senderName,
    required this.timestamp,
    required this.isSent,
  });

  factory DirectMessage.sent(String content, String senderName) {
    return DirectMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      senderName: senderName,
      timestamp: DateTime.now(),
      isSent: true,
    );
  }

  factory DirectMessage.received(String content, String senderName) {
    return DirectMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      senderName: senderName,
      timestamp: DateTime.now(),
      isSent: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'senderName': senderName,
      'timestamp': timestamp.toIso8601String(),
      'isSent': isSent,
    };
  }

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      id: json['id'],
      content: json['content'],
      senderName: json['senderName'],
      timestamp: DateTime.parse(json['timestamp']),
      isSent: json['isSent'],
    );
  }

  String get timeString {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}