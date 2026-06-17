import 'package:airsoft_shop/screens/customer/product_detail_screen.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import 'cart_screen.dart';

import '../../services/product_service.dart';
import '../../repositories/firebase/firestore_product_repository.dart';
import '../../repositories/firebase/firestore_cart_repository.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  double _maxPrice = 20000000;
  bool _inStockOnly = false;
  bool _loading = true;
  late final ProductService _service;
  late final CartService _cartService;
  late final AuthService _authService;
  int _cartItemCount = 0;

  String? get _uid => _authService.currentUserId;

  @override
  void initState() {
    super.initState();

    _authService = AuthService();
    final productRepository = FirestoreProductRepository();
    _service = ProductService(productRepository);
    _cartService = CartService(FirestoreCartRepository(productRepository));

    _loadProducts();
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    final uid = _uid;
    if (uid == null) return;

    final items = await _cartService.getCartItems(uid);
    if (!mounted) return;
    setState(() {
      _cartItemCount = _cartService.calculateItemCount(items);
    });
  }

  // Mock Categories (equivalent to useQuery for categories)
  final List<Category> _categories = [
    Category(slug: 'aeg', nameVi: 'Súng Trường AEG'),
    Category(slug: 'gbb', nameVi: 'Súng Lục GBB'),
    Category(slug: 'sniper', nameVi: 'Súng Ngắm'),
    Category(slug: 'gear', nameVi: 'Trang Bị'),
  ];

  // Mock Products (equivalent to useQuery for products)
  List<Product> _allProducts = [
    Product(
      slug: 'm4a1',
      name: 'M4A1 Carbine',
      price: 4500000,
      rating: 4.5,
      fps: 400,
      stock: 5,
      categorySlug: 'aeg',
    ),
    Product(
      slug: 'glock19',
      name: 'Glock 19 Gen 4',
      price: 2500000,
      rating: 4.8,
      fps: 300,
      stock: 12,
      categorySlug: 'gbb',
    ),
    Product(
      slug: 'vsr10',
      name: 'VSR-10 Pro Sniper',
      price: 6000000,
      rating: 4.9,
      fps: 500,
      stock: 0,
      categorySlug: 'sniper',
    ),
    Product(
      slug: 'vest',
      name: 'Tactical Vest JPC',
      price: 1200000,
      rating: 4.2,
      fps: null,
      stock: 20,
      categorySlug: 'gear',
    ),
  ];

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  // Filter Logic
  List<Product> get _filteredProducts {
    return _allProducts.where((p) {
      if (_selectedCategory != null && p.categorySlug != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !p.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (p.price > _maxPrice) return false;
      if (_inStockOnly && p.stock <= 0) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        foregroundColor: kNeon,
        title: const Text(
          'CỬA HÀNG',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () async {
                  final uid = _uid;
                  if (uid == null) return;

                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CartScreen(
                        uid: uid,
                        cartService: _cartService,
                      ),
                    ),
                  );
                  if (!mounted) return;
                  _loadCartCount();
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: kNeon,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _cartItemCount > 9 ? '9+' : '$_cartItemCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Tìm trang bị...',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.black26,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: kNeon),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Categories
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('Tất cả', null),
                ..._categories.map((c) => _buildCategoryChip(c.nameVi, c.slug)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Filters (Price Slider & Checkbox)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GIÁ TỐI ĐA',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '${(_maxPrice / 1000000).toStringAsFixed(1)}M ₫',
                      style: const TextStyle(
                        color: kNeon,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _maxPrice,
                  min: 500000,
                  max: 20000000,
                  divisions: 39,
                  activeColor: kNeon,
                  onChanged: (v) => setState(() => _maxPrice = v),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _inStockOnly,
                      activeColor: kNeon,
                      checkColor: Colors.black,
                      onChanged: (v) =>
                          setState(() => _inStockOnly = v ?? false),
                    ),
                    const Text(
                      'Chỉ hàng còn sẵn',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Grid View
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                ? const Center(
              child: Text(
                'No matches found',
                style: TextStyle(color: Colors.white54),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75, // Adjust card proportion here
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: products[index],
                  onTap: () async {
                    final uid = _uid;
                    if (uid == null) return;

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(
                          product: products[index],
                          cartService: _cartService,
                          uid: uid,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    _loadCartCount();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? slug) {
    final isSelected = _selectedCategory == slug;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = slug),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kNeon : Colors.transparent,
          border: Border.all(color: isSelected ? kNeon : Colors.white24),
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadProducts() async {
    final products = await _service.getProducts();

    debugPrint('Products count: ${products.length}');

    setState(() {
      _allProducts = products;
      _loading = false;
    });
  }
}