import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../bottombar/model/product_model.dart';
import '../product/product_details_screen.dart';
import 'controller/product_search_api.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final _api = ProductSearchApi();
  final _controller = TextEditingController();

  List<ProductModel> results = [];
  bool isLoading = false;
  Timer? _debounce;
  String? selectedPrice;
  final Set<String> selectedDelivery = {};

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() => results.clear());
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => isLoading = true);
      try {
        results = await _api.searchProducts(query);
      } catch (_) {
        results = [];
      }
      setState(() => isLoading = false);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        leading: const BackButton(),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _SearchField(
            controller: _controller,
            onChanged: _onSearchChanged,
            onFilterTap: () {
              _showFilterSheet(context); // ✅ Show the bottom sheet

            },
          ),
        ),
      ),


      body: Builder(
        builder: (_) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.text.isNotEmpty && results.isEmpty) {
            return _EmptySearchView(onFilterTap: () {
              _showFilterSheet(context);
            });
          }

          if (results.isEmpty) {
            return _InitialSearchView();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: results.length,
            itemBuilder: (_, i) =>
                _ProductCardCompact(product: results[i]),
          );
        },
      ),
    );
  }

  // ================= FILTER BOTTOM SHEET =================

  void _showFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterBottomSheet(
        initialPrice: selectedPrice,
        initialDelivery: selectedDelivery,
      ),
    );

    if (result != null) {
      setState(() {
        selectedPrice = result.price;
        selectedDelivery
          ..clear()
          ..addAll(result.delivery as Iterable<String>);
      });

      // 🔥 Call API again with filters if needed
      // _api.searchProducts(_controller.text, filters: result);
    }
  }
}

class _FilterResult {
  final String? price;
  final Set<String>? delivery;

  _FilterResult({this.price,  this.delivery});
}

/// ================= SEARCH FIELD =================
class _FilterBottomSheet extends StatefulWidget {
  final String? initialPrice;
  final Set<String> initialDelivery;

  const _FilterBottomSheet({
    this.initialPrice,
    required this.initialDelivery,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? price;
  late Set<String> delivery;

  @override
  void initState() {
    super.initState();
    price = widget.initialPrice;
    delivery = {...widget.initialDelivery};
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          /// HEADER
          Row(
            children: [
              Text("Filters",
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    price = null;
                    delivery.clear();
                  });
                },
                child: const Text("Clear",),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// PRICE
          Text("Price Range", style: tt.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _SelectableChip(
                label: "Under ₹500",
                selected: price == "under_500",
                onTap: () => setState(() => price = "under_500"),
              ),
              _SelectableChip(
                label: "₹500 - ₹1000",
                selected: price == "500_1000",
                onTap: () => setState(() => price = "500_1000"),
              ),
              _SelectableChip(
                label: "Above ₹1000",
                selected: price == "above_1000",
                onTap: () => setState(() => price = "above_1000"),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// DELIVERY
          Text("Delivery", style: tt.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _SelectableChip(
                label: "Fast Delivery",
                selected: delivery.contains("fast"),
                onTap: () {
                  setState(() {
                    delivery.contains("fast")
                        ? delivery.remove("fast")
                        : delivery.add("fast");
                  });
                },
              ),
              _SelectableChip(
                label: "Free Delivery",
                selected: delivery.contains("free"),
                onTap: () {
                  setState(() {
                    delivery.contains("free")
                        ? delivery.remove("free")
                        : delivery.add("free");
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          /// APPLY
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _FilterResult(price: price, delivery: delivery),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Black background
                foregroundColor: Colors.white, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Optional: rounded corners
                ),
              ),
              child: const Text("Apply Filters"),
            ),
          ),

          SizedBox(height: 40,)
        ],
      ),
    );
  }
}
class _SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ChoiceChip(
      label: Text(
        label,
        style: tt.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: selected ? Colors.white : cs.onSurfaceVariant, // White text on black
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.black, // Black background when selected
      backgroundColor: cs.surfaceVariant, // Default background
      surfaceTintColor: Colors.transparent,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? Colors.black : cs.outlineVariant, // Outline matches selected state
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        /// 🔍 SEARCH CARD
        Expanded(
          child: Material(
            elevation: 2,

            shadowColor: Colors.black.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            color: cs.surfaceContainerHighest,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: cs.outlineVariant.withOpacity(0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: cs.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 10),

                  /// TEXT FIELD
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.search,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search products or brands",
                        hintStyle: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                        ),

                        // 🔥 Remove ALL borders
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,

                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),


                  /// ❌ CLEAR (animated)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: controller.text.isNotEmpty
                        ? InkWell(
                      key: const ValueKey('clear'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        controller.clear();
                        onChanged('');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                        : const SizedBox(key: ValueKey('empty')),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        /// ⚙️ FILTER BUTTON (Premium)
        Material(
          elevation: 3,
          shadowColor: cs.primary.withOpacity(0.35),
          color: Colors.black, // Background set to black
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onFilterTap,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              height: 48,
              width: 48,
              child: Icon(
                Icons.tune_rounded,
                color: Colors.white, // Icon remains visible on black
                size: 22,
              ),
            ),
          ),
        ),

      ],
    );
  }
}

/// ================= EMPTY STATES =================

class _InitialSearchView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            "Search for products",
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            "Find products, brands and categories",
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchView extends StatelessWidget {
  final VoidCallback onFilterTap;
  const _EmptySearchView({required this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80,
                color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              "No products found",
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "Try different keywords or apply filters",
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onFilterTap,
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
              label: const Text(
                "Apply Filters",
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.black, // Set background to black
                side: const BorderSide(color: Colors.white), // Outline color
              ),
            ),


          ],
        ),
      ),
    );
  }
}

/// ================= FILTER CHIP =================

class _FilterChip extends StatefulWidget {
  final String label;

  const _FilterChip({required this.label, super.key});

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ChoiceChip(
      label: Text(
        widget.label,
        style: tt.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: _selected
              ? cs.onPrimary
              : cs.onSurfaceVariant,
        ),
      ),
      selected: _selected,
      onSelected: (value) {
        setState(() => _selected = value);
      },

      // 🎨 Theme-based colors
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceVariant,
      surfaceTintColor: Colors.transparent,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _selected ? cs.primary : cs.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      showCheckmark: false,
    );
  }
}

/// ================= PRODUCT CARD (UNCHANGED, PERFECT) =================

class _ProductCardCompact extends StatelessWidget {
  final ProductModel product;
  const _ProductCardCompact({required this.product});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final hasDiscount =
        product.discountPrice != null &&
            product.discountPrice != product.price;

    final outOfStock = product.availableQuantity <= 0;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      "${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${product.image}",
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  if (outOfStock)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.45),
                        alignment: Alignment.center,
                        child: const Text(
                          "OUT OF STOCK",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (hasDiscount)
                        Text(
                          "₹${product.price}",
                          style: tt.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        "₹${product.discountPrice ?? product.price}",
                        style: tt.bodyMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
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
    );
  }
}
