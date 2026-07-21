import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../theme/app_theme.dart';

class AdminProductFormScreen extends StatefulWidget {
  final Product? product; // Null if creating new product

  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  late TextEditingController _slugCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _fpsCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _imageCtrl;
  late TextEditingController _descCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _slugCtrl = TextEditingController(text: p?.slug ?? '');
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? 'Tokyo Marui');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '5000000');
    _stockCtrl = TextEditingController(text: p != null ? p.stock.toString() : '10');
    _fpsCtrl = TextEditingController(text: p?.fps != null ? p.fps.toString() : '380');
    _categoryCtrl = TextEditingController(text: p?.categorySlug ?? 'aeg');
    _imageCtrl = TextEditingController(
      text: p != null && p.images.isNotEmpty ? p.images.first : '',
    );
    _descCtrl = TextEditingController(text: p?.description ?? '');
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _fpsCtrl.dispose();
    _categoryCtrl.dispose();
    _imageCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final slug = widget.product?.slug ??
          (_slugCtrl.text.trim().isNotEmpty
              ? _slugCtrl.text.trim()
              : _nameCtrl.text.trim().toLowerCase().replaceAll(' ', '-'));

      final data = <String, dynamic>{
        'slug': slug,
        'name': _nameCtrl.text.trim(),
        'title': _nameCtrl.text.trim(),
        'brand': _brandCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'stock': int.tryParse(_stockCtrl.text.trim()) ?? 0,
        'fps': int.tryParse(_fpsCtrl.text.trim()) ?? 350,
        'categorySlug': _categoryCtrl.text.trim().toLowerCase(),
        'images': _imageCtrl.text.trim().isNotEmpty ? [_imageCtrl.text.trim()] : [],
        'description': _descCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.product == null) {
        data['rating'] = 5.0;
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('products').doc(slug).set(data, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null ? 'Đã thêm sản phẩm mới!' : 'Đã cập nhật sản phẩm!',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu sản phẩm: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        foregroundColor: kNeon,
        title: Text(
          isEditing ? 'SỬA SẢN PHẨM' : 'THÊM SẢN PHẨM MỚI',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nameCtrl, 'Tên sản phẩm', required: true),
              const SizedBox(height: 12),
              _buildTextField(_brandCtrl, 'Thương hiệu (Brand)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_priceCtrl, 'Giá (VND)', isNumber: true, required: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_stockCtrl, 'Số lượng kho', isNumber: true, required: true)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_fpsCtrl, 'Tốc độ đạn (FPS)', isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_categoryCtrl, 'Mã danh mục (AEG/GBB/Sniper)')),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(_imageCtrl, 'URL hình ảnh (https://...)'),
              const SizedBox(height: 12),
              _buildTextField(_descCtrl, 'Mô tả chi tiết sản phẩm', maxLines: 3),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNeon,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _isSaving ? null : _saveProduct,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          isEditing ? 'CẬP NHẬT SẢN PHẨM' : 'TẠO SẢN PHẨM MỚI',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập trường này' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: kSurfaceCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
