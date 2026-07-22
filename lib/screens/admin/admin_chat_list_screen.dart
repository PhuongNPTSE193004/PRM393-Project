import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';
import '../../models/chat_room.dart';
import '../../theme/app_theme.dart';
import 'admin_chat_screen.dart';

class AdminChatListScreen extends StatefulWidget {
  final String senderId; // Either the admin's UID or staff's UID
  final String senderRole; // 'admin' or 'staff'

  const AdminChatListScreen({
    super.key,
    required this.senderId,
    required this.senderRole,
  });

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ChatRoomsSubscriptionRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        foregroundColor: kNeon,
        title: const Text(
          'CUSTOMER INBOX',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state.status == ChatStatus.loading && state.rooms.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: kNeon),
            );
          }

          if (state.status == ChatStatus.failure && state.rooms.isEmpty) {
            final isPermission = state.error.toString().contains('permission-denied');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.amber, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      isPermission
                          ? 'CẦN CẤP QUYỀN FIRESTORE RULES'
                          : 'LỖI TẢI HỘP THƯ',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPermission
                          ? 'Firebase Security Rules cần cho phép tài khoản Admin/Staff đọc collection "chats". Vui lòng cập nhật Rules trên Firebase Console.'
                          : '${state.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kMuted,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final rooms = state.rooms;
          if (rooms.isEmpty) {
            return _buildEmptyInbox();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _buildChatRoomTile(room);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyInbox() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mail_outline_rounded,
            color: Colors.white24,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Hộp thư hỗ trợ trống',
            style: TextStyle(
              color: Colors.white54,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hiện tại chưa có khách hàng nào nhắn tin.',
            style: TextStyle(
              color: kMuted,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomTile(ChatRoom room) {
    final hasUnread = room.unreadByAdmin;
    final timeStr = _formatTime(room.lastMessageTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(
          color: hasUnread ? kNeon.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminChatScreen(
                customerId: room.customerId,
                customerEmail: room.customerEmail,
                senderId: widget.senderId,
                senderRole: widget.senderRole,
              ),
            ),
          );
        },
        title: Text(
          room.customerEmail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            room.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasUnread ? Colors.white70 : kMuted,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeStr,
              style: TextStyle(
                color: kMuted,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            if (hasUnread)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: kNeon,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes}p trước';
    if (diff.inDays < 1) return '${diff.inHours}h trước';
    return '${time.day}/${time.month}';
  }
}
