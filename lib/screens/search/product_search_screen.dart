import 'package:ecom/extensions/context_extension.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../bottombar/BottomNavWrapper.dart';
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

  List<ProductModel> _searchResults = [];
  List<ProductModel> _displayProducts = [];
  Map<String, dynamic> _globalSearchResults = {};
  List<String> _recentSearches = [];

  bool _isLoading = false;

  String? _selectedPrice;
  Set<String> _selectedDelivery = {};
  String _selectedSort = 'default';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    _recentSearches.remove(value);
    _recentSearches.insert(0, value);

    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.take(10).toList();
    }

    await prefs.setStringList('recent_searches', _recentSearches);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');

    if (!mounted) return;

    setState(() {
      _recentSearches = [];
    });
  }

  Future<void> _performSearch() async {
    final searchText = _searchController.text.trim();

    if (searchText.isEmpty) {
      setState(() {
        _searchResults = [];
        _displayProducts = [];
        _globalSearchResults = {};
        _isLoading = false;
      });
      return;
    }

    await _saveRecentSearch(searchText);

    setState(() {
      _isLoading = true;
      _searchResults = [];
      _displayProducts = [];
      _globalSearchResults = {};
    });

    try {
      final cityData = await CityStorage.getCity();
      final filter = await CityStorage.getDeliveryFilter();

      final productFuture = ProductSearchApi()
          .searchProducts(
        query: searchText,
        deliveryCity: cityData["name"],
        deliveryType: filter["delivery_type"],
        deliveryTimeValue: filter["delivery_time_value"],
        deliveryTimeUnit: filter["delivery_time_unit"],
      )
          .catchError((e) => <ProductModel>[]);

      final globalFuture = ProductSearchApi()
          .globalSearch(
        query: searchText,
        deliveryCity: cityData["name"],
        deliveryType: filter["delivery_type"],
        deliveryTimeValue: filter["delivery_time_value"],
        deliveryTimeUnit: filter["delivery_time_unit"],
      )
          .catchError((e) => <String, dynamic>{});

      final results = await Future.wait<dynamic>([
        productFuture,
        globalFuture,
      ]);

      if (!mounted) return;
      if (_searchController.text.trim() != searchText) return;

      setState(() {
        _searchResults = results[0] as List<ProductModel>;
        _globalSearchResults = results[1] as Map<String, dynamic>;
        _applySortAndFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint("Search error: $e");

      setState(() {
        _searchResults = [];
        _displayProducts = [];
        _globalSearchResults = {};
        _isLoading = false;
      });
    }
  }

  void _applySortAndFilter() {
    List<ProductModel> list = List.from(_searchResults);

    if (_selectedPrice == 'under_500') {
      list = list.where((p) {
        final price =
            double.tryParse((p.discountPrice ?? p.price).toString()) ?? 0;
        return price < 500;
      }).toList();
    } else if (_selectedPrice == '500_1000') {
      list = list.where((p) {
        final price =
            double.tryParse((p.discountPrice ?? p.price).toString()) ?? 0;
        return price >= 500 && price <= 1000;
      }).toList();
    } else if (_selectedPrice == 'above_1000') {
      list = list.where((p) {
        final price =
            double.tryParse((p.discountPrice ?? p.price).toString()) ?? 0;
        return price > 1000;
      }).toList();
    }

    if (_selectedSort == 'price_low') {
      list.sort((a, b) {
        final aPrice =
            double.tryParse((a.discountPrice ?? a.price).toString()) ?? 0;
        final bPrice =
            double.tryParse((b.discountPrice ?? b.price).toString()) ?? 0;
        return aPrice.compareTo(bPrice);
      });
    } else if (_selectedSort == 'price_high') {
      list.sort((a, b) {
        final aPrice =
            double.tryParse((a.discountPrice ?? a.price).toString()) ?? 0;
        final bPrice =
            double.tryParse((b.discountPrice ?? b.price).toString()) ?? 0;
        return bPrice.compareTo(aPrice);
      });
    } else if (_selectedSort == 'name_az') {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    _displayProducts = list;
  }

  Future<void> _showFilterBottomSheet() async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
        _applySortAndFilter();
      });
    }
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                _sortTile('default', context.tr('txt_default')),
                _sortTile('price_low', context.tr('txt_price_low_high')),
                _sortTile('price_high', context.tr('txt_price_high_low')),
                _sortTile('name_az', context.tr('txt_name_az')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sortTile(String value, String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: _selectedSort == value
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _selectedSort = value;
          _applySortAndFilter();
        });
      },
    );
  }

  bool get _hasGlobalResults {
    return (_globalSearchResults['categories'] as List? ?? []).isNotEmpty ||
        (_globalSearchResults['sub_categories'] as List? ?? []).isNotEmpty ||
        (_globalSearchResults['child_categories'] as List? ?? []).isNotEmpty ||
        (_globalSearchResults['stores'] as List? ?? []).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _displayProducts.isEmpty &&
        !_hasGlobalResults &&
        _searchController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 76,
        titleSpacing: 16,
        title: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: SizedBox(
                height: 52,
                child: _SearchField(
                  controller: _searchController,
                  onChanged: (_) => _performSearch(),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _searchController.text.isEmpty
            ? _RecentSearchView(
          searches: _recentSearches,
          onTap: (value) {
            _searchController.text = value;
            _performSearch();
          },
          onClear: _clearRecentSearches,
        )
            : isEmpty
            ? _EmptySearchView(onFilterTap: _showFilterBottomSheet)
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSmartSearchChips(),
              _buildPremiumStoreList(),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      context.tr('txt_products'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${_displayProducts.length})',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _SmallActionButton(
                      icon: Icons.sort_rounded,
                      label: context.tr('txt_sort'),
                      onTap: _showSortBottomSheet,
                    ),
                    const SizedBox(width: 8),
                    _SmallActionButton(
                      icon: Icons.tune_rounded,
                      label: context.tr('txt_filter'),
                      onTap: _showFilterBottomSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_displayProducts.isEmpty)
                  _FilteredEmptyView(
                    onClear: () {
                      setState(() {
                        _selectedPrice = null;
                        _selectedDelivery.clear();
                        _selectedSort = 'default';
                        _applySortAndFilter();
                      });
                    },
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _displayProducts.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.55,
                    ),
                    itemBuilder: (context, index) {
                      final product = _displayProducts[index];

                      return ProductCardWidget(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(
                                    productId: product.id,
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartSearchChips() {
    final categories = _globalSearchResults['categories'] ?? [];
    final subCategories = _globalSearchResults['sub_categories'] ?? [];
    final childCategories = _globalSearchResults['child_categories'] ?? [];

    final items = [
      ...categories,
      ...subCategories,
      ...childCategories,
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map<Widget>((item) {
        final name = item['name']?.toString() ?? '';

        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            _searchController.text = name;
            _performSearch();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up_rounded, size: 15),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPremiumStoreList() {
    final stores = _globalSearchResults['stores'] ?? [];
    if (stores.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final store = stores[index];

              final name = store['name']?.toString() ?? '';
              final city = store['city']?.toString() ?? '';
              final logo = store['logo']?.toString();

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  final storeId = int.tryParse(store['id'].toString());
                  if (storeId == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoreDetailScreen(
                        storeId: storeId,
                        storeName: name,
                      ),
                    ),
                  );

                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => BottomNavWrapper(
                  //       currentIndex: 1,
                  //       onTap: (_) => Navigator.pop(context),
                  //       child: StoreDetailScreen(
                  //         storeId: storeId,
                  //         storeName: name,
                  //       ),
                  //     ),
                  //   ),
                  // );
                },
                child: Container(
                  width: 190,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: logo != null && logo.isNotEmpty
                            ? Image.network(
                          "${ApiService.ImagebaseUrl}/${ApiService.store_logo_URL}$logo",
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _fallbackStoreLogo(),
                        )
                            : _fallbackStoreLogo(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 11,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    city,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _fallbackStoreLogo() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.storefront_rounded,
        size: 24,
        color: Colors.grey,
      ),
    );
  }
}

class _RecentSearchView extends StatelessWidget {
  final List<String> searches;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;

  const _RecentSearchView({
    required this.searches,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (searches.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: searches.map((item) {
              return InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => onTap(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        item,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FilteredEmptyView extends StatelessWidget {
  final VoidCallback onClear;

  const _FilteredEmptyView({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.filter_alt_off_rounded, size: 42, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          const Text(
            'No products match this filter',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onClear,
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}

class _FilterResult {
  final String? price;
  final Set<String>? delivery;

  _FilterResult({
    this.price,
    this.delivery,
  });
}

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
          Row(
            children: [
              Text(
                context.tr('txt_filters'),
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    price = null;
                    delivery.clear();
                  });
                },
                child: Text(context.tr('txt_clear')),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(context.tr('txt_price_range'), style: tt.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _SelectableChip(
                label: "${context.tr('txt_under')} 500 c.",
                selected: price == "under_500",
                onTap: () => setState(() => price = "under_500"),
              ),
              _SelectableChip(
                label: "500 - 1000 c.",
                selected: price == "500_1000",
                onTap: () => setState(() => price = "500_1000"),
              ),
              _SelectableChip(
                label: "${context.tr('txt_above')} 1000 c.",
                selected: price == "above_1000",
                onTap: () => setState(() => price = "above_1000"),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _FilterResult(
                    price: price,
                    delivery: delivery,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(context.tr('txt_apply_filter')),
            ),
          ),
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
          color: selected ? Colors.white : cs.onSurfaceVariant,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.black,
      backgroundColor: cs.surfaceVariant,
      surfaceTintColor: Colors.transparent,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? Colors.black : cs.outlineVariant,
        ),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,

        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [

          const SizedBox(width: 10),

          Expanded(
            child: TextFormField(

              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              cursorColor: Colors.black,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,

                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),

                hintText: context.tr('txt_search_products_brands'),
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),

                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,

                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return controller.text.isNotEmpty
                  ? Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              )
                  : const SizedBox(width: 12);
            },
          ),
        ],
      ),
    );
  }
}
class _EmptySearchView extends StatelessWidget {
  final VoidCallback onFilterTap;

  const _EmptySearchView({
    required this.onFilterTap,
  });

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
            Icon(Icons.search_off, size: 80, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              context.tr('txt_no_product_found'),
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('try_diff_keyword'),
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}