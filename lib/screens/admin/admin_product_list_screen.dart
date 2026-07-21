import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'admin_product_form_screen.dart';

class AdminProductListScreen extends StatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  State<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
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
          'QUẢN LÝ SẢN PHẨM',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kNeon,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm Sản Phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminProductFormScreen()),
          );
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: kNeon),
                filled: true,
                fillColor: kSurfaceCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kNeon));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi tải sản phẩm: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                var products = docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return Product(
                    slug: data['slug'] ?? d.id,
                    name: data['name'] ?? data['title'] ?? 'Unknown',
                    brand: data['brand'],
                    price: (data['price'] as num?)?.toDouble() ?? 0,
                    rating: (data['rating'] as num?)?.toDouble() ?? 0,
                    fps: (data['fps'] as num?)?.toInt(),
                    stock: (data['stock'] as num?)?.toInt() ?? 0,
                    categorySlug: data['categorySlug'] ?? '',
                    images: List<String>.from(data['images'] ?? []),
                  );
                }).toList();

                if (_query.isNotEmpty) {
                  products = products
                      .where((p) => p.name.toLowerCase().contains(_query) || (p.brand?.toLowerCase().contains(_query) ?? false))
                      .toList();
                }

                if (products.isEmpty) {
                  return const Center(
                    child: Text('Chưa có sản phẩm nào.', style: TextStyle(color: kMuted, fontFamily: 'monospace')),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductItem(product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kSurfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
            image: product.images.isNotEmpty
                ? DecorationImage(image: NetworkImage(product.images.first), fit: BoxFit.cover)
                : null,
          ),
          child: product.images.isEmpty ? const Icon(Icons.shield_outlined, color: kNeon) : null,
        ),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          'Giá: ${formatVnd(product.price)}đ  •  Kho: ${product.stock}',
          style: const TextStyle(color: kMuted, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminProductFormScreen(product: product),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDeleteProduct(product),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceCard,
        title: const Text('Xóa Sản Phẩm', style: TextStyle(color: Colors.white)),
        content: Text('Bạn có chắc chắn muốn xóa "${product.name}" khỏi cửa hàng không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Quay lại', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _firestore.collection('products').doc(product.slug).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa sản phẩm ${product.name}')),
      );
    }
  }
}
