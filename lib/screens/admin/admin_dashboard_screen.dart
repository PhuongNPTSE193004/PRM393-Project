import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import 'admin_chat_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        foregroundColor: kNeon,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontFamily: 'monospace'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CONTROL PANEL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: kMuted,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuTile(
              context: context,
              icon: Icons.chat_bubble_outline,
              title: 'CUSTOMER CHATS',
              subtitle: 'View and reply to customer support requests',
              onTap: () {
                final uid = AuthService().currentUserId;
                if (uid == null) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminChatListScreen(
                      senderId: uid,
                      senderRole: 'admin',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kNeon,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        onPressed: () {
          final uid = AuthService().currentUserId;
          if (uid == null) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminChatListScreen(
                senderId: uid,
                senderRole: 'admin',
              ),
            ),
          );
        },
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(icon, color: kNeon, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: kMuted,
              fontSize: 11,
            ),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: kNeon, size: 16),
        onTap: onTap,
      ),
    );
  }
}
