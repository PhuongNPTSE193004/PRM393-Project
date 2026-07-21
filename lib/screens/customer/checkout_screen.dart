import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../services/cart_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';

/// Checkout screen with Firestore order creation and direct Momo sandbox integration.
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

  List<_CartLine> _items = [];

  double get _subtotal =>
      _items.fold(0.0, (s, i) => s + i.unitPrice * i.quantity);
  double get _shipping => _subtotal > 0 ? 50000 : 0;
  double get _total => _subtotal + _shipping;

  @override
  void initState() {
    super.initState();
    _loadProfileAndCart();
  }

  Future<void> _loadProfileAndCart() async {
    final uid = widget.uid ?? _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _nameCtrl.text = data['displayName'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
        _addressCtrl.text = data['address'] ?? '';
      }

      // 1. Load via CartService if available
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
        if (lines.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _items = lines;
            _loading = false;
          });
          return;
        }
      }

      // 2. Query users/{uid}/cart subcollection (standard repository path)
      final userCartSnap =
          await _firestore.collection('users').doc(uid).collection('cart').get();
      if (userCartSnap.docs.isNotEmpty) {
        final lines = <_CartLine>[];
        for (var doc in userCartSnap.docs) {
          final data = doc.data();
          final productSlug = data['productSlug'] as String? ?? doc.id;
          final qty = (data['quantity'] as num?)?.toInt() ?? 1;

          final prodDoc =
              await _firestore.collection('products').doc(productSlug).get();
          if (prodDoc.exists) {
            final prodData = prodDoc.data()!;
            final prod = Product(
              slug: prodData['slug'] ?? prodDoc.id,
              name: prodData['name'] ?? prodData['title'] ?? 'Unknown',
              brand: prodData['brand'],
              price: (prodData['price'] as num?)?.toDouble() ?? 0,
              rating: (prodData['rating'] as num?)?.toDouble() ?? 0,
              fps: (prodData['fps'] as num?)?.toInt(),
              stock: (prodData['stock'] as num?)?.toInt() ?? 0,
              categorySlug: prodData['categorySlug'] ?? '',
              images: List<String>.from(prodData['images'] ?? []),
            );
            lines.add(_CartLine(
              id: doc.id,
              product: prod,
              quantity: qty,
              unitPrice: prod.price,
            ));
          }
        }
        if (!mounted) return;
        setState(() {
          _items = lines;
          _loading = false;
        });
        return;
      }

      // 3. Query legacy top-level carts/{uid}
      final cartDoc = await _firestore.collection('carts').doc(uid).get();
      if (cartDoc.exists) {
        final cartData = cartDoc.data()!;
        final rawItems = (cartData['items'] as List<dynamic>?) ?? [];

        final lines = <_CartLine>[];
        for (var map in rawItems) {
          final item = map as Map<String, dynamic>;
          final prodId = item['product_id'] as String?;
          final q = (item['quantity'] as num?)?.toInt() ?? 1;

          if (prodId != null) {
            final pDoc =
                await _firestore.collection('products').doc(prodId).get();
            if (pDoc.exists) {
              final prodData = pDoc.data()!;
              final prod = Product(
                slug: prodData['slug'] ?? pDoc.id,
                name: prodData['name'] ?? prodData['title'] ?? 'Unknown',
                brand: prodData['brand'],
                price: (prodData['price'] as num?)?.toDouble() ?? 0,
                rating: (prodData['rating'] as num?)?.toDouble() ?? 0,
                fps: (prodData['fps'] as num?)?.toInt(),
                stock: (prodData['stock'] as num?)?.toInt() ?? 0,
                categorySlug: prodData['categorySlug'] ?? '',
                images: List<String>.from(prodData['images'] ?? []),
              );
              lines.add(_CartLine(
                id: pDoc.id,
                product: prod,
                quantity: q,
                unitPrice: prod.price,
              ));
            }
          }
        }
        _items = lines;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tải giỏ hàng: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Creates a MoMo Sandbox Payment URL directly using MoMo V2 Gateway API.
  Future<String> _createDirectMomoPaymentUrl(String orderId, double amount) async {
    const partnerCode = 'MOMO';
    const accessKey = 'F8BBA842ECF85';
    const secretKey = 'K951B6PE1waDMi640xX08PD3vg6EkVlz';
    const endpoint = 'https://test-payment.momo.vn/v2/gateway/api/create';

    final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
    final amountInt = amount.toInt();
    final orderInfo = 'Thanh toán đơn hàng AirsoftGear #$orderId';
    const redirectUrl = 'https://momo.vn';
    const ipnUrl = 'https://momo.vn';
    const requestType = 'captureWallet';
    const extraData = '';

    final rawSignature =
        'accessKey=$accessKey&amount=$amountInt&extraData=$extraData&ipnUrl=$ipnUrl&orderId=$orderId&orderInfo=$orderInfo&partnerCode=$partnerCode&redirectUrl=$redirectUrl&requestId=$requestId&requestType=$requestType';

    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final signature = hmac.convert(utf8.encode(rawSignature)).toString();

    final body = {
      'partnerCode': partnerCode,
      'accessKey': accessKey,
      'requestId': requestId,
      'amount': amountInt.toString(),
      'orderId': orderId,
      'orderInfo': orderInfo,
      'redirectUrl': redirectUrl,
      'ipnUrl': ipnUrl,
      'extraData': extraData,
      'requestType': requestType,
      'signature': signature,
    };

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final payUrl = json['payUrl'] as String?;
      if (payUrl != null && payUrl.isNotEmpty) {
        return payUrl;
      }
      throw Exception(json['message'] ?? 'Không lấy được link thanh toán MoMo');
    } else {
      throw Exception('Lỗi MoMo Sandbox (${response.statusCode}): ${response.body}');
    }
  }

  Future<bool> _showMomoWebPaymentModal(String orderId) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return AlertDialog(
              backgroundColor: kSurfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: kNeon.withValues(alpha: 0.3)),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA50064),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'MoMo Sandbox Gateway',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded, size: 100, color: Colors.black),
                        const SizedBox(height: 8),
                        Text(
                          'MÃ GD: #$orderId',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số tiền:', style: TextStyle(color: kMuted)),
                      Text(
                        '${formatVnd(_total)}đ',
                        style: const TextStyle(
                          color: kNeon,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cổng thanh toán thử nghiệm MoMo Sandbox cho phép bạn xác nhận hoàn tất giao dịch.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Hủy', style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNeon,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('XÁC NHẬN ĐÃ THANH TOÁN'),
                ),
              ],
            );
          },
        ) ??
        false;
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
        final demoOrderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
        bool paidSuccess = false;

        try {
          // 1. Try direct MoMo Sandbox V2 Gateway API call
          final payUrl = await _createDirectMomoPaymentUrl(demoOrderId, _total);
          final uri = Uri.parse(payUrl);
          if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            paidSuccess = true;
          }
        } catch (e) {
          // 2. Fallback for Web CORS or API fetch restrictions
          paidSuccess = await _showMomoWebPaymentModal(demoOrderId);
        }

        if (!paidSuccess) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanh toán MoMo đã bị hủy')),
          );
          setState(() => _submitting = false);
          return;
        }

        // 3. Create order record in Firestore
        await _createOrderInFirestore(uid, paid: true);
      } else {
        await _createOrderInFirestore(uid, paid: false);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đặt hàng thành công!')));
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
