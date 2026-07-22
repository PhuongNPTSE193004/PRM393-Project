import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool outOfStock = product.stock <= 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: kSurfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Container
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (product.images.isNotEmpty)
                      Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.white10,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white30,
                            size: 40,
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.white10,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(kNeon),
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.white10,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white30,
                          size: 40,
                        ),
                      ),
                    
                    // Dark Gradient Overlay at Bottom of Image
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Badges (FPS & Stock & Discount)
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (product.fps != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: kNeon,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${product.fps} FPS',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          
                          Row(
                            children: [
                              if (product.discountPrice != null && !outOfStock)
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'GIẢM GIÁ',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              if (outOfStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.redAccent),
                                  ),
                                  child: const Text(
                                    'HẾT HÀNG',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Product Info Block
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand != null && product.brand!.isNotEmpty) ...[
                      Text(
                        product.brand!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          color: kMuted,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.discountPrice != null) ...[
                                Text(
                                  '${(product.price / 1000000).toStringAsFixed(1)}M ₫',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                    color: kMuted,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${(product.discountPrice! / 1000000).toStringAsFixed(1)}M ₫',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: kNeon,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  '${(product.price / 1000000).toStringAsFixed(1)}M ₫',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: kNeon,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
