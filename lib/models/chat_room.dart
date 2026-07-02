import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String customerId;
  final String customerEmail;
  final String? customerName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool unreadByAdmin;
  final bool unreadByCustomer;

  ChatRoom({
    required this.customerId,
    required this.customerEmail,
    this.customerName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadByAdmin,
    required this.unreadByCustomer,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestampVal = data['lastMessageTime'];
    DateTime parsedTime = DateTime.now();
    if (timestampVal is Timestamp) {
      parsedTime = timestampVal.toDate();
    }
    return ChatRoom(
      customerId: doc.id,
      customerEmail: data['customerEmail'] ?? '',
      customerName: data['customerName'],
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: parsedTime,
      unreadByAdmin: data['unreadByAdmin'] ?? false,
      unreadByCustomer: data['unreadByCustomer'] ?? false,
    );
  }
}
