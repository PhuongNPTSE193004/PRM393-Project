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
      'read': false,
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

    // Update read state on individual messages sent by the other party
    try {
      final unreadSnap = await _chats
          .doc(customerId)
          .collection('messages')
          .where('read', isEqualTo: false)
          .get();

      if (unreadSnap.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in unreadSnap.docs) {
          final senderRole = doc.data()['senderRole'] as String?;
          final isFromOther = isForAdmin
              ? (senderRole == 'customer')
              : (senderRole == 'admin' || senderRole == 'staff');
          if (isFromOther) {
            batch.update(doc.reference, {'read': true});
          }
        }
        await batch.commit();
      }
    } catch (_) {}
  }
}
