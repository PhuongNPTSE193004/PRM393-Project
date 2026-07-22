import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';
import '../../models/chat_message.dart';
import '../../theme/app_theme.dart';

class CustomerChatScreen extends StatefulWidget {
  final String uid;
  final String email;

  const CustomerChatScreen({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ChatMessagesSubscriptionRequested(widget.uid));
    _markAsRead();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _markAsRead() {
    // Ideally this should be an event in ChatBloc
    // context.read<ChatBloc>().add(ChatMarkAsReadRequested(customerId: widget.uid, isForAdmin: false));
  }

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    _messageCtrl.clear();

    context.read<ChatBloc>().add(
          ChatMessageSent(
            customerId: widget.uid,
            customerEmail: widget.email,
            senderId: widget.uid,
            senderRole: 'customer',
            content: text,
          ),
        );
    _scrollToBottom();
    _markAsRead();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        foregroundColor: kNeon,
        title: const Text(
          'SUPPORT CHAT',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.status == ChatStatus.loading && state.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: kNeon),
                  );
                }

                if (state.status == ChatStatus.failure && state.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Lỗi kết nối: ${state.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final messages = state.messages;
                if (messages.isEmpty) {
                  return _buildEmptyChat();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == widget.uid;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white24,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Hỏi đáp trực tiếp với Admin / Cửa hàng',
            style: TextStyle(
              color: Colors.white54,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy gửi tin nhắn đầu tiên bên dưới.',
            style: TextStyle(
              color: kMuted,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    final timeStr = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isMe ? kNeon : kSurface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(8),
                topRight: const Radius.circular(8),
                bottomLeft: Radius.circular(isMe ? 8 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 8),
              ),
              border: isMe
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
            ),
            child: Text(
              msg.content,
              style: TextStyle(
                color: isMe ? Colors.black : Colors.white,
                fontSize: 14,
                height: 1.3,
                fontFamily: 'monospace',
                fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: kMuted,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.read ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 11,
                    color: msg.read ? kNeon : kMuted,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isSending = state.status == ChatStatus.loading && state.messages.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kSurface,
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      hintStyle: TextStyle(color: Colors.white30),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kNeon, width: 1),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: kNeon,
                  disabledColor: kMuted,
                  onPressed: isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
