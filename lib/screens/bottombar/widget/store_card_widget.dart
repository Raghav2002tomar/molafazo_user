import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../services/api_service.dart';
import '../model/store_model.dart';
import '../../product/product_details_screen.dart';

class StoreCardWidget extends StatelessWidget {
  final StoreModel store;
  final VoidCallback onTap;

  const StoreCardWidget({
    super.key,
    required this.store,
    required this.onTap,
  });

  /// Parse hex color from API (e.g. "#F5F0EB" or "F5F0EB")
  /// Falls back to a palette color if null/invalid.
  Color _resolveBackgroundColor() {
    final hex = store.backgroundColor;
    if (hex != null && hex.isNotEmpty) {
      try {
        final clean = hex.replaceAll('#', '');
        return Color(int.parse('0xFF$clean'));
      } catch (_) {}
    }
    return _fallbackBg(store.id);
  }

  Color _fallbackBg(int storeId) {
    const palette = [
      Color(0xFFD6E4F0),
      Color(0xFFD5ECD4),
      Color(0xFFF7E7CE),
      Color(0xFFEDD5F3),
      Color(0xFFFFDDD2),
      Color(0xFFD2EAF5),
      Color(0xFFF2D2D2),
      Color(0xFFDFF5E1),
    ];
    return palette[storeId % palette.length];
  }

  /// Determine if background is dark so we can invert text/icon colors.
  bool _isDark(Color bg) => bg.computeLuminance() < 0.4;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hasBg = store.storeBackgroundImage != null &&
        store.storeBackgroundImage!.isNotEmpty;
    final hasProducts =
        store.products != null && store.products!.isNotEmpty;

    final bgColor = _resolveBackgroundColor();
    final isDark = _isDark(bgColor);

    // Card text/icon colors derived from background
    final cardTextColor = isDark ? Colors.white : Colors.black87;
    final cardSubColor =
    isDark ? Colors.white.withOpacity(0.7) : Colors.black54;
    final chipBg =
    isDark ? Colors.white.withOpacity(0.18) : Colors.white;
    final chipTextColor = isDark ? Colors.white : Colors.black87;
    final shopAllBg =
    isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade100;
    final arrowBg =
    isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade200;
    final arrowIconColor = isDark ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          // Use the API background color as the card background
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── TOP BANNER ────────────────────────────────────────────
            _TopBanner(
              store: store,
              hasBg: hasBg,
              bgColor: bgColor,
              isDark: isDark,
              tt: tt,
            ),

            // ── SCROLLABLE PRODUCT LIST ───────────────────────────────
            hasProducts
                ? _ScrollableProductStrip(
              products: store.products!,
              context: context,
              bgColor: bgColor,
              isDark: isDark,
            )
                : _EmptyProducts(isDark: isDark),

            // ── SHOP ALL ROW ──────────────────────────────────────────
            GestureDetector(
              onTap: onTap,
              child: Container(
                color: shopAllBg,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      "Shop all",
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: cardTextColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: arrowBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: arrowIconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _TopBanner extends StatelessWidget {
  final StoreModel store;
  final bool hasBg;
  final Color bgColor;
  final bool isDark;
  final TextTheme tt;

  const _TopBanner({
    required this.store,
    required this.hasBg,
    required this.bgColor,
    required this.isDark,
    required this.tt,
  });

  bool get hasLogo => store.logo != null && store.logo!.isNotEmpty;

  String get _bgUrl =>
      "${ApiService.ImagebaseUrl}/${ApiService.store_background_URL}${store.storeBackgroundImage}";

  String get _logoUrl =>
      "${ApiService.ImagebaseUrl}/${ApiService.store_logo_URL}${store.logo}";

  @override
  Widget build(BuildContext context) {
    // Only apply gradient if there's a background image
    final bottomGradient = hasBg
        ? LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.3, 1.0],
      colors: [
        Colors.transparent,
        isDark ? Colors.black.withOpacity(0.62) : bgColor.withOpacity(0.6),
      ],
    )
        : null;

    return Stack(
      children: [
        // ── Background ─────────────────────────────────────────────
        SizedBox(
          height: 130,
          width: double.infinity,
          child: hasBg
              ? Image.network(
            _bgUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: bgColor),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(color: Colors.grey),
              );
            },
          )
              : Container(color: bgColor),
        ),

        // ── Scrim blending into card bg (only if has background image) ────────────
        if (hasBg)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(gradient: bottomGradient!),
            ),
          ),

        // ── Logo + Name + City ─────────────────────────────────────
        Positioned(
          bottom: 10,
          left: 12,
          right: 12,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 8,
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: hasLogo
                    ? Image.network(
                  _logoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _logoFallback(store.name),
                )
                    : _logoFallback(store.name),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleSmall?.copyWith(
                        color: hasBg ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        shadows: hasBg
                            ? const [Shadow(color: Colors.black54, blurRadius: 6)]
                            : null,
                      ),
                    ),
                    if (store.city.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 11,
                            color: hasBg ? Colors.white70 : (isDark ? Colors.white70 : Colors.black54),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              store.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasBg ? Colors.white70 : (isDark ? Colors.white70 : Colors.black54),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
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
      ],
    );
  }

  Widget _logoFallback(String name) => Container(
    color: Colors.grey.shade100,
    alignment: Alignment.center,
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'S',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Colors.grey.shade600,
      ),
    ),
  );
}
// ─────────────────────────────────────────────────────────────────────────────
// SCROLLABLE PRODUCT STRIP
// ─────────────────────────────────────────────────────────────────────────────

class _ScrollableProductStrip extends StatelessWidget {
  final List<dynamic> products;
  final BuildContext context;
  final Color bgColor;
  final bool isDark;

  const _ScrollableProductStrip({
    required this.products,
    required this.context,
    required this.bgColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext ctx) {
    // Strip bg: slightly tinted version of the card background
    final stripBg = isDark
        ? Colors.black.withOpacity(0.2)
        : Colors.white.withOpacity(0.35);

    return Container(
      height: 150,
      color: stripBg,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        itemCount: products.length,
        itemBuilder: (_, i) {
          final product = products[i];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _ProductCard(
              product: product,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailScreen(productId: product.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SINGLE PRODUCT CARD IN STRIP
// ─────────────────────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;
  final bool isDark;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.isDark,
  });

  String? _imageUrl() {
    try {
      if (product.primaryImage != null &&
          product.primaryImage.image != null &&
          product.primaryImage.image.isNotEmpty) {
        return "${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${product.primaryImage.image}";
      }
      final imgs = product.images;
      if (imgs != null && (imgs as List).isNotEmpty) {
        final filename = imgs.first?.toString() ?? '';
        if (filename.isEmpty) return null;
        return "${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}$filename";
      }
    } catch (_) {}
    return null;
  }

  String _fmt(dynamic val) {
    if (val == null) return '';
    final s = val.toString();
    if (s.endsWith('.00')) return '${s.substring(0, s.length - 3)} c.';
    return '$s c.';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final imageUrl = _imageUrl();

    final price = _fmt(product.price);
    String? originalPrice;
    try {
      final before = product.priceBeforeDiscount?.toString() ?? '';
      final current = product.price?.toString() ?? '';
      if (before.isNotEmpty &&
          before != current &&
          before != '0' &&
          before != '0.00') {
        originalPrice = _fmt(before);
      }
    } catch (_) {}

    String productName = '';
    try {
      productName = product.name?.toString() ?? '';
    } catch (_) {}

    // Product card is always white for readability
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product image ─────────────────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl != null
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _fallbackImg(),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(color: Colors.grey),
                      );
                    },
                  )
                      : _fallbackImg(),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.88),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Name + Price ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (productName.isNotEmpty)
                    Text(
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: Colors.black87,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (price.isNotEmpty)
                        Text(
                          price,
                          style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: Colors.black,
                          ),
                        ),
                      if (originalPrice != null) ...[
                        const SizedBox(width: 3),
                        Text(
                          originalPrice,
                          style: tt.labelSmall?.copyWith(
                            fontSize: 9,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImg() => Container(
    color: Colors.grey.shade100,
    child: const Icon(Icons.image_not_supported,
        size: 26, color: Colors.grey),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY PRODUCTS
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyProducts extends StatelessWidget {
  final bool isDark;
  const _EmptyProducts({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      alignment: Alignment.center,
      color: isDark
          ? Colors.black.withOpacity(0.15)
          : Colors.white.withOpacity(0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 26,
              color: isDark
                  ? Colors.white.withOpacity(0.4)
                  : Colors.grey.shade400),
          const SizedBox(height: 4),
          Text(
            "No products yet",
            style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ── store type map ────────────────────────────────────────────────────────────
const storeTypeMap = {
  '1': 'Retail',
  '2': 'Online',
  '3': 'Wholesale',
  '4': 'Offline',
};