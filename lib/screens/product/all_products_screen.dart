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
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        products = [];
        isLoading = false;
      });
    }
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllProductsScreen(
          initialCategoryId: selectedCategoryId,
          initialSubCategoryId: subCategoryId,
          categoryName: subCategoryName,
        ),
      ),
    );
  }

  void _selectChildCategory(int childCategoryId) {
    setState(() {
      selectedChildCategoryId = childCategoryId;
    });
    _fetchProducts();
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
    if (selectedCategoryId != null && selectedSubCategoryId == null && categories.isNotEmpty) {
      try {
        final category = categories.firstWhere(
              (c) => c.id == selectedCategoryId,
          orElse: () => categories.first,
        );
        return isCategoryExpanded
            ? category.subCategories
            : (category.subCategories.length > 5
            ? category.subCategories.take(5).toList()
            : category.subCategories);
      } catch (e) {
        debugPrint('Error getting subcategories: $e');
        return [];
      }
    }
    return [];
  }

  List<ChildCategoryModel> get _visibleChildCategories {
    if (selectedSubCategoryId != null && categories.isNotEmpty) {
      try {
        final category = categories.firstWhere(
              (c) => c.id == selectedCategoryId,
          orElse: () => categories.first,
        );
        final subCategory = category.subCategories.firstWhere(
              (s) => s.id == selectedSubCategoryId,
          orElse: () => category.subCategories.first,
        );
        return isCategoryExpanded
            ? subCategory.childCategories
            : (subCategory.childCategories.length > 5
            ? subCategory.childCategories.take(5).toList()
            : subCategory.childCategories);
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

          if (selectedCategoryId != null &&
              selectedSubCategoryId == null)
            _buildSubCategoryList(),

          if (selectedSubCategoryId != null)
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
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [

                    const Text(
                      "Products",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      "${products.length} items",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
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
                      "No products found",
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
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          itemCount: subCategories.length,
          itemBuilder: (context, index) {
            final item = subCategories[index];

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildChipCard(
                name: item.name,
                image: item.image,
                onTap: () =>
                    _selectSubCategory(item.id, item.name),
              ),
            );
          },
        ),
      ),
    );
  }Widget _buildChildCategoryList() {
    final childCategories = _visibleChildCategories;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 70,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: childCategories.length,
          itemBuilder: (context, index) {
            final item = childCategories[index];
            final isSelected =
                selectedChildCategoryId == item.id;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildChipCard(
                name: item.name,
                image: item.image,
                isSelected: isSelected,
                onTap: () => _selectChildCategory(item.id),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChipCard({
    required String name,
    required String image,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade300 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? Colors.green
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            /// IMAGE
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.network(
                  "${ApiService.ImagebaseUrl}${ApiService.subcategory_images_URL}$image",
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image,
                    size: 20,
                    color: Colors.grey[400],
                  ),
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
                color: isSelected
                    ? Colors.green.shade800
                    : Colors.black87,
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
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final product = products[index];

            return ProductCardWidget( // ✅ YOUR MAIN CARD
              product: product,

              /// optional callbacks if your card supports
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailScreen(productId: product.id),
                  ),
                );
              },


            );
          },
          childCount: products.length,
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
