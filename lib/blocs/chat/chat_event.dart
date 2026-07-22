import 'package:equatable/equatable.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatMessagesSubscriptionRequested extends ChatEvent {
  final String customerId;
  const ChatMessagesSubscriptionRequested(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class ChatRoomsSubscriptionRequested extends ChatEvent {}

class ChatMessageSent extends ChatEvent {
  final String customerId;
  final String customerEmail;
  final String senderId;
  final String senderRole;
  final String content;

  const ChatMessageSent({
    required this.customerId,
    required this.customerEmail,
    required this.senderId,
    required this.senderRole,
    required this.content,
  });

  @override
  List<Object?> get props => [customerId, customerEmail, senderId, senderRole, content];
}

class ChatMessagesInternalChanged extends ChatEvent {
  final List<ChatMessage> messages;
  const ChatMessagesInternalChanged(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatRoomsInternalChanged extends ChatEvent {
  final List<ChatRoom> rooms;
  const ChatRoomsInternalChanged(this.rooms);

  @override
  List<Object?> get props => [rooms];
}
