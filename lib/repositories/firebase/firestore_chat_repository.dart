import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../chat_repository.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  @override
  Stream<List<ChatRoom>> getChatRooms() {
    return _chats
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<List<ChatMessage>> getMessages(String customerId) {
    return _chats
        .doc(customerId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> sendMessage({
    required String customerId,
    required String customerEmail,
    required String senderId,
    required String senderRole,
    required String content,
  }) async {
    final timestamp = FieldValue.serverTimestamp();

    // 1. Write the message to the messages subcollection
    await _chats.doc(customerId).collection('messages').add({
      'senderId': senderId,
      'senderRole': senderRole,
      'content': content.trim(),
      'timestamp': timestamp,
    });

    // 2. Update the parent chat room doc
    final isFromAdmin = senderRole == 'admin' || senderRole == 'staff';
    await _chats.doc(customerId).set({
      'customerEmail': customerEmail.trim().toLowerCase(),
      'lastMessage': content.trim(),
      'lastMessageTime': timestamp,
      'unreadByAdmin': isFromAdmin ? false : true,
      'unreadByCustomer': isFromAdmin ? true : false,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> markAsRead({
    required String customerId,
    required bool isForAdmin,
  }) async {
    final updateField = isForAdmin ? 'unreadByAdmin' : 'unreadByCustomer';
    await _chats.doc(customerId).set({
      updateField: false,
    }, SetOptions(merge: true));
  }
}
