import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _roomsSubscription;

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatState()) {
    on<ChatMessagesSubscriptionRequested>(_onMessagesSubscriptionRequested);
    on<ChatRoomsSubscriptionRequested>(_onRoomsSubscriptionRequested);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMessagesInternalChanged>(_onMessagesInternalChanged);
    on<ChatRoomsInternalChanged>(_onRoomsInternalChanged);
  }

  Future<void> _onMessagesSubscriptionRequested(
    ChatMessagesSubscriptionRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    await _messagesSubscription?.cancel();
    _messagesSubscription = _chatRepository.getMessages(event.customerId).listen(
      (messages) => add(ChatMessagesInternalChanged(messages)),
      onError: (e) => emit(state.copyWith(status: ChatStatus.failure, error: e.toString())),
    );
  }

  Future<void> _onRoomsSubscriptionRequested(
    ChatRoomsSubscriptionRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    await _roomsSubscription?.cancel();
    _roomsSubscription = _chatRepository.getChatRooms().listen(
      (rooms) => add(ChatRoomsInternalChanged(rooms)),
      onError: (e) => emit(state.copyWith(status: ChatStatus.failure, error: e.toString())),
    );
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.sendMessage(
        customerId: event.customerId,
        customerEmail: event.customerEmail,
        senderId: event.senderId,
        senderRole: event.senderRole,
        content: event.content,
      );
    } catch (e) {
      emit(state.copyWith(status: ChatStatus.failure, error: e.toString()));
    }
  }

  void _onMessagesInternalChanged(
    ChatMessagesInternalChanged event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(
      status: ChatStatus.success,
      messages: event.messages,
    ));
  }

  void _onRoomsInternalChanged(
    ChatRoomsInternalChanged event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(
      status: ChatStatus.success,
      rooms: event.rooms,
    ));
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _roomsSubscription?.cancel();
    return super.close();
  }
}
