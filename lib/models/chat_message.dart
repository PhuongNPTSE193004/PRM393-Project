import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestampVal = data['timestamp'];
    DateTime parsedTime = DateTime.now();
    if (timestampVal is Timestamp) {
      parsedTime = timestampVal.toDate();
    }
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderRole: data['senderRole'] ?? 'customer',
      content: data['content'] ?? '',
      timestamp: parsedTime,
    );
  }
}
