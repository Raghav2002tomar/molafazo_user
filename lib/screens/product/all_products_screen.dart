import 'package:ecom/extensions/context_extension.dart';
import 'package:ecom/screens/product/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../services/api_service.dart';
import '../bottombar/controller/CityService.dart';
import '../bottombar/controller/category_service.dart';
import '../bottombar/controller/product_services.dart';
import '../bottombar/model/category_model.dart';
import '../bottombar/model/product_model.dart';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../bottombar/widget/product_card_widget.dart';

class AllProductsScreen extends StatefulWidget {
  final int? initialCategoryId;
  final int? initialSubCategoryId;
  final int? initialChildCategoryId;
  final String? categoryName;

  const AllProductsScreen({
    super.key,
    this.initialCategoryId,
    this.initialSubCategoryId,
    this.initialChildCategoryId,
    this.categoryName,
  });

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  int? selectedCategoryId;
  int? selectedSubCategoryId;
  int? selectedChildCategoryId;

  List<ProductModel> products = [];
  List<CategoryModel> categories = [];
  bool isLoading = true;
  bool isCategoryExpanded = false;
  String? selectedCity;
  String? selectedCountry;
  List<ProductModel> displayProducts = [];

  String? selectedPrice;
  String selectedSort = 'default';


  @override
  void initState() {
    super.initState();
    selectedCategoryId = widget.initialCategoryId;
    selectedSubCategoryId = widget.initialSubCategoryId;
    selectedChildCategoryId = widget.initialChildCategoryId;
    _initialize();
  }

  Future<void> _initialize() async {
    /// load saved city
    final data = await CityStorage.getCity();

    selectedCity = data?["city"];
    selectedCountry = data?["country"];

    await _loadCategories();
    await _fetchProducts();
  }

  Future<void> _loadCategories() async {
    categories = await CategoryService.fetchCategories();
    setState(() {});
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() => isLoading = true);

      final result = await ProductService.fetchProducts(
        categoryId: selectedCategoryId,
        subCategoryId: selectedSubCategoryId,
        childCategoryId: selectedChildCategoryId,
        city: selectedCity,
        country: selectedCountry,
      );

      setState(() {
        products = result;
        _applySortAndFilter();
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        products = [];
        isLoading = false;
      });
    }
  }

  void _applySortAndFilter() {
    List<ProductModel> list = List.from(products);

    if (selectedPrice == 'under_500') {
      list = list.where((p) {
        final price = double.tryParse((p.discountPrice ?? p.price).toString()) ?? 0;
        return price < 500;
      }).toList();
    } else if (selectedPrice == '500_1000') {
      list = list.where((p) {
        final price = double.tryParse((p.discountPrice ?? p.price).toString()) ?? 0;
        return price >= 500 && price <= 1000;
      }).toList();
    } else if (selectedPrice == 'above_1000') {
      list = list.where((p) {
        final price = double.tryParse((p.discountPrice ?? p.price).toString()) ?? 0;
        return price > 1000;
      }).toList();
    }

    if (selectedSort == 'price_low') {
      list.sort((a, b) {
        final aPrice = double.tryParse((a.discountPrice ?? a.price).toString()) ?? 0;
        final bPrice = double.tryParse((b.discountPrice ?? b.price).toString()) ?? 0;
        return aPrice.compareTo(bPrice);
      });
    } else if (selectedSort == 'price_high') {
      list.sort((a, b) {
        final aPrice = double.tryParse((a.discountPrice ?? a.price).toString()) ?? 0;
        final bPrice = double.tryParse((b.discountPrice ?? b.price).toString()) ?? 0;
        return bPrice.compareTo(aPrice);
      });
    } else if (selectedSort == 'name_az') {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    displayProducts = list;
  }

  void _selectCategory(int categoryId, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllProductsScreen(
          initialCategoryId: categoryId,
          categoryName: categoryName,
        ),
      ),
    );
  }

  void _selectSubCategory(int subCategoryId, String subCategoryName) {
    setState(() {
      selectedSubCategoryId = subCategoryId;
      selectedChildCategoryId = null;
      isCategoryExpanded = false;
    });

    _fetchProducts();
  }

  void _selectChildCategory(int childCategoryId) {
    setState(() {
      selectedChildCategoryId = childCategoryId;
    });
    _fetchProducts();
  }
  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sortTile('default', context.tr('txt_default')),
              _sortTile('price_low', context.tr('txt_price_low_high')),
              _sortTile('price_high', context.tr('txt_price_high_low')),
              _sortTile('name_az', context.tr('txt_name_az')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortTile(String value, String title) {
    return ListTile(
      title: Text(title),
      trailing: selectedSort == value
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: () {
        Navigator.pop(context);
        setState(() {
          selectedSort = value;
          _applySortAndFilter();
        });
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip(null, context.tr('txt_all')),
              _filterChip('under_500', '${context.tr('txt_under')} 500 c.'),
              _filterChip('500_1000', '500 - 1000 c.'),
              _filterChip('above_1000', '${context.tr('txt_above')} 1000 c.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String? value, String label) {
    final isSelected = selectedPrice == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.black,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) {
        Navigator.pop(context);
        setState(() {
          selectedPrice = value;
          _applySortAndFilter();
        });
      },
    );
  }


  String get _screenTitle {
    if (widget.categoryName != null) {
      return widget.categoryName!;
    }
    return "";
  }

  List<CategoryModel> get _visibleCategories {
    if (selectedCategoryId == null) {
      // ✅ MAIN CATEGORY → SHOW ALL (NO LIMIT)
      return categories;
    }
    return [];
  }


  List<SubCategoryModel> get _visibleSubCategories {
    if (selectedCategoryId != null && categories.isNotEmpty) {
      try {
        final category = categories.firstWhere(
              (c) => c.id == selectedCategoryId,
          orElse: () => categories.first,
        );
        return category.subCategories;
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  List<ChildCategoryModel> get _visibleChildCategories {
    if (selectedCategoryId != null &&
        selectedSubCategoryId != null &&
        categories.isNotEmpty) {
      try {
        final category = categories.firstWhere(
              (c) => c.id == selectedCategoryId,
        );

        final subCategory = category.subCategories.firstWhere(
              (s) => s.id == selectedSubCategoryId,
        );

        return subCategory.childCategories;
      } catch (e) {
        debugPrint('Error getting child categories: $e');
        return [];
      }
    }
    return [];
  }

  bool get _hasMoreCategories {
    try {

      // ❌ DO NOT allow expand for MAIN category
      if (selectedCategoryId == null) {
        return false;
      }

      // ✅ SubCategory expand
      else if (selectedSubCategoryId == null && categories.isNotEmpty) {
        final category = categories.firstWhere(
              (c) => c.id == selectedCategoryId,
          orElse: () => categories.first,
        );
        return category.subCategories.length > 5;
      }

      // ✅ ChildCategory expand
      else if (categories.isNotEmpty) {
        final category = categories.firstWhere(
              (c) => c.id == selectedCategoryId,
          orElse: () => categories.first,
        );
        final subCategory = category.subCategories.firstWhere(
              (s) => s.id == selectedSubCategoryId,
          orElse: () => category.subCategories.first,
        );
        return subCategory.childCategories.length > 5;
      }

    } catch (e) {
      debugPrint('Error checking more categories: $e');
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {

    // Loading state (initial)
    if (categories.isEmpty && isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(_screenTitle),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        title: Text(
          _screenTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,

        /// BACK BUTTON FIX
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        )
            : null,
      ),

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),

        slivers: [

          /// MAIN CATEGORY GRID
          if (selectedCategoryId == null &&
              categories.isNotEmpty)
            _buildCategoryGrid(),


          // /// SUB CATEGORY GRID
          // if (selectedCategoryId != null &&
          //     selectedSubCategoryId == null &&
          //     _visibleSubCategories.isNotEmpty)
          //   _buildSubCategoryGrid(),
          //
          //
          // /// CHILD CATEGORY GRID
          // if (selectedSubCategoryId != null &&
          //     _visibleChildCategories.isNotEmpty)
          //   _buildChildCategoryGrid(),

          if (selectedCategoryId != null)
            _buildSubCategoryList(),
          SliverToBoxAdapter(
            child: SizedBox(height: 8,),
          ),
          if (selectedSubCategoryId != null &&
              _visibleChildCategories.isNotEmpty)
            _buildChildCategoryList(),

          /// DIVIDER BEFORE PRODUCTS
          if (selectedCategoryId != null)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Divider(),
              ),
            ),


          /// PRODUCTS HEADER
          if (selectedCategoryId != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    16, 6, 16, 12),
                child: Row(
                  children: [
                    Text(
                      context.tr('txt_products'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "(${displayProducts.length})",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
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
              ),
            ),


          /// PRODUCTS GRID / LOADING / EMPTY
          if (selectedCategoryId != null)

            isLoading

                ? _buildProductGridShimmer()

                : products.isEmpty

                ? SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.all(40),
                child: Column(
                  children: [

                    Icon(
                      Icons.inventory_2_outlined,
                      size: 70,
                      color: Colors.grey[400],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      context.tr('txt_no_products_found'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )

                : _buildProductsGrid(),


          /// BOTTOM SPACE
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {

    final categories = _visibleCategories;

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          crossAxisCount: 2,
          childAspectRatio: 1.4,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {

            final category = categories[index];

            return _buildCategoryCard(
              image: category.image,
              name: category.name,
              onTap: () =>
                  _selectCategory(category.id, category.name),
            );
          },
          childCount: categories.length, // ✅ Always show ALL
        ),
      ),
    );
  }

  Widget _buildSubCategoryGrid() {
    final subCategories = _visibleSubCategories;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 220,
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),

          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // ✅ 2 rows
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),

          itemCount: subCategories.length,

          itemBuilder: (context, index) {
            final subCategory = subCategories[index];

            return _buildSubCategoryCard(
              name: subCategory.name,
              image: subCategory.image,
              onTap: () =>
                  _selectSubCategory(subCategory.id, subCategory.name),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubCategoryList() {
    final subCategories = _visibleSubCategories;

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        height: 62,
        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: subCategories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final item = subCategories[index];

            return _buildCategoryPill(
              name: item.name,
              image: item.image,
              isSelected: selectedSubCategoryId == item.id,
              showImage: true,
              onTap: () => _selectSubCategory(item.id, item.name),
            );
          },
        ),
      ),
    );
  }


  Widget _buildChildCategoryList() {
    final childCategories = _visibleChildCategories;
    final bool showTwoLines = childCategories.length > 2;

    final firstRow = <ChildCategoryModel>[];
    final secondRow = <ChildCategoryModel>[];

    for (int i = 0; i < childCategories.length; i++) {
      if (i.isEven) {
        firstRow.add(childCategories[i]);
      } else {
        secondRow.add(childCategories[i]);
      }
    }

    Widget buildRow(List<ChildCategoryModel> items) {
      return Row(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _buildCategoryPill(
              name: item.name,
              image: '',
              isSelected: selectedChildCategoryId == item.id,
              showImage: false,
              onTap: () => _selectChildCategory(item.id),
            ),
          );
        }).toList(),
      );
    }

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        height: showTwoLines ? 82 : 42,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: showTwoLines
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildRow(firstRow),
              const SizedBox(height: 8),
              buildRow(secondRow),
            ],
          )
              : buildRow(childCategories),
        ),
      ),
    );
  }


  Widget _buildCategoryPill({
    required String name,
    required String image,
    required bool isSelected,
    required bool showImage,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 30,
        padding: EdgeInsets.symmetric(
          horizontal: showImage ? 8 : 16,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B7CFF) : const Color(0xFFF4F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showImage) ...[
              Container(
                height: 28,
                width: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFC94A),
                ),
                child: ClipOval(
                  child: Image.network(
                    "${ApiService.ImagebaseUrl}${ApiService.subcategory_images_URL}$image",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Widget _buildChildCategoryList() {
  //   final childCategories = _visibleChildCategories;
  //   final bool showTwoLines = childCategories.length > 2;
  //
  //   final double itemHeight = 40;
  //   final double spacing = 10;
  //
  //   return SliverToBoxAdapter(
  //     child: Container(
  //       color: Colors.white,
  //
  //       // ✅ PERFECT HEIGHT CALCULATION
  //       height: showTwoLines
  //           ? (itemHeight * 2) + spacing + 16 // top + bottom padding
  //           : itemHeight + 16,
  //
  //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //
  //       child: SingleChildScrollView(
  //         scrollDirection: Axis.horizontal,
  //         child: Wrap(
  //           direction: Axis.vertical,
  //           spacing: showTwoLines ? spacing : 0,
  //           runSpacing: spacing,
  //           alignment: WrapAlignment.start,
  //           children: childCategories.map((item) {
  //             return _buildCategoryPill(
  //               name: item.name,
  //               image: '',
  //               isSelected: selectedChildCategoryId == item.id,
  //               showImage: false,
  //               onTap: () => _selectChildCategory(item.id),
  //             );
  //           }).toList(),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildChipCard({
    required String name,
    required String image,
    required VoidCallback onTap,
    required bool isSelected, // 👈 add this
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade200, // ✅ BLACK
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [

            /// IMAGE
            Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.network(
                  "${ApiService.ImagebaseUrl}${ApiService.subcategory_images_URL}$image",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(width: 10),

            /// TEXT
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87, // ✅ WHITE TEXT
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCategoryGrid() {
    final childCategories = _visibleChildCategories;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 190, // ✅ controls 2 rows height
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal, // ✅ horizontal scroll
          physics: const BouncingScrollPhysics(),

          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // ✅ 2 rows
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),

          itemCount: childCategories.length,

          itemBuilder: (context, index) {
            final childCategory = childCategories[index];
            final isSelected =
                selectedChildCategoryId == childCategory.id;

            return _buildChildCategoryCard(
              name: childCategory.name,
              image: childCategory.image,
              isSelected: isSelected,
              onTap: () => _selectChildCategory(childCategory.id),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String image,
    required String name,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [

            /// Category Title (Top Left)
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),

            /// Category Image (Bottom Right)
            Positioned(
              bottom: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(18),
                ),
                child: Image.network(
                  "${ApiService.ImagebaseUrl}${ApiService.category_images_URL}$image",
                  height: 90,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 90,
                    width: 80,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.category,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategoryCard({
    required String name,
    required String image,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  "${ApiService.ImagebaseUrl}${ApiService.subcategory_images_URL}$image",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.category,
                        size: 32, color: Colors.grey[400]),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildChildCategoryCard({
    required String name,
    required String image,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.green.shade600
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  "${ApiService.ImagebaseUrl}${ApiService.subchild_category_images_URL}$image",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported,
                        size: 32, color: Colors.grey[400]),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? Colors.green.shade800
                      : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildExpandButton({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.grey.shade700),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.55,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {

            final product = displayProducts[index];

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
            );
          },
          childCount: displayProducts.length,
        ),
      ),
    );
  }
  Widget _buildProductGridShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
              (_, __) => Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          childCount: 6,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        );
        // Navigate to product detail
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  "${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${product.image}",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
                  ),
                ),
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${product.price} c.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
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