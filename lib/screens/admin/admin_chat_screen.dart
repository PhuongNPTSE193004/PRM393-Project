import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';

class AdminChatScreen extends StatefulWidget {
  final String customerId;
  final String customerEmail;
  final String senderId; // Admin's / staff's UID
  final String senderRole; // 'admin' or 'staff'

  const AdminChatScreen({
    super.key,
    required this.customerId,
    required this.customerEmail,
    required this.senderId,
    required this.senderRole,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _chatService = ChatService();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    try {
      await _chatService.markAsRead(
        customerId: widget.customerId,
        isForAdmin: true,
      );
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageCtrl.clear();

    try {
      await _chatService.sendMessage(
        customerId: widget.customerId,
        customerEmail: widget.customerEmail,
        senderId: widget.senderId,
        senderRole: widget.senderRole,
        content: text,
      );
      _scrollToBottom();
      _markAsRead();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi tin nhắn: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CUSTOMER SUPPORT',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              widget.customerEmail,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.customerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kNeon),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi kết nối: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];
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
                    final isCustomer = msg.senderRole == 'customer';
                    return _buildMessageBubble(msg, !isCustomer);
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
            'Bắt đầu cuộc hội thoại hỗ trợ khách hàng',
            style: TextStyle(
              color: Colors.white54,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.customerEmail,
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
            child: Text(
              timeStr,
              style: const TextStyle(
                color: kMuted,
                fontSize: 9,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
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
                  hintText: 'Trả lời khách hàng...',
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
              onPressed: _isSending ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
