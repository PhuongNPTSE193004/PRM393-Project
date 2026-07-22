import 'package:airsoft_shop/screens/customer/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event.dart';
import '../../blocs/notification/notification_state.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../widgets/product_card.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';

import '../../services/category_service.dart';
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
  String? _selectedBrand;
  bool _promoOnly = false;
  double _maxPrice = 20000000;
  bool _inStockOnly = false;
  late final CategoryService _categoryService;

  @override
  void initState() {
    super.initState();
    _categoryService = CategoryService(FirestoreCategoryRepository());

    context.read<ProductBloc>().add(ProductLoadRequested());
    _loadCategories();

    final uid = context.read<AuthBloc>().state.userId;
    if (uid != null) {
      context.read<CartBloc>().add(CartLoadRequested(uid));
      context.read<NotificationBloc>().add(NotificationSubscriptionRequested(uid));
    }
  }

  List<Category> _categories = [];

  Future<void> _logout(BuildContext context) async {
    context.read<AuthBloc>().add(AuthLogoutRequested());
  }

  // Filter Logic
  List<Product> _getFilteredProducts(List<Product> allProducts) {
    return allProducts.where((p) {
      if (_selectedCategory != null && p.categorySlug != _selectedCategory) {
        return false;
      }
      if (_selectedBrand != null && p.brand != _selectedBrand) {
        return false;
      }
      if (_promoOnly && p.discountPrice == null) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !p.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      final currentPrice = p.discountPrice ?? p.price;
      if (currentPrice > _maxPrice) return false;
      
      if (_inStockOnly && p.stock <= 0) return false;
      return true;
    }).toList();
  }

  List<String> _getBrands(List<Product> allProducts) {
    final list = allProducts.map((p) => p.brand).whereType<String>().toSet().toList();
    list.sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final products = _getFilteredProducts(state.products);
        final brands = _getBrands(state.products);

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

              // Filter Panel
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          'HÃNG SẢN XUẤT',
                          style: TextStyle(
                            color: kMuted,
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        DropdownButton<String?>(
                          value: _selectedBrand,
                          dropdownColor: kSurfaceCard,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: kNeon, size: 18),
                          style: const TextStyle(
                            color: kNeon,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                          hint: const Text('Tất cả hãng', style: TextStyle(color: Colors.white60, fontSize: 11)),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tất cả hãng'),
                            ),
                            ...brands.map((b) => DropdownMenuItem<String?>(
                                  value: b,
                                  child: Text(b),
                                )),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedBrand = val);
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 16),
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
                              'Còn hàng',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _promoOnly,
                                activeColor: kNeon,
                                checkColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (v) =>
                                    setState(() => _promoOnly = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Khuyến mãi',
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
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Grid View Catalog
              Expanded(
                child: state.status == ProductStatus.loading
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
                              final uid = context.read<AuthBloc>().state.userId;
                              if (uid == null) return;

                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(
                                    product: products[index],
                                    uid: uid,
                                  ),
                                ),
                              );
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
              final uid = context.read<AuthBloc>().state.userId;
              final email = AuthService().currentUserEmail;
              if (uid == null || email == null) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomerChatScreen(uid: uid, email: email),
                ),
              );
            },
            child: const Icon(Icons.chat_bubble_outline),
          ),
          bottomNavigationBar: MultiBlocListener(
            listeners: [
              BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state.status == AuthStatus.unauthenticated) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
            child: BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, notifState) {
                return BlocBuilder<CartBloc, CartState>(
                  builder: (context, cartState) {
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
                          final uid = context.read<AuthBloc>().state.userId;

                          if (index == 1) {
                            if (uid == null) return;
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => NotificationsScreen(
                                  uid: uid,
                                ),
                              ),
                            );
                          } else if (index == 2) {
                            if (uid == null) return;
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CartScreen(
                                  uid: uid,
                                ),
                              ),
                            );
                          } else if (index == 3) {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AboutScreen()),
                            );
                          } else if (index == 4) {
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
                              count: notifState.unreadCount,
                              badgeColor: Colors.redAccent,
                              badgeTextColor: Colors.white,
                            ),
                            label: 'Thông báo',
                          ),
                          BottomNavigationBarItem(
                            icon: _BottomBarIconWithBadge(
                              icon: Icons.shopping_cart_outlined,
                              count: cartState.itemCount,
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
                );
              },
            ),
          ),
        );
      },
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
