import 'package:airsoft_shop/screens/customer/product_detail_screen.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../widgets/product_card.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';

import '../../services/product_service.dart';
import '../../services/notification_service.dart';
import '../../services/category_service.dart';
import '../../repositories/firebase/firestore_product_repository.dart';
import '../../repositories/firebase/firestore_cart_repository.dart';
import '../../repositories/firebase/firestore_notification_repository.dart';
import '../../repositories/firebase/firestore_category_repository.dart';
import 'about_screen.dart';

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
  late final NotificationService _notificationService;
  late final CategoryService _categoryService;
  int _cartItemCount = 0;

  String? get _uid => _authService.currentUserId;

  @override
  void initState() {
    super.initState();

    _authService = AuthService();
    final productRepository = FirestoreProductRepository();
    _service = ProductService(productRepository);
    _cartService = CartService(FirestoreCartRepository(productRepository));
    _notificationService = NotificationService(
      FirestoreNotificationRepository(),
    );
    _categoryService = CategoryService(FirestoreCategoryRepository());

    _loadProducts();
    _loadCategories();
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

  List<Category> _categories = [];
  List<Product> _allProducts = [];

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();
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
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trang bị Airsoft...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: kNeon, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: kSurfaceCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kNeon, width: 1.5),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Categories Horizontal Chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('Tất cả', null),
                ..._categories.map((c) => _buildCategoryChip(c.name, c.id)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Filter Panel (Price Slider & Stock Checkbox)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: kSurfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'KHOẢNG GIÁ TỐI ĐA',
                      style: TextStyle(
                        color: kMuted,
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kNeon.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(_maxPrice / 1000000).toStringAsFixed(1)}M ₫',
                        style: const TextStyle(
                          color: kNeon,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: _maxPrice,
                    min: 500000,
                    max: 20000000,
                    divisions: 39,
                    activeColor: kNeon,
                    inactiveColor: Colors.white12,
                    onChanged: (v) => setState(() => _maxPrice = v),
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _inStockOnly,
                        activeColor: kNeon,
                        checkColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (v) =>
                            setState(() => _inStockOnly = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Chỉ hiển thị sản phẩm còn sẵn hàng',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Grid View Catalog
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: kNeon),
                  )
                : products.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy sản phẩm phù hợp',
                      style: TextStyle(color: Colors.white54, fontFamily: 'monospace'),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.70,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: kNeon,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        onPressed: () {
          final uid = _uid;
          final email = _authService.currentUserEmail;
          if (uid == null || email == null) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomerChatScreen(uid: uid, email: email),
            ),
          );
        },
        child: const Icon(Icons.chat_bubble_outline),
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: _notificationService.getUnreadCount(_uid ?? ''),
        builder: (context, notifSnapshot) {
          final notifCount = notifSnapshot.data ?? 0;
          return Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: 0,
              backgroundColor: kSurface,
              selectedItemColor: kNeon,
              unselectedItemColor: Colors.white54,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
              ),
              onTap: (index) async {
                final uid = _uid;

                if (index == 1) {
                  // Notifications
                  if (uid == null) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotificationsScreen(
                        uid: uid,
                        service: _notificationService,
                      ),
                    ),
                  );
                } else if (index == 2) {
                  // Cart
                  if (uid == null) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CartScreen(
                        uid: uid,
                        cartService: _cartService,
                      ),
                    ),
                  );
                  if (mounted) _loadCartCount();
                } else if (index == 3) {
                  // Location / About
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                } else if (index == 4) {
                  // Profile
                  if (uid == null) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CustomerProfileScreen(),
                    ),
                  );
                }
              },
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.storefront),
                  label: 'Cửa hàng',
                ),
                BottomNavigationBarItem(
                  icon: _BottomBarIconWithBadge(
                    icon: Icons.notifications_outlined,
                    count: notifCount,
                    badgeColor: Colors.redAccent,
                    badgeTextColor: Colors.white,
                  ),
                  label: 'Thông báo',
                ),
                BottomNavigationBarItem(
                  icon: _BottomBarIconWithBadge(
                    icon: Icons.shopping_cart_outlined,
                    count: _cartItemCount,
                  ),
                  label: 'Giỏ hàng',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.location_on_outlined),
                  label: 'Vị trí',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Tài khoản',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? slug) {
    final isSelected = _selectedCategory == slug;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = slug),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? kNeon : kSurfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kNeon : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kNeon.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
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

  Future<void> _loadCategories() async {
    final categories = await _categoryService.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
    });
  }
}

class _BottomBarIconWithBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color badgeColor;
  final Color badgeTextColor;

  const _BottomBarIconWithBadge({
    required this.icon,
    required this.count,
    this.badgeColor = kNeon,
    this.badgeTextColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
