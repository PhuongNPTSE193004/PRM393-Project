import 'package:flutter/material.dart';

import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/cart_item_tile.dart';

class CartScreen extends StatefulWidget {
  final String uid;
  final CartService cartService;

  const CartScreen({
    super.key,
    required this.uid,
    required this.cartService,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  final _couponController = TextEditingController();
  double _discount = 0;

  static const _kFreeShippingThreshold = 0; // shipping is always free for now

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.cartService.getCartItems(widget.uid);
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải giỏ hàng. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  Future<void> _incrementQuantity(CartItem item) async {
    await widget.cartService.updateQuantity(
      uid: widget.uid,
      productSlug: item.product.slug,
      quantity: item.quantity + 1,
    );
    if (!mounted) return;
    _loadCart();
  }

  Future<void> _decrementQuantity(CartItem item) async {
    await widget.cartService.updateQuantity(
      uid: widget.uid,
      productSlug: item.product.slug,
      quantity: item.quantity - 1,
    );
    if (!mounted) return;
    _loadCart();
  }

  Future<void> _removeItem(CartItem item) async {
    await widget.cartService.removeItem(
      uid: widget.uid,
      productSlug: item.product.slug,
    );
    if (!mounted) return;
    _loadCart();
  }

  void _applyCoupon() {
    // TODO: replace with real coupon validation once a CouponService exists.
    // Kept local to UI state for now since there is no coupon repository
    // in the current architecture.
    final code = _couponController.text.trim().toUpperCase();
    final subtotal = widget.cartService.calculateSubtotal(_items);

    setState(() {
      _discount = code == 'TACTIC20' ? subtotal * 0.20 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.cartService.calculateSubtotal(_items);
    final total = (subtotal - _discount).clamp(0.0, double.infinity).toDouble();
    final itemCount = widget.cartService.calculateItemCount(_items);

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kNeon))
            : _errorMessage != null
            ? _buildError(_errorMessage!)
            : _items.isEmpty
            ? _buildEmptyState()
            : _buildCartContent(subtotal, total, itemCount),
      ),
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
          TextButton(onPressed: _loadCart, child: const Text('Thử lại')),
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
                Icon(Icons.shopping_cart_outlined, color: Colors.white24, size: 56),
                SizedBox(height: 12),
                Text('Giỏ hàng của bạn đang trống',
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Main content ────────────────────────────────────────────────────────

  Widget _buildCartContent(double subtotal, double total, int itemCount) {
    return Column(
      children: [
        _buildHeader(itemCount),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              ..._items.map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CartItemTile(
                    item: item,
                    onIncrement: () => _incrementQuantity(item),
                    onDecrement: () => _decrementQuantity(item),
                    onRemove: () => _removeItem(item),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildCouponField(),
              const SizedBox(height: 20),
              _buildSummary(subtotal, total),
            ],
          ),
        ),
        _buildCheckoutBar(total),
      ],
    );
  }

  Widget _buildHeader(int itemCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giỏ hàng',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$itemCount mặt hàng',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withOpacity(0.08)),
        ],
      ),
    );
  }

  Widget _buildCouponField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
            onPressed: _applyCoupon,
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
        Container(height: 1, color: Colors.white.withOpacity(0.08)),
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
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _buildCheckoutBar(double total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            // TODO: navigate to checkout flow once it exists.
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