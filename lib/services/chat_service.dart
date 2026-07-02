import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../repositories/chat_repository.dart';
import '../repositories/firebase/firestore_chat_repository.dart';

class ChatService {
  ChatService({ChatRepository? chatRepository})
      : _chatRepository = chatRepository ?? FirestoreChatRepository();

  final ChatRepository _chatRepository;

  Stream<List<ChatRoom>> getChatRooms() {
    return _chatRepository.getChatRooms();
  }

  Stream<List<ChatMessage>> getMessages(String customerId) {
    return _chatRepository.getMessages(customerId);
  }

  Future<void> sendMessage({
    required String customerId,
    required String customerEmail,
    required String senderId,
    required String senderRole,
    required String content,
  }) {
    if (content.trim().isEmpty) {
      throw ArgumentError('Message content cannot be empty.');
    }
    return _chatRepository.sendMessage(
      customerId: customerId,
      customerEmail: customerEmail,
      senderId: senderId,
      senderRole: senderRole,
      content: content,
    );
  }

  Future<void> markAsRead({
    required String customerId,
    required bool isForAdmin,
  }) {
    return _chatRepository.markAsRead(
      customerId: customerId,
      isForAdmin: isForAdmin,
    );
  }
}
