import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        foregroundColor: kNeon,
        title: const Text(
          'TÀI KHOẢN',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Vui lòng đăng nhập',
                style: TextStyle(color: Colors.white54),
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
                  final displayName = (profile?['displayName'] as String?)
                      ?.trim();
                  final phone = (profile?['phone'] as String?)?.trim();
                  final address = (profile?['address'] as String?)?.trim();

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('user_id', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, ordersSnapshot) {
                      if (ordersSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Không thể tải lịch sử mua hàng',
                            style: TextStyle(color: Colors.red.shade300),
                          ),
                        );
                      }

                      if (ordersSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: kNeon),
                        );
                      }

                      final orders = (ordersSnapshot.data?.docs ?? const [])
                        ..sort((a, b) {
                          final aValue = a.data()['created_at'];
                          final bValue = b.data()['created_at'];
                          final aTime = aValue is Timestamp
                              ? aValue.toDate()
                              : DateTime.fromMillisecondsSinceEpoch(0);
                          final bTime = bValue is Timestamp
                              ? bValue.toDate()
                              : DateTime.fromMillisecondsSinceEpoch(0);
                          return bTime.compareTo(aTime);
                        });

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _ProfileHeader(
                            name: displayName?.isNotEmpty == true
                                ? displayName!
                                : (user.displayName?.isNotEmpty == true
                                      ? user.displayName!
                                      : user.email ?? 'Khách hàng'),
                            email: user.email ?? '',
                            phone: phone,
                            address: address,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'LỊCH SỬ MUA HÀNG',
                            style: TextStyle(
                              color: kNeon,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (orders.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: kSurface,
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Chưa có đơn hàng nào',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            )
                          else
                            ...orders.map(
                              (orderDoc) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _OrderCard(orderDoc: orderDoc),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    this.phone,
    this.address,
  });

  final String name;
  final String email;
  final String? phone;
  final String? address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kNeon.withOpacity(0.18),
              border: Border.all(color: kNeon),
            ),
            child: const Icon(Icons.person_outline, color: kNeon, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.white54)),
                if (phone != null && phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'SĐT: $phone',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
                if (address != null && address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Địa chỉ: $address',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.orderDoc});

  final QueryDocumentSnapshot<Map<String, dynamic>> orderDoc;

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final data = orderDoc.data();
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final status = (data['status'] as String?) ?? 'pending';
    final paymentMethod = (data['payment_method'] as String?) ?? 'cod';
    final createdAt = _formatDate(data['created_at']);

    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: Colors.white12),
      ),
      child: ExpansionTile(
        collapsedIconColor: Colors.white54,
        iconColor: kNeon,
        title: Text(
          'Đơn #${orderDoc.id.substring(0, 8)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$createdAt • ${status.toUpperCase()} • ${paymentMethod.toUpperCase()}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: Text(
          formatVnd(total),
          style: const TextStyle(color: kNeon, fontWeight: FontWeight.bold),
        ),
        children: [
          const Divider(height: 1, color: Colors.white12),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('order_items')
                  .where('order_id', isEqualTo: orderDoc.id)
                  .get(),
              builder: (context, itemsSnapshot) {
                if (itemsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(color: kNeon),
                  );
                }

                final items = itemsSnapshot.data?.docs ?? const [];
                if (items.isEmpty) {
                  return const Text(
                    'Không có dữ liệu sản phẩm cho đơn này.',
                    style: TextStyle(color: Colors.white54),
                  );
                }

                return Column(
                  children: items.map((itemDoc) {
                    final item = itemDoc.data();
                    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                    final unitPrice =
                        (item['unit_price'] as num?)?.toDouble() ?? 0;
                    final productName =
                        (item['product_name'] as String?) ?? 'Sản phẩm';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white54,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$productName x$quantity',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          Text(
                            formatVnd(unitPrice * quantity),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
