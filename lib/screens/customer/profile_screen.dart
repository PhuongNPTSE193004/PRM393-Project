import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../repositories/firebase/firestore_notification_repository.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'about_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'TÀI KHOẢN',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Vui lòng đăng nhập',
                style: TextStyle(color: Colors.white54, fontFamily: 'monospace'),
              ),
            )
          : SafeArea(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, profileSnapshot) {
                  final profile = profileSnapshot.data?.data();
                  final displayName = (profile?['displayName'] as String?)?.trim();
                  final role = (profile?['role'] as String?)?.toUpperCase() ?? 'OPERATOR';

                  final nameToShow = displayName?.isNotEmpty == true
                      ? displayName!
                      : (user.displayName?.isNotEmpty == true
                          ? user.displayName!
                          : (user.email?.split('@').first ?? 'operator'));

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('user_id', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, ordersSnapshot) {
                      final orders = (ordersSnapshot.data?.docs ?? const [])
                        ..sort((a, b) {
                          final aVal = a.data()['created_at'];
                          final bVal = b.data()['created_at'];
                          final aTime = aVal is Timestamp ? aVal.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                          final bTime = bVal is Timestamp ? bVal.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                          return bTime.compareTo(aTime);
                        });

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          // ─── User Header Card ─────────────────────────────
                          _buildUserHeaderCard(nameToShow, user.email ?? '', role),

                          const SizedBox(height: 20),

                          // ─── Section 1: Đơn hàng gần đây ─────────────────
                          const Text(
                            'Đơn hàng gần đây',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (ordersSnapshot.connectionState == ConnectionState.waiting)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(color: kNeon, strokeWidth: 2),
                              ),
                            )
                          else if (orders.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: kSurfaceCard,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: const Center(
                                child: Text(
                                  'Chưa có đơn hàng nào',
                                  style: TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 12),
                                ),
                              ),
                            )
                          else
                            ...orders.take(3).map((doc) => _buildOrderTile(context, doc)),

                          const SizedBox(height: 20),

                          // ─── Section 2: Tài khoản Options Card ────────────
                          const Text(
                            'Tài khoản',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildAccountGroupCard(context, user),

                          const SizedBox(height: 24),

                          // ─── Logout Button ────────────────────────────────
                          _buildLogoutButton(context),

                          const SizedBox(height: 20),

                          // ─── App Footer Version ───────────────────────────
                          const Center(
                            child: Text(
                              'v1.0.0  ·  AIRSOFTGEAR VN',
                              style: TextStyle(
                                color: kMuted,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  // ─── User Header Card Component ───────────────────────────────────────────
  Widget _buildUserHeaderCard(String name, String email, String role) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'O';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circle Avatar Initial
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: kNeon,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // User Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    color: kMuted,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '$role  ·  TIER 2',
                      style: const TextStyle(
                        color: kNeon,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recent Order Tile Component ──────────────────────────────────────────
  Widget _buildOrderTile(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final status = (data['status'] as String?) ?? 'pending';
    final createdAtVal = data['created_at'];

    String dateStr = 'Mới đây';
    if (createdAtVal is Timestamp) {
      final date = createdAtVal.toDate();
      dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    // Status translations & colors
    String statusText = 'Đang xử lý';
    Color statusColor = Colors.amber;
    if (status == 'delivered' || status == 'completed' || status == 'success') {
      statusText = 'Đã giao';
      statusColor = kNeon;
    } else if (status == 'shipping' || status == 'delivering') {
      statusText = 'Đang giao';
      statusColor = Colors.orangeAccent;
    } else if (status == 'cancelled') {
      statusText = 'Đã hủy';
      statusColor = Colors.redAccent;
    }

    final code = doc.id.length >= 4 ? doc.id.substring(0, 4).toUpperCase() : doc.id.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kSurfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Green Box Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kNeon.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kNeon.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: kNeon,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Order ID & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#A-$code',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: kMuted,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // Price & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatVnd(total),
                style: const TextStyle(
                  color: kNeon,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Grouped Account Card ─────────────────────────────────────────────────
  Widget _buildAccountGroupCard(BuildContext context, User user) {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _buildAccountTile(
            icon: Icons.location_on_outlined,
            title: 'Cửa hàng & địa chỉ',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          const Divider(height: 1, color: Colors.white12, indent: 48),
          _buildAccountTile(
            icon: Icons.notifications_outlined,
            title: 'Thông báo',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(
                    uid: user.uid,
                    service: NotificationService(FirestoreNotificationRepository()),
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Colors.white12, indent: 48),
          _buildAccountTile(
            icon: Icons.chat_outlined,
            title: 'Hỗ trợ khách hàng',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerChatScreen(
                    uid: user.uid,
                    email: user.email ?? 'customer@airsoftvn.com',
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Colors.white12, indent: 48),
          _buildAccountTile(
            icon: Icons.favorite_border_rounded,
            title: 'Yêu thích',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Danh sách sản phẩm đã lưu yêu thích'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(height: 1, color: Colors.white12, indent: 48),
          _buildAccountTile(
            icon: Icons.settings_outlined,
            title: 'Cài đặt',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cài đặt ứng dụng AirsoftGear'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Single Account List Tile ──────────────────────────────────────────────
  Widget _buildAccountTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: kNeon.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: kNeon, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white38,
        size: 20,
      ),
    );
  }

  // ─── Red Logout Button ────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF2B1518),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (!context.mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
