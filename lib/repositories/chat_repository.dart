import '../models/chat_message.dart';
import '../models/chat_room.dart';

abstract class ChatRepository {
  Stream<List<ChatRoom>> getChatRooms();
  Stream<List<ChatMessage>> getMessages(String customerId);
  Future<void> sendMessage({
    required String customerId,
    required String customerEmail,
    required String senderId,
    required String senderRole,
    required String content,
  });
  Future<void> markAsRead({
    required String customerId,
    required bool isForAdmin,
  });
}
