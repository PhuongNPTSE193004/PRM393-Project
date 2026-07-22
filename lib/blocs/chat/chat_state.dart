import 'package:equatable/equatable.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';

enum ChatStatus { initial, loading, success, failure }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatMessage> messages;
  final List<ChatRoom> rooms;
  final String? error;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.rooms = const [],
    this.error,
  });

  @override
  List<Object?> get props => [status, messages, rooms, error];

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    List<ChatRoom>? rooms,
    String? error,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      rooms: rooms ?? this.rooms,
      error: error ?? this.error,
    );
  }
}
