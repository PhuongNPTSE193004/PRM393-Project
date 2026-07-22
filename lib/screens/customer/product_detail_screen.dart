import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/cart_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  /// Vietnamese display name for the product's category (e.g. "Súng trường"
  /// for slug "rifles"). [Product] only stores [Product.categorySlug], so
  /// the caller resolves the display name via ProductService/CategoryService
  /// before navigating here — screens must not look up category names
  /// directly from a repository.
  final String? categoryName;

  /// Related products to show at the bottom of the screen, resolved by the
  /// caller via ProductService.getRelatedProducts(...) before navigation.
  /// Defaults to an empty list so the section simply hides itself if the
  /// caller hasn't wired this up yet.
  final List<Product> relatedProducts;

  /// Business logic for cart operations. Injected by the caller so this
  /// screen never touches Firebase or repositories directly.
  final CartService cartService;

  /// Currently signed-in user's uid, used for cart operations.
  final String uid;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.cartService,
    required this.uid,
    this.categoryName,
    this.relatedProducts = const [],
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;
  bool _isFavorite = false;
  bool _isAddingToCart = false;

  static const _kThumbnailSize = 60.0;
  static const _kBottomBarHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.stock > 0 ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: kBackground,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: _kBottomBarHeight + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageCarousel(product),
                _buildInfo(product),
                _buildShippingBadges(),
                _buildDescription(product),
                _buildSpecs(product),
                _buildQuantitySelector(product),
                _buildRelatedProducts(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: _CircleIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
      actions: [
        _CircleIconButton(
          icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
          iconColor: _isFavorite ? Colors.redAccent : Colors.white,
          onTap: () => setState(() => _isFavorite = !_isFavorite),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ─── Image Carousel ─────────────────────────────────────────────────────────

  Widget _buildImageCarousel(Product product) {
    final images = product.images;

    return Column(
      children: [
        // Main image with grid background
        GestureDetector(
          onHorizontalDragEnd: (details) {
            if (images.isEmpty) return;
            if (details.primaryVelocity == null) return;
            setState(() {
              if (details.primaryVelocity! < 0) {
                _selectedImageIndex =
                    (_selectedImageIndex + 1).clamp(0, images.length - 1);
              } else {
                _selectedImageIndex =
                    (_selectedImageIndex - 1).clamp(0, images.length - 1);
              }
            });
          },
          child: _MainImageView(
            imageUrl: images.isNotEmpty ? images[_selectedImageIndex] : null,
          ),
        ),

        const SizedBox(height: 12),

        // Dot indicator
        if (images.length > 1)
          _DotIndicator(
            count: images.length,
            activeIndex: _selectedImageIndex,
          ),

        const SizedBox(height: 12),

        // Thumbnail row
        if (images.length > 1)
          _ThumbnailRow(
            images: images,
            selectedIndex: _selectedImageIndex,
            onTap: (i) => setState(() => _selectedImageIndex = i),
            thumbnailSize: _kThumbnailSize,
          ),

        const SizedBox(height: 12),
      ],
    );
  }

  // ─── Info ────────────────────────────────────────────────────────────────────

  Widget _buildInfo(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category label
          if (widget.categoryName != null)
            Text(
              widget.categoryName!.toUpperCase(),
              style: const TextStyle(
                color: kNeon,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),

          const SizedBox(height: 6),

          // Product name
          Text(
            product.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Rating + stock
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                product.rating.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Text('·', style: TextStyle(color: Colors.white54)),
              const SizedBox(width: 4),
              Text(
                product.stock > 0
                    ? 'Còn ${product.stock} sản phẩm'
                    : 'Hết hàng',
                style: TextStyle(
                  color: product.stock > 0 ? Colors.white54 : Colors.red,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Price
          if (product.discountPrice != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatVnd(product.discountPrice!)}đ',
                  style: const TextStyle(
                    color: kNeon,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${formatVnd(product.price)}đ',
                  style: const TextStyle(
                    color: kMuted,
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              '${formatVnd(product.price)}đ',
              style: const TextStyle(
                color: kNeon,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Shipping Badges ─────────────────────────────────────────────────────────

  Widget _buildShippingBadges() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _BadgeTile(
              icon: Icons.local_shipping_outlined,
              title: 'Giao hàng nhanh',
              subtitle: 'Toàn quốc 2–4 ngày',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _BadgeTile(
              icon: Icons.verified_user_outlined,
              title: 'Bảo hành 6 tháng',
              subtitle: 'Đổi trả 7 ngày',
            ),
          ),
        ],
      ),
    );
  }

  // ─── Description ─────────────────────────────────────────────────────────────

  Widget _buildDescription(Product product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Mô tả'),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ─── Technical Specs ─────────────────────────────────────────────────────────

  Widget _buildSpecs(Product product) {
    final specs = <_SpecEntry>[
      if (product.fps != null) _SpecEntry('FPS', '${product.fps}'),
      if (product.material != null) _SpecEntry('Chất liệu (Material)', product.material!),
      if (product.magazine != null) _SpecEntry('Băng đạn (Magazine)', product.magazine!),
      if (product.battery != null) _SpecEntry('Pin / Battery', product.battery!),
      if (product.fireMode != null) _SpecEntry('Chế độ bắn (Fire mode)', product.fireMode!),
      if (product.powerSource != null) _SpecEntry('Nguồn lực (Power source)', product.powerSource!),
      if (product.barrelLength != null) _SpecEntry('Chiều dài nòng (Barrel)', '${product.barrelLength} mm'),
      if (product.weight != null) _SpecEntry('Trọng lượng (Weight)', '${product.weight} kg'),
      if (product.warranty != null) _SpecEntry('Bảo hành (Warranty)', product.warranty!),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Thông số kỹ thuật'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: specs
                  .map(
                    (s) => _SpecRow(
                  label: s.label,
                  value: s.value,
                  isLast: s == specs.last,
                ),
              )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quantity Selector ───────────────────────────────────────────────────────

  Widget _buildQuantitySelector(Product product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _SectionLabel(text: 'Số lượng'),
          _QuantityControl(
            quantity: _quantity,
            maxQuantity: product.stock,
            onDecrement: () {
              if (_quantity > 1) setState(() => _quantity--);
            },
            onIncrement: () {
              if (_quantity < product.stock) setState(() => _quantity++);
            },
          ),
        ],
      ),
    );
  }

  // ─── Related Products ────────────────────────────────────────────────────────

  Widget _buildRelatedProducts() {
    if (widget.relatedProducts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Sản phẩm liên quan'),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.relatedProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _RelatedProductCard(
                product: widget.relatedProducts[i],
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        product: widget.relatedProducts[i],
                        cartService: widget.cartService,
                        uid: widget.uid,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Bar ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final bool outOfStock = widget.product.stock <= 0;

    return Container(
      height: _kBottomBarHeight,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: kBackground,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: (outOfStock || _isAddingToCart) ? null : _addToCart,
              icon: _isAddingToCart
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(outOfStock ? Icons.block : Icons.shopping_cart_outlined, size: 18),
              label: Text(outOfStock ? 'Hết hàng' : 'Thêm vào giỏ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: outOfStock ? kMuted : Colors.white,
                side: BorderSide(color: outOfStock ? Colors.white12 : Colors.white.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: (outOfStock || _isAddingToCart) ? null : _buyNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: outOfStock ? kSurfaceCard : kNeon,
                foregroundColor: outOfStock ? kMuted : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              child: Text(
                outOfStock ? 'Tạm hết hàng' : 'Mua ngay',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Cart actions ────────────────────────────────────────────────────────────

  Future<void> _addToCart() async {
    setState(() => _isAddingToCart = true);

    try {
      await widget.cartService.addToCart(
        uid: widget.uid,
        productSlug: widget.product.slug,
        quantity: _quantity,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${widget.product.name} vào giỏ hàng'),
          backgroundColor: kNeon,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể thêm vào giỏ hàng. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  Future<void> _buyNow() async {
    // "Mua ngay" funnels through the same cart-add flow for now, since
    // there is no OrderService/checkout flow yet. Once one exists, this
    // should navigate straight to checkout with this single item instead.
    await _addToCart();
    // TODO: navigate to checkout screen once OrderService exists.
  }

}
// ═══════════════════════════════════════════════════════════════════════════════

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 18),
      ),
    );
  }
}

class _MainImageView extends StatelessWidget {
  final String? imageUrl;

  const _MainImageView({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Grid background
          CustomPaint(painter: _GridPainter()),
          // Image
          if (imageUrl != null)
            Image.network(imageUrl!, fit: BoxFit.contain)
          else
            const Icon(Icons.image_not_supported,
                size: 80, color: Colors.white12),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _DotIndicator({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? kNeon : Colors.white24,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _ThumbnailRow extends StatelessWidget {
  final List<String> images;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final double thumbnailSize;

  const _ThumbnailRow({
    required this.images,
    required this.selectedIndex,
    required this.onTap,
    required this.thumbnailSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: thumbnailSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: thumbnailSize,
              height: thumbnailSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? kNeon : Colors.white12,
                  width: isSelected ? 2 : 1,
                ),
                color: Colors.white.withOpacity(0.05),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.network(images[i], fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BadgeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: kNeon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _SpecRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityControl({
    required this.quantity,
    required this.maxQuantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove,
            onTap: quantity > 1 ? onDecrement : null,
          ),
          SizedBox(
            width: 32,
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add,
            onTap: quantity < maxQuantity ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? Colors.white : Colors.white24,
        ),
      ),
    );
  }
}

class _RelatedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _RelatedProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stock <= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 70,
                    width: double.infinity,
                    child: product.images.isNotEmpty
                        ? Image.network(product.images.first, fit: BoxFit.cover)
                        : const Icon(Icons.image_outlined,
                        color: Colors.white12, size: 32),
                  ),
                ),
                if (isOutOfStock)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SẮP HẾT',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              '${formatVnd(product.price)}đ',
              style: const TextStyle(
                color: kNeon,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data helpers ────────────────────────────────────────────────────────────

class _SpecEntry {
  final String label;
  final String value;

  const _SpecEntry(this.label, this.value);
}