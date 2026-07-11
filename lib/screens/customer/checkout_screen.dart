import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../services/cart_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';

/// Checkout screen with Firestore order creation and Momo sandbox integration.
///
/// This screen will call a local demo Momo server (running under
/// `tools/momo-server`) to create a payment and open the resulting `payUrl`.
/// For Android emulator the demo server base is `http://10.0.2.2:3000` by
/// default; change to your machine IP when testing on a physical device.
class CheckoutScreen extends StatefulWidget {
  final String? uid;
  final CartService? cartService;

  const CheckoutScreen({super.key, this.uid, this.cartService});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Hồ Chí Minh');
  final _notesCtrl = TextEditingController();

  String _payment = 'cod';
  bool _loading = true;
  bool _submitting = false;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // TODO: for emulator use 10.0.2.2, for web or iOS use localhost
  static const _momoBase = 'http://localhost:3000';

  List<_CartLine> _items = [];

  double get _subtotal =>
      _items.fold(0.0, (s, i) => s + i.unitPrice * i.quantity);
  double get _shipping => _subtotal > 0 ? 50000 : 0;
  double get _total => _subtotal + _shipping;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() => _loading = true);

    final uid = widget.uid ?? _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      if (widget.cartService != null) {
        final items = await widget.cartService!.getCartItems(uid);
        final lines = items
            .map(
              (ci) => _CartLine(
                id: ci.product.slug,
                product: ci.product,
                quantity: ci.quantity,
                unitPrice: ci.product.price,
              ),
            )
            .toList();
        if (!mounted) return;
        setState(() {
          _items = lines;
          _loading = false;
        });
        return;
      }

      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cart')
          .get();

      final lines = await Future.wait(
        snap.docs.map((doc) async {
          final data = doc.data();
          final productSlug = data['productSlug'] as String? ?? doc.id;
          final qty = (data['quantity'] as num?)?.toInt() ?? 1;
          final prodDoc = await _firestore
              .collection('products')
              .doc(productSlug)
              .get();
          final prodData = prodDoc.exists
              ? prodDoc.data()!
              : <String, dynamic>{};

          final product = Product(
            slug: prodData['slug'] ?? prodDoc.id,
            name: prodData['name'] ?? prodData['title'] ?? 'Unknown',
            price: (prodData['price'] as num?)?.toDouble() ?? 0,
            rating: (prodData['rating'] as num?)?.toDouble() ?? 0,
            fps: prodData['fps'],
            stock: (prodData['stock'] as num?)?.toInt() ?? 0,
            categorySlug: prodData['categorySlug'] ?? '',
            images: List<String>.from(prodData['images'] ?? []),
          );

          return _CartLine(
            id: doc.id,
            product: product,
            quantity: qty,
            unitPrice: product.price,
          );
        }),
      );

      if (!mounted) return;
      setState(() {
        _items = lines;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tải giỏ hàng: $e')));
    }
  }

  Future<void> _submitOrder() async {
    final uid = widget.uid ?? _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập trước khi đặt hàng')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Giỏ hàng trống')));
      return;
    }

    setState(() => _submitting = true);

    try {
      if (_payment == 'online') {
        final demoOrderId = DateTime.now().millisecondsSinceEpoch.toString();

        final createRes = await http.post(
          Uri.parse('$_momoBase/create_payment'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'orderId': demoOrderId,
            'amount': _total,
            'returnUrl': 'http://localhost:3000/payment/result',
          }),
        );

        if (createRes.statusCode != 200) {
          throw Exception('Không thể tạo payment: ${createRes.body}');
        }

        final payload = jsonDecode(createRes.body) as Map<String, dynamic>;
        final payUrl = payload['payUrl'] as String?;
        if (payUrl == null) throw Exception('payUrl missing from server');

        final uri = Uri.parse(payUrl);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw Exception('Không thể mở trang thanh toán');
        }

        final confirmed = await _pollPaymentStatus(demoOrderId);
        if (!confirmed) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanh toán không xác nhận')),
          );
          setState(() => _submitting = false);
          return;
        }

        await _createOrderInFirestore(uid, paid: true);
      } else {
        await _createOrderInFirestore(uid, paid: false);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đặt hàng thành công')));
      Navigator.of(context).pushReplacementNamed('/profile');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi đặt hàng: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _pollPaymentStatus(String orderId) async {
    const maxAttempts = 12;
    const delayMs = 1500;
    for (var i = 0; i < maxAttempts; i++) {
      final res = await http.get(
        Uri.parse('$_momoBase/check_payment?orderId=$orderId'),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['paid'] == true) return true;
      }
      await Future.delayed(const Duration(milliseconds: delayMs));
    }
    return false;
  }

  Future<void> _createOrderInFirestore(String uid, {required bool paid}) async {
    final orderRef = await _firestore.collection('orders').add({
      'user_id': uid,
      'total': _total,
      'status': paid ? 'paid' : 'pending',
      'shipping_name': _nameCtrl.text.trim(),
      'shipping_phone': _phoneCtrl.text.trim(),
      'shipping_address': _addressCtrl.text.trim(),
      'shipping_city': _cityCtrl.text.trim(),
      'payment_method': _payment,
      'notes': _notesCtrl.text.trim(),
      'created_at': FieldValue.serverTimestamp(),
    });

    final batch = _firestore.batch();
    for (final line in _items) {
      final oiRef = _firestore.collection('order_items').doc();
      batch.set(oiRef, {
        'order_id': orderRef.id,
        'product_id': line.product.slug,
        'product_name': line.product.name,
        'unit_price': line.unitPrice,
        'quantity': line.quantity,
      });
    }

    final cartSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();
    for (final d in cartSnap.docs) batch.delete(d.reference);

    final notifRef = _firestore.collection('notifications').doc();
    batch.set(notifRef, {
      'user_id': uid,
      'title': 'Đơn hàng đã được đặt',
      'body': 'Đơn hàng #${orderRef.id.substring(0, 8)} đang được xử lý.',
      'kind': 'order',
      'created_at': FieldValue.serverTimestamp(),
      'read': false,
    });

    await batch.commit();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        foregroundColor: kNeon,
        title: const Text(
          'Thanh toán',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Địa chỉ giao hàng',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Họ và tên'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Số điện thoại'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Địa chỉ'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cityCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Tỉnh / Thành phố'),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Phương thức thanh toán',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'Thanh toán khi nhận hàng (COD)',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: 'cod',
                    groupValue: _payment,
                    onChanged: (v) => setState(() => _payment = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'Thanh toán online',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: 'online',
                    groupValue: _payment,
                    onChanged: (v) => setState(() => _payment = v!),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Ghi chú',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Tùy chọn...'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Tóm tắt đơn hàng',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        ..._items.map(
                          (it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${it.product.name} × ${it.quantity}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatVnd(it.unitPrice * it.quantity),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(color: Colors.white12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Vận chuyển',
                              style: TextStyle(color: Colors.white54),
                            ),
                            Text(
                              formatVnd(_shipping),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng',
                              style: TextStyle(
                                color: kNeon,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              formatVnd(_total),
                              style: const TextStyle(
                                color: kNeon,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _submitting ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kNeon,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Xác nhận đặt hàng',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white54),
    filled: true,
    fillColor: Colors.black26,
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white24),
    ),
    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kNeon)),
  );
}

class _CartLine {
  final String id;
  final Product product;
  final int quantity;
  final double unitPrice;

  _CartLine({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });
}
