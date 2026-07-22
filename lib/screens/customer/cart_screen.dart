import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../repositories/firebase/firestore_product_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/cart_item_tile.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final String uid;

  const CartScreen({super.key, required this.uid});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();
  double _discount = 0;

  static const _kFreeShippingThreshold = 0; // shipping is always free for now

  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(CartLoadRequested(widget.uid));
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _incrementQuantity(String productSlug, int currentQuantity) {
    context.read<CartBloc>().add(
          CartItemQuantityUpdated(
            uid: widget.uid,
            productSlug: productSlug,
            quantity: currentQuantity + 1,
          ),
        );
  }

  void _decrementQuantity(String productSlug, int currentQuantity) {
    context.read<CartBloc>().add(
          CartItemQuantityUpdated(
            uid: widget.uid,
            productSlug: productSlug,
            quantity: currentQuantity - 1,
          ),
        );
  }

  void _removeItem(String productSlug) {
    context.read<CartBloc>().add(
          CartItemRemoved(
            uid: widget.uid,
            productSlug: productSlug,
          ),
        );
  }

  void _applyCoupon(double subtotal) {
    final code = _couponController.text.trim().toUpperCase();
    setState(() {
      _discount = code == 'TACTIC20' ? subtotal * 0.20 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final subtotal = state.subtotal;
        final total = (subtotal - _discount).clamp(0.0, double.infinity).toDouble();
        final itemCount = state.itemCount;

        return Scaffold(
          backgroundColor: kBackground,
          appBar: AppBar(
            backgroundColor: kBackground,
            foregroundColor: kNeon,
            title: const Text(
              'GIỎ HÀNG',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          body: SafeArea(
            child: state.status == CartStatus.loading && state.items.isEmpty
                ? const Center(child: CircularProgressIndicator(color: kNeon))
                : state.status == CartStatus.failure && state.items.isEmpty
                    ? _buildError(state.error ?? 'Lỗi tải giỏ hàng')
                    : state.items.isEmpty
                        ? _buildEmptyState()
                        : _buildCartContent(state, subtotal, total, itemCount),
          ),
        );
      },
    );
  }

  // ─── States ──────────────────────────────────────────────────────────────

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.read<CartBloc>().add(CartLoadRequested(widget.uid)),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildHeader(0),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white24,
                  size: 56,
                ),
                SizedBox(height: 12),
                Text(
                  'Giỏ hàng của bạn đang trống',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Main content ────────────────────────────────────────────────────────

  Widget _buildCartContent(CartState state, double subtotal, double total, int itemCount) {
    return Column(
      children: [
        _buildHeader(itemCount),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              ...state.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CartItemTile(
                    item: item,
                    onIncrement: () => _incrementQuantity(item.product.slug, item.quantity),
                    onDecrement: () => _decrementQuantity(item.product.slug, item.quantity),
                    onRemove: () => _removeItem(item.product.slug),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildCouponField(subtotal),
              const SizedBox(height: 20),
              _buildSummary(subtotal, total),
            ],
          ),
        ),
        _buildCheckoutBar(state, total),
      ],
    );
  }

  Widget _buildHeader(int itemCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$itemCount mặt hàng',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        ],
      ),
    );
  }

  Widget _buildCouponField(double subtotal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sell_outlined, color: Colors.white38, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _couponController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Mã giảm giá (TACTIC20)',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          ),
          TextButton(
            onPressed: () => _applyCoupon(subtotal),
            style: TextButton.styleFrom(
              backgroundColor: kNeon,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Áp dụng',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(double subtotal, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryRow('Tạm tính', '${formatVnd(subtotal)}đ'),
        const SizedBox(height: 8),
        _summaryRow(
          'Phí vận chuyển',
          _kFreeShippingThreshold == 0 ? 'Miễn phí' : '',
        ),
        if (_discount > 0) ...[
          const SizedBox(height: 8),
          _summaryRow('Giảm giá', '-${formatVnd(_discount)}đ'),
        ],
        const SizedBox(height: 12),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tổng cộng',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${formatVnd(total)}đ',
              style: const TextStyle(
                color: kNeon,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _buildCheckoutBar(CartState state, double total) {
    final isLoading = state.status == CartStatus.loading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  // TODO: This logic should ideally be moved to the BLoC as well
                  try {
                    final productRepository = FirestoreProductRepository();
                    for (final item in state.items) {
                      final freshProd = await productRepository.getProductBySlug(item.product.slug);
                      if (freshProd == null) {
                        throw Exception('Sản phẩm "${item.product.name}" không còn tồn tại.');
                      }
                      if (item.quantity > freshProd.stock) {
                        throw Exception(
                          'Sản phẩm "${item.product.name}" chỉ còn lại ${freshProd.stock} mặt hàng trong kho. Vui lòng giảm số lượng.',
                        );
                      }
                    }

                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(
                          uid: widget.uid,
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: kNeon,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          child: Text(
            'Thanh toán · ${formatVnd(total)}đ',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
