
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/cart_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../cart/controller/cart_services.dart';
import '../../product/product_details_screen.dart';
import '../model/product_model.dart';

class ProductCardWidget extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onFavourite;
  final VoidCallback? onStoreTap;

  const ProductCardWidget({
    super.key,
    required this.product,
    this.onTap,
    this.onFavourite,
    this.onStoreTap,
  });

  @override
  State<ProductCardWidget> createState() => _ProductCardWidgetState();
}

class _ProductCardWidgetState extends State<ProductCardWidget> {
  late bool isFav;
  int quantity = 1;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    isFav = widget.product.isFavorite ?? false;
  }

  /// Show variant selection bottom sheet
  Future<void> _showVariantBottomSheet() async {
    final product = widget.product;
    final hasVariants =
        product.combinations != null && product.combinations!.isNotEmpty;

    if (!hasVariants) {
      // If no variants, add to cart directly
      await addToCart(product.id, null);
      return;
    }

    // Show bottom sheet with variants
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => VariantSelectionBottomSheet(
        product: product,
        onAddToCart: (combinationId, quantity) async {
          Navigator.pop(context, {
            'combinationId': combinationId,
            'quantity': quantity,
          });
        },
      ),
    );

    if (result != null && mounted) {
      await addToCart(
        product.id,
        result['combinationId'],
        quantity: result['quantity'] ?? 1,
      );
    }
  }

  /// Add to cart with selected combination
  Future<void> addToCart(
    int productId,
    int? combinationId, {
    int quantity = 1,
  }) async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please login first")));
      }
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final res = await CartService.addToCart(
        productId: productId,
        quantity: quantity,
        combinationId: combinationId,
      );

      if (res["status"] == true) {
        if (mounted) {
          context.read<CartProvider>().refreshCart();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Added to cart"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (res['requiresLogin'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Please login first")));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res['message'] ?? "Failed to add to cart"),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cart error")));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cartProvider = context.watch<CartProvider>();
    int cartQty = cartProvider.getQuantity(product.id);
    bool isInCart = cartQty > 0;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final bool hasDiscount = product.hasDiscount;
    final double price = double.tryParse(product.price) ?? 0;
    final double discount =
        double.tryParse(product.discountPrice ?? product.price) ?? price;
    final int discountPercent = (((price - discount) / price) * 100).round();
    final bool isOutOfStock = product.availableQuantity <= 0;

    String formatPrice(num price) {
      if (price % 1 == 0) {
        return price.toInt().toString();
      } else {
        return price.toStringAsFixed(2);
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: Image.network(
                      "${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${product.image}",
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "-${discountPercent.abs()}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () async {
                        final token = await AuthStorage.getToken();
                        if (token == null || token.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please login first")),
                          );
                          return;
                        }
                        final res = await ApiService.post(
                          endpoint: "/customer/product/favorite/toggle",
                          token: token,
                          body: {"product_id": widget.product.id.toString()},
                        );
                        if (res["success"] == true) {
                          setState(() {
                            isFav = !isFav;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFav ? Colors.red : Colors.grey,
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
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        final rating = product.reviewsAvgRating ?? 0;
                        return Icon(
                          index < rating.floor()
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: Colors.amber,
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        "(${(product.reviewsAvgRating ?? 0).toStringAsFixed(1)})",
                        style: tt.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        "${formatPrice(double.parse((product.discountPrice ?? product.price).toString()))} c.",
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (hasDiscount)
                        Text(
                          formatPrice(double.parse(product.price.toString())),
                          style: tt.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: cs.onSurface.withOpacity(.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: isOutOfStock
                        ? Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Out of Stock",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          )
                        : isInCart
                        ? quantityController(cs, cartQty, product.id)
                        : ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : _showVariantBottomSheet,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Add to Cart",
                                    style: TextStyle(fontSize: 12),
                                  ),
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

  /// Quantity Controller Widget
  Widget quantityController(ColorScheme cs, int cartQty, int productId) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () async {
              final cartProvider = context.read<CartProvider>();
              final cartId = cartProvider.getCartItemId(productId);
              if (cartId == null) return;
              int newQty = cartQty - 1;
              if (newQty < 1) return;
              final res = await CartService.updateCartItem(
                cartItemId: cartId,
                quantity: newQty,
              );
              if (res["status"] == true) {
                cartProvider.refreshCart();
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.remove, size: 16),
            ),
          ),
          Text(
            cartQty.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          InkWell(
            onTap: () async {
              final cartProvider = context.read<CartProvider>();
              final cartId = cartProvider.getCartItemId(productId);
              if (cartId == null) return;
              int newQty = cartQty + 1;
              final res = await CartService.updateCartItem(
                cartItemId: cartId,
                quantity: newQty,
              );
              if (res["status"] == true) {
                cartProvider.refreshCart();
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.add, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Variant Selection Bottom Sheet with Half-Screen to Full-Screen Scrolling
class VariantSelectionBottomSheet extends StatefulWidget {
  final ProductModel product;
  final Function(int? combinationId, int quantity) onAddToCart;

  const VariantSelectionBottomSheet({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<VariantSelectionBottomSheet> createState() =>
      _VariantSelectionBottomSheetState();
}

class _VariantSelectionBottomSheetState
    extends State<VariantSelectionBottomSheet> {
  int quantity = 1;
  ProductCombination? selectedCombination;
  Map<String, String> selectedAttributes = {};
  int? selectedImageIndex = 0;
  List<String> currentImages = [];
  PageController? _pageController;
  final DraggableScrollableController _scrollController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _initializeCombinations();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeCombinations() {
    final combinations = widget.product.combinations;
    if (combinations != null && combinations.isNotEmpty) {
      selectedCombination = combinations.first;
      _initializeSelectedAttributes(combinations.first);
      _updateCurrentImages(combinations.first);
    }
  }

  void _initializeSelectedAttributes(ProductCombination combination) {
    selectedAttributes.clear();
    combination.combination.forEach((key, value) {
      selectedAttributes[key] = value.toString();
    });
  }

  void _updateCurrentImages(ProductCombination combination) {
    currentImages = combination.images;
    selectedImageIndex = 0;
    _pageController?.jumpToPage(0);
  }

  void _updateSelectedCombination() {
    final combinations = widget.product.combinations;
    if (combinations == null) return;

    final matchingCombo = combinations.firstWhere((combo) {
      bool matches = true;
      for (var entry in selectedAttributes.entries) {
        if (combo.combination[entry.key]?.toString() != entry.value) {
          matches = false;
          break;
        }
      }
      return matches;
    }, orElse: () => combinations.first);

    setState(() {
      selectedCombination = matchingCombo;
      _updateCurrentImages(matchingCombo);
      quantity = 1; // Reset quantity when variant changes
    });
  }

  List<String> _getAttributeOptions(String attributeName) {
    final combinations = widget.product.combinations;
    if (combinations == null) return [];

    final options = <String>{};
    for (var combo in combinations) {
      final value = combo.combination[attributeName]?.toString();
      if (value != null) {
        options.add(value);
      }
    }
    return options.toList();
  }

  String get displayPrice {
    if (selectedCombination != null) {
      final price = double.tryParse(selectedCombination!.price) ?? 0;
      return price.toStringAsFixed(0);
    }
    final price = double.tryParse(widget.product.price) ?? 0;
    return price.toStringAsFixed(0);
  }

  double get totalPrice {
    final price = double.tryParse(displayPrice) ?? 0;
    return price * quantity;
  }

  @override
  Widget build(BuildContext context) {
    final hasVariants =
        widget.product.combinations != null &&
        widget.product.combinations!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      controller: _scrollController,
      initialChildSize: 0.65, // Start at 65% of screen
      minChildSize: 0.5, // Minimum 50%
      maxChildSize: 0.95, // Maximum 95%
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Choose Options",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Select your preferred variant",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20),
                        color: Colors.grey.shade600,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Product Image Section
                    SliverToBoxAdapter(child: _buildImageSection(isDark)),

                    // Product Info Card
                    SliverToBoxAdapter(child: _buildProductInfoCard(isDark)),

                    // Variant Selectors
                    if (hasVariants && widget.product.combinations != null)
                      SliverToBoxAdapter(child: _buildVariantSelectors(isDark)),

                    // Quantity Selector
                    SliverToBoxAdapter(child: _buildQuantitySelector(isDark)),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
              ),

              // Fixed Bottom Button
              _buildBottomButton(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSection(bool isDark) {
    if (currentImages.isEmpty) return const SizedBox.shrink();

    return Container(
      height: MediaQuery.of(context).size.height * 0.38,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Stack(
        children: [
          // Main Image with PageView
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  selectedImageIndex = index;
                });
              },
              itemCount: currentImages.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 3.0,
                  child: Image.network(
                    "${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${currentImages[index]}",
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                );
              },
            ),
          ),

          // Navigation Arrows
          if (currentImages.length > 1) ...[
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (selectedImageIndex! > 0) {
                      _pageController?.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      size: 24,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (selectedImageIndex! < currentImages.length - 1) {
                      _pageController?.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      size: 24,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Image Counter
          if (currentImages.length > 1)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${(selectedImageIndex ?? 0) + 1}/${currentImages.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductInfoCard(bool isDark) {
    final hasDiscount = widget.product.hasDiscount;
    final originalPrice = double.tryParse(widget.product.price) ?? 0;
    final discountedPrice = double.tryParse(displayPrice) ?? 0;
    // final discountPercent = hasDiscount
    //     ? ((originalPrice - discountedPrice) / originalPrice * 100).round()
    //     : 0;
    final int discountPercent =hasDiscount? (((originalPrice - discountedPrice) / originalPrice) * 100).round(): 0;


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.grey[50]!,
            isDark ? Colors.grey[900]! : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$displayPrice c.",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(width: 12),
                Text(
                  "${double.parse(widget.product.price).toInt()} c.",
                  style: TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade500,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "-${discountPercent.abs()}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color:
                      selectedCombination != null &&
                          selectedCombination!.stock > 0
                      ? Colors.green
                      : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                selectedCombination != null && selectedCombination!.stock > 0
                    ? "In Stock • ${selectedCombination!.stock} units available"
                    : "Out of Stock",
                style: TextStyle(
                  fontSize: 13,
                  color:
                      selectedCombination != null &&
                          selectedCombination!.stock > 0
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSelectors(bool isDark) {
    final attributes = widget.product.combinations!.first.combination.keys
        .toSet();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: attributes.map((attributeName) {
          final options = _getAttributeOptions(attributeName);
          final currentValue = selectedAttributes[attributeName];

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      attributeName.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: options.map((value) {
                    final isSelected = currentValue == value;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedAttributes[attributeName] = value;
                          _updateSelectedCombination();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          value,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuantitySelector(bool isDark) {
    final maxStock = selectedCombination?.stock ?? 0;
    final canIncrease = quantity < maxStock;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Quantity",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: quantity > 1 ? () => setState(() => quantity--) : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: quantity > 1 ? Colors.black : Colors.grey.shade100,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(40),
                      ),
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 20,
                      color: quantity > 1 ? Colors.white : Colors.grey.shade400,
                    ),
                  ),
                ),
                Container(
                  width: 55,
                  alignment: Alignment.center,
                  child: Text(
                    quantity.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: canIncrease ? () => setState(() => quantity++) : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: canIncrease ? Colors.black : Colors.grey.shade100,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(40),
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 20,
                      color: canIncrease ? Colors.white : Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(bool isDark) {
    final isOutOfStock =
        selectedCombination != null && selectedCombination!.stock <= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isOutOfStock
                ? null
                : () {
                    widget.onAddToCart(selectedCombination?.id, quantity);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isOutOfStock
                  ? Colors.grey.shade400
                  : Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOutOfStock
                      ? Icons.shopping_cart_outlined
                      : Icons.shopping_cart_outlined,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  isOutOfStock
                      ? "Out of Stock"
                      : "Add to Cart • ${totalPrice.toStringAsFixed(0)} c.",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
