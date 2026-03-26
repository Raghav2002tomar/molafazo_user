import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../bottombar/controller/CityService.dart';
import '../bottombar/model/product_model.dart';
import '../bottombar/widget/product_card_widget.dart';
import '../product/product_details_screen.dart';
import '../product/store_detail_screen.dart';
import 'controller/product_search_api.dart';


class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProductSearchApi _searchApi = ProductSearchApi();
  List<ProductModel> _searchResults = [];
  bool _isLoading = false;
  String? _selectedCity;
  String? _selectedCountry;
  String? _selectedPrice;
  Set<String> _selectedDelivery = {};

  @override
  void initState() {
    super.initState();
    _loadCity();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // You can implement debounce here if needed
  }

  Future<void> _loadCity() async {

    final data = await CityStorage.getCity();

    setState(() {
      _selectedCity = data["name"];
    });

  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _searchApi.searchProducts(
        query: _searchController.text,
        city: _selectedCity,
        country: _selectedCountry,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Search failed: $e")),
      );
    }
  }

  Future<void> _showFilterBottomSheet() async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterBottomSheet(
        initialPrice: _selectedPrice,
        initialDelivery: _selectedDelivery,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedPrice = result.price;
        _selectedDelivery = result.delivery ?? {};
      });
      // Re-run search with filters
      _performSearch();
    }
  }

  void _clearCityFilter() {
    setState(() {
      _selectedCity = null;
      _selectedCountry = null;
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        bottom: _selectedCity != null
            ? PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(
                "Searching in: $_selectedCity${_selectedCountry != null ? ', $_selectedCountry' : ''}",
              ),
              onDeleted: _clearCityFilter,
              deleteIcon: const Icon(Icons.close, size: 18),
            ),
          ),
        )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Field
            Padding(
              padding: const EdgeInsets.all(16),
              child: _SearchField(
                controller: _searchController,
                onChanged: (_) => _performSearch(),
                onFilterTap: _showFilterBottomSheet,
              ),
            ),

            // Active Filters Display
            if (_selectedPrice != null || _selectedDelivery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_selectedPrice != null)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(
                              _getPriceLabel(_selectedPrice!),
                              style: const TextStyle(fontSize: 12),
                            ),
                            onDeleted: () {
                              setState(() => _selectedPrice = null);
                              _performSearch();
                            },
                          ),
                        ),
                      if (_selectedDelivery.contains('fast'))
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: const Text('Fast Delivery'),
                            onDeleted: () {
                              setState(() => _selectedDelivery.remove('fast'));
                              _performSearch();
                            },
                          ),
                        ),
                      if (_selectedDelivery.contains('free'))
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: const Text('Free Delivery'),
                            onDeleted: () {
                              setState(() => _selectedDelivery.remove('free'));
                              _performSearch();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Results
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchController.text.isEmpty
                  ?  _InitialSearchView()
                  : _searchResults.isEmpty
                  ? _EmptySearchView(onFilterTap: _showFilterBottomSheet)
                  : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.55,
                ),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final product = _searchResults[index];

                  return ProductCardWidget(
                    product: product,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            productId: product.id,
                          ),
                        ),
                      );
                    },

                    onStoreTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreDetailScreen(
                            storeId: product.store.id,
                          ),
                        ),
                      );
                    },

                    // onAddCart: () {
                    //   // CartService.addProduct(product);
                    // },

                    onFavourite: () {
                      // WishlistService.toggle(product.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPriceLabel(String price) {
    switch (price) {
      case 'under_500':
        return 'Under 500 c.';
      case '500_1000':
        return '500 - 1000 c.';
      case 'above_1000':
        return 'Above 1000 c.';
      default:
        return price;
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
                label: "Under 500 c.",
                selected: price == "under_500",
                onTap: () => setState(() => price = "under_500"),
              ),
              _SelectableChip(
                label: "500 - 1000 c.",
                selected: price == "500_1000",
                onTap: () => setState(() => price = "500_1000"),
              ),
              _SelectableChip(
                label: "Above 1000 c.",
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
                          "${product.price} c.",
                          style: tt.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 8
                          ),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        "${product.discountPrice ?? product.price} c.",
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
