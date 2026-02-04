import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../screens/product/product_details_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: cs.shadow.withOpacity(0.06),
        //     blurRadius: 12,
        //     offset: const Offset(0, 6),
        //   ),
        // ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => ProductDetailsScreen(product: product),
          //   ),
          // );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Favorite + Badge
            Expanded(
              child: Stack(
                children: [
                  // Product Image
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: product.image,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.image_not_supported,
                          color: cs.onSurfaceVariant,
                          size: 40,
                        ),
                      ),
                    ),
                  ),

                  // ❤️ Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: cs.outlineVariant, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.favorite_border,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                        onPressed: () {
                          // toggle favorite
                        },
                      ),
                    ),
                  ),

                  // % OFF badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.tertiary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '18% off',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    style: tt.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: cs.onSurface,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Short description
                  Text(
                    "Premium quality product",
                    style: tt.bodySmall?.copyWith(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Price + MRP
                  Row(
                    children: [
                      Text(
                        '₹${(product.price * 80).toInt()}',
                        style: tt.titleSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${(product.price * 98).toInt()}',
                        style: tt.bodySmall?.copyWith(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '(18% off)',
                    style: tt.bodySmall?.copyWith(
                      fontSize: 11,
                      color: cs.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
