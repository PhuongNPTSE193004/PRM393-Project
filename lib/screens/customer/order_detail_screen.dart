import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase();

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        foregroundColor: kNeon,
        title: Text(
          'ĐƠN HÀNG #$shortId',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 16),
            _buildShippingCard(),
            const SizedBox(height: 16),
            _buildOrderItemsSection(),
            const SizedBox(height: 16),
            _buildPaymentSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kNeon.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TRẠNG THÁI ĐƠN HÀNG',
                style: TextStyle(
                  color: kMuted,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusPill(order.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getStatusDescription(order.status),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: kNeon, size: 18),
              SizedBox(width: 8),
              Text(
                'THÔNG TIN GIAO HÀNG',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          Text(
            order.shippingName.isNotEmpty ? order.shippingName : 'Khách hàng',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'SĐT: ${order.shippingPhone.isNotEmpty ? order.shippingPhone : "Chưa cập nhật"}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Địa chỉ: ${order.shippingAddress}, ${order.shippingCity}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (order.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ghi chú: ${order.notes}',
              style: const TextStyle(color: kMuted, fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'DANH SÁCH SẢN PHẨM',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('order_items')
              .where('order_id', isEqualTo: order.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kNeon));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Không có chi tiết sản phẩm.', style: TextStyle(color: kMuted)),
              );
            }

            final items = docs.map((d) => OrderItemModel.fromFirestore(d)).toList();

            return Container(
              decoration: BoxDecoration(
                color: kSurfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(
                      item.productName,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${formatVnd(item.unitPrice)}đ x ${item.quantity}',
                      style: const TextStyle(color: kMuted, fontSize: 12),
                    ),
                    trailing: Text(
                      '${formatVnd(item.subtotal)}đ',
                      style: const TextStyle(
                        color: kNeon,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Phương thức thanh toán:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                order.paymentMethod.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng thanh toán:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                '${formatVnd(order.total)}đ',
                style: const TextStyle(
                  color: kNeon,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: TextStyle(color: fg, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'paid':
        return 'Đơn hàng đã được thanh toán thành công và đang chờ xử lý vận chuyển.';
      case 'shipped':
        return 'Đơn hàng đang trên đường giao tới địa chỉ của bạn.';
      case 'delivered':
        return 'Đơn hàng đã được giao thành công.';
      case 'cancelled':
        return 'Đơn hàng này đã bị hủy.';
      default:
        return 'Đơn hàng của bạn đang được cửa hàng xác nhận và xử lý.';
    }
  }
}
