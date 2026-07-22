import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../blocs/order/order_state.dart';
import '../../models/order.dart';
import '../../services/push_notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../customer/order_detail_screen.dart';

class AdminOrderListScreen extends StatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  State<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends State<AdminOrderListScreen> {
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(const OrderSubscriptionRequested(null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        foregroundColor: kNeon,
        title: const Text(
          'QUẢN LÝ ĐƠN HÀNG',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: state.status == OrderStatus.loading && state.orders.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: kNeon))
                    : state.status == OrderStatus.failure && state.orders.isEmpty
                        ? Center(
                            child: Text(
                              'Lỗi tải đơn hàng: ${state.error}',
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          )
                        : _buildOrderList(state.orders),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> allOrders) {
    var orders = allOrders;
    if (_selectedStatus != 'all') {
      orders = orders.where((o) => o.status == _selectedStatus).toList();
    }

    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'Không có đơn hàng nào.',
          style: TextStyle(color: kMuted, fontFamily: 'monospace'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildAdminOrderCard(order);
      },
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Tất cả'},
      {'key': 'pending', 'label': 'Đang xử lý'},
      {'key': 'paid', 'label': 'Đã thanh toán'},
      {'key': 'shipped', 'label': 'Đang giao'},
      {'key': 'delivered', 'label': 'Đã giao'},
      {'key': 'cancelled', 'label': 'Đã hủy'},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedStatus == f['key'];

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
            backgroundColor: kSurfaceCard,
            onSelected: (_) {
              setState(() => _selectedStatus = f['key']!);
            },
          );
        },
      ),
    );
  }

  Widget _buildAdminOrderCard(OrderModel order) {
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
                Text(
                  '#$shortId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
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
            const SizedBox(height: 8),
            Text(
              'Người nhận: ${order.shippingName} (${order.shippingPhone})',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            Text(
              'Địa chỉ: ${order.shippingAddress}, ${order.shippingCity}',
              style: const TextStyle(color: kMuted, fontSize: 12),
            ),
            const Divider(color: Colors.white10, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: ['pending', 'paid', 'shipped', 'delivered', 'cancelled'].contains(order.status)
                      ? order.status
                      : 'pending',
                  dropdownColor: kSurfaceCard,
                  style: const TextStyle(color: kNeon, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  underline: Container(height: 1, color: kNeon),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Đang xử lý')),
                    DropdownMenuItem(value: 'paid', child: Text('Đã thanh toán')),
                    DropdownMenuItem(value: 'shipped', child: Text('Đang giao hàng')),
                    DropdownMenuItem(value: 'delivered', child: Text('Đã giao hàng')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
                  ],
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      _updateOrderStatus(order, newStatus);
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order: order),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSurface,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Chi Tiết'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(OrderModel order, String newStatus) async {
    context.read<OrderBloc>().add(OrderStatusUpdateRequested(
          orderId: order.id,
          newStatus: newStatus,
        ));

    // Send push notification & store notification record for customer
    try {
      await PushNotificationService().sendOrderStatusPushNotification(
        userId: order.userId,
        orderId: order.id,
        status: newStatus,
      );
    } catch (e) {
      debugPrint('Failed to trigger push notification: $e');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã cập nhật trạng thái đơn hàng thành: $newStatus (Push Notification Sent)')),
    );
  }
}
