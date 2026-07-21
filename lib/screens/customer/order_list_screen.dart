import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  final String uid;

  const OrderListScreen({super.key, required this.uid});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        foregroundColor: kNeon,
        title: const Text(
          'ĐƠN HÀNG CỦA TÔI',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('orders')
                  .where('user_id', isEqualTo: widget.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kNeon),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi tải đơn hàng: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                var orders = docs.map((d) => OrderModel.fromFirestore(d)).toList();

                // Client side sorting by createdAt descending
                orders.sort((a, b) {
                  final tA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final tB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return tB.compareTo(tA);
                });

                if (_selectedFilter != 'all') {
                  orders = orders.where((o) => o.status == _selectedFilter).toList();
                }

                if (orders.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Tất cả'},
      {'key': 'pending', 'label': 'Đang xử lý'},
      {'key': 'paid', 'label': 'Đã thanh toán'},
      {'key': 'shipped', 'label': 'Đang giao'},
      {'key': 'cancelled', 'label': 'Đã hủy'},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedFilter == f['key'];

          return ChoiceChip(
            label: Text(
              f['label']!,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontFamily: 'monospace',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            selected: isSelected,
            selectedColor: kNeon,
            backgroundColor: kSurface,
            onSelected: (_) {
              setState(() => _selectedFilter = f['key']!);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.receipt_long_outlined, color: Colors.white24, size: 64),
          SizedBox(height: 16),
          Text(
            'Chưa có đơn hàng nào',
            style: TextStyle(
              color: Colors.white54,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final dateStr = order.createdAt != null
        ? '${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year}'
        : 'Mới tạo';

    final shortId = order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kSurfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: kNeon, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '#$shortId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                _buildStatusPill(order.status),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngày đặt: $dateStr',
                      style: const TextStyle(color: kMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thanh toán: ${order.paymentMethod.toUpperCase()}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Tổng tiền', style: TextStyle(color: kMuted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      '${formatVnd(order.total)}đ',
                      style: const TextStyle(
                        color: kNeon,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(order: order),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Text('Xem Chi Tiết'),
                  ),
                ),
                if (order.status == 'pending') ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _confirmCancelOrder(order),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    child: const Text('Hủy Đơn'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'paid':
        bg = Colors.green.withValues(alpha: 0.2);
        fg = Colors.greenAccent;
        text = 'ĐÃ THANH TOÁN';
        break;
      case 'shipped':
        bg = Colors.blue.withValues(alpha: 0.2);
        fg = Colors.lightBlueAccent;
        text = 'ĐANG GIAO HÀNG';
        break;
      case 'delivered':
        bg = Colors.teal.withValues(alpha: 0.2);
        fg = Colors.tealAccent;
        text = 'ĐÃ GIAO HÀNG';
        break;
      case 'cancelled':
        bg = Colors.red.withValues(alpha: 0.2);
        fg = Colors.redAccent;
        text = 'ĐÃ HỦY';
        break;
      default:
        bg = Colors.amber.withValues(alpha: 0.2);
        fg = Colors.amberAccent;
        text = 'ĐANG XỬ LÝ';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Future<void> _confirmCancelOrder(OrderModel order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceCard,
        title: const Text('Hủy Đơn Hàng', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bạn có chắc chắn muốn hủy đơn hàng này không?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Quay lại', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận Hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _firestore.collection('orders').doc(order.id).update({
        'status': 'cancelled',
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đơn hàng đã được hủy thành công')),
      );
    }
  }
}
