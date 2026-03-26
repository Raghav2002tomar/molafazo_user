import 'package:ecom/screens/bottombar/widget/product_card_widget.dart';
import 'package:ecom/screens/bottombar/widget/store_card_widget.dart';
import 'package:ecom/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../cart/controller/cart_services.dart';
import '../product/all_products_screen.dart';
import '../product/product_details_screen.dart';
import '../product/store_detail_screen.dart';
import '../search/product_search_screen.dart';
import 'AllStoresScreen.dart';
import 'BottomNavWrapper.dart';
import 'CitySearchScreen.dart';
import 'MainScreen.dart';
import 'controller/BannerService.dart';
import 'controller/CityService.dart';
import 'controller/category_service.dart';
import 'controller/product_services.dart';

import 'controller/store_services.dart';
import 'model/Banner_Model.dart';
import 'model/category_model.dart';
import 'model/product_model.dart';
import 'model/store_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ValueNotifier<int?> selectedCategoryId = ValueNotifier(null);
  final ValueNotifier<int?> selectedSubCategoryId = ValueNotifier(null);
  final ValueNotifier<int?> selectedChildCategoryId = ValueNotifier(null);

  final ValueNotifier<List<ProductModel>> products = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  int? selectedCityId;
  String? selectedCity;
  @override
  void initState() {
    super.initState();
    loadCity();
    _fetchAllProducts();
  }

  void loadCity() async {

    final data = await CityStorage.getCity();

    setState(() {
      selectedCityId = data["id"];
      selectedCity = data["name"];
    });

    _fetchAllProducts();
  }
  void removeCity() async {

    await CityStorage.removeCity();

    setState(() {
      selectedCity = null;
    });

    _fetchAllProducts();


  }

  /// Fetch all products initially
  Future<void> _fetchAllProducts() async {

    try {

      isLoading.value = true;

      final result = await ProductService.fetchAllProducts(
        cityId: selectedCityId?.toString(),
      );

      products.value = result;

    } catch (e) {

      products.value = [];
      debugPrint("Error fetching products: $e");

    } finally {

      isLoading.value = false;

    }
  }
  /// Fetch filtered products when category/subcategory/child selected
  Future<void> _fetchFilteredProducts() async {

    try {

      isLoading.value = true;

      final result = await ProductService.fetchProducts(
        categoryId: selectedCategoryId.value,
        subCategoryId: selectedSubCategoryId.value,
        childCategoryId: selectedChildCategoryId.value,
        city: selectedCity,
      );

      products.value = result;

    } catch (e) {

      products.value = [];
      debugPrint("Error fetching filtered products: $e");

    } finally {

      isLoading.value = false;

    }
  }

  /// Clear all filters
  void _clearFilters() {
    selectedCategoryId.value = null;
    selectedSubCategoryId.value = null;
    selectedChildCategoryId.value = null;
    _fetchAllProducts();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            /// HEADER
            SliverAppBar(
              pinned: true,
              floating: false,
              snap: false,
              elevation: 0,
              backgroundColor: cs.surface,
              automaticallyImplyLeading: false,

              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Column(
                      children: [

                        /// 📍 LOCATION ROW
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CitySearchScreen(),
                                ),
                              );

                              if (result != null) {

                                setState(() {
                                  selectedCityId = result["id"];
                                  selectedCity = result["name"];
                                });

                                if (selectedCityId == null) {
                                  _fetchAllProducts(); // show all cities products
                                } else {
                                  _fetchFilteredProducts(); // filter by city
                                }
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 18,
                                ),

                                const SizedBox(width: 6),

                                Text(
                                  selectedCity ?? "All Cities"
,                                  overflow: TextOverflow.ellipsis,
                                  style: tt.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                /// ❌ CLEAR LOCATION BUTTON
                                if (selectedCity != null)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedCityId = null;
                                        selectedCity = null;
                                        removeCity();
                                      });

                                      _fetchFilteredProducts();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ),

                                /// ⌄ Dropdown Icon
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 20,
                                  color: cs.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),                        const SizedBox(height: 10),

                        /// 🔍 SEARCH + MENU
                        Row(
                          children: [

                            Expanded(
                              child: InkWell(onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>ProductSearchScreen()));
                              },
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: cs.outlineVariant),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.search,
                                          size: 20, color: cs.onSurfaceVariant),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Search products...",
                                        style: tt.bodyMedium?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            InkWell(onTap: (){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BottomNavWrapper(
                                    currentIndex: 1, // Shop tab
                                    onTap: (index) {
                                      // Handle tab change - navigate to appropriate screen
                                      Navigator.pop(context);
                                      // Then change tab in main bottom nav
                                    },
                                    child: AllProductsScreen(
                                      // initialCategoryId: categoryId,
                                      // categoryName: categoryName,
                                    ),
                                  ),
                                ),
                              );                            },
                              child: Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Icon(Icons.menu, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            /// BANNERS
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200, // 🔥 Bigger banner
                child: FutureBuilder<List<BannerModel>>(
                  future: BannerService.fetchBanners(
                    city: selectedCity,
                  ),
                  builder: (_, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _PromoBannerShimmer();
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox();
                    }

                    return _AutoBannerSlider(banners: snapshot.data!);
                  },
                )
              ),
            ),


            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            /// FILTER BREADCRUMB & CLEAR BUTTON
            ValueListenableBuilder<int?>(
              valueListenable: selectedCategoryId,
              builder: (_, catId, __) {
                if (catId == null)
                  return const SliverToBoxAdapter(child: SizedBox());

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _FilterBreadcrumb(
                            selectedCategoryId: selectedCategoryId,
                            selectedSubCategoryId: selectedSubCategoryId,
                            selectedChildCategoryId: selectedChildCategoryId,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ClearFilterButton(onClear: _clearFilters),
                      ],
                    ),
                  ),
                );
              },
            ),


            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            /// PRODUCTS SECTION HEADER


            /// PRODUCTS GRID
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (_, loading, __) {
                if (loading) return const _ProductGridShimmer();

                return ValueListenableBuilder<List<ProductModel>>(
                  valueListenable: products,
                  builder: (_, list, __) {
                    if (list.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: cs.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No products found",
                                style: tt.bodyLarge?.copyWith(
                                  color: cs.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

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
                              (_, i) => ProductCardWidget(product: list[i], onTap: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(productId: list[i].id),
                                  ),
                                );
                              },),
                          childCount: list.length >= 6 ?  6: list.length, // SAFE LIMIT
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            /// STORES HEADER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.storefront,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Stores",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllStoresScreen(
                              city: selectedCity,
                            ),
                          ),
                        );
                      },
                      child: const Text("View All"),
                    )
                  ],
                ),
              ),
            ),

            /// STORES LIST
            SliverToBoxAdapter(
              child: SizedBox(
                height: 270,
                child: FutureBuilder(
                  future: StoreService.fetchStores(
                    city: selectedCity,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, __) => Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            width: 220,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemCount: 3,
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedCity == null
                                  ? "No stores available"
                                  : "No stores found in $selectedCity",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final stores = snapshot.data!;

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) {
                        final store = stores[i];

                        return StoreCardWidget(
                          store: store,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StoreDetailScreen(
                                  storeId: store.id,
                                  storeName: store.name,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemCount: stores.length,
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------
/// FILTER BREADCRUMB
/// ------------------------------
class _FilterBreadcrumb extends StatelessWidget {
  final ValueNotifier<int?> selectedCategoryId;
  final ValueNotifier<int?> selectedSubCategoryId;
  final ValueNotifier<int?> selectedChildCategoryId;

  const _FilterBreadcrumb({
    required this.selectedCategoryId,
    required this.selectedSubCategoryId,
    required this.selectedChildCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return FutureBuilder<List<CategoryModel>>(
      future: CategoryService.fetchCategories(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final categories = snapshot.data!;
        String breadcrumb = "";

        if (selectedCategoryId.value != null) {
          final cat = categories.firstWhere(
            (c) => c.id == selectedCategoryId.value,
          );
          breadcrumb = cat.name;

          if (selectedSubCategoryId.value != null) {
            final sub = cat.subCategories.firstWhere(
              (s) => s.id == selectedSubCategoryId.value,
            );
            breadcrumb += " > ${sub.name}";

            if (selectedChildCategoryId.value != null) {
              final child = sub.childCategories.firstWhere(
                (c) => c.id == selectedChildCategoryId.value,
              );
              breadcrumb += " > ${child.name}";
            }
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list, size: 14, color: cs.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  breadcrumb,
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ------------------------------
/// CLEAR FILTER BUTTON
/// ------------------------------
class _ClearFilterButton extends StatelessWidget {
  final VoidCallback onClear;
  const _ClearFilterButton({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onClear,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cs.errorContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.error.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, size: 14, color: cs.error),
            const SizedBox(width: 4),
            Text(
              "Clear",
              style: TextStyle(
                fontSize: 11,
                color: cs.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------
/// COMPACT CATEGORY CHIP
/// ------------------------------

class _CompactBigCategoryChip extends StatelessWidget {
  final String label;
  final String image;
  final bool selected;
  final bool isSecondary;
  final bool isChild;

  const _CompactBigCategoryChip({
    super.key,
    required this.label,
    required this.image,
    this.selected = false,
    this.isSecondary = false,
    this.isChild = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color fgColor;
    Color borderColor;

    if (selected) {
      bgColor = isDark ? Colors.white : Colors.black;
      fgColor = isDark ? Colors.black : Colors.white;
      borderColor = fgColor;
    } else if (isChild) {
      bgColor = cs.surfaceContainerHighest;
      fgColor = cs.onSurface.withOpacity(0.75);
      borderColor = cs.outlineVariant.withOpacity(0.5);
    } else if (isSecondary) {
      bgColor = cs.surfaceContainer;
      fgColor = cs.onSurface.withOpacity(0.85);
      borderColor = cs.outlineVariant;
    } else {
      bgColor = cs.surface;
      fgColor = cs.onSurface;
      borderColor = cs.outlineVariant;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 80, // ✅ narrower
      height: 70, // ✅ taller
      // padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: cs.shadow.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // 🖼️ Image with top corners rounded only
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: SizedBox(
              height: 45,
              width: 80,
              child: Image.network(
                "${ApiService.ImagebaseUrl}${ApiService.category_images_URL}$image",
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 2),

          // 📝 Text
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fgColor,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isSecondary;
  final bool isChild;

  const _CompactCategoryChip({
    required this.label,
    this.selected = false,
    this.isSecondary = false,
    this.isChild = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color fgColor;
    Color borderColor;

    if (selected) {
      bgColor = isDark ? Colors.white : Colors.black;
      fgColor = isDark ? Colors.black : Colors.white;
      borderColor = isDark ? Colors.white : Colors.black;
    } else if (isChild) {
      bgColor = cs.surfaceContainerHighest;
      fgColor = cs.onSurface.withOpacity(0.7);
      borderColor = cs.outlineVariant.withOpacity(0.5);
    } else if (isSecondary) {
      bgColor = cs.surfaceContainer;
      fgColor = cs.onSurface.withOpacity(0.8);
      borderColor = cs.outlineVariant;
    } else {
      bgColor = cs.surface;
      fgColor = cs.onSurface;
      borderColor = cs.outlineVariant;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: isChild ? 10 : 12,
        vertical: isChild ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: cs.shadow.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fgColor,
          fontSize: isChild ? 11 : 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}

/// ------------------------------
/// PROMO CARD
/// ------------------------------
class _PromoCardDynamic extends StatelessWidget {
  final BannerModel banner;
  const _PromoCardDynamic({required this.banner});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: isDark ? Colors.white38 : Colors.black12,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          "${ApiService.ImagebaseUrl}${ApiService.banner_images_URL}${banner.image}",
          width: 240,
          height: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(width: 240, color: Colors.grey),
            );
          },
          errorBuilder: (_, __, ___) =>
              Image.asset('assets/images/banner_error.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// ------------------------------
/// SHIMMERS
/// ------------------------------

class _ProductGridShimmer extends StatelessWidget {
  const _ProductGridShimmer();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
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

class _AutoBannerSlider extends StatefulWidget {
  final List<BannerModel> banners;
  const _AutoBannerSlider({required this.banners});

  @override
  State<_AutoBannerSlider> createState() => _AutoBannerSliderState();
}

class _AutoBannerSliderState extends State<_AutoBannerSlider> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  void _autoScroll() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      _currentIndex++;
      if (_currentIndex >= widget.banners.length) {
        _currentIndex = 0;
      }

      _controller.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (_, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _BigPromoCard(banner: widget.banners[i]),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        /// 🔵 Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
                (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentIndex == index ? 18 : 6,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? Colors.black
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _BigPromoCard extends StatelessWidget {
  final BannerModel banner;
  const _BigPromoCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          "${banner.image}",
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            return Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(color: Colors.grey),
            );
          },
          errorBuilder: (_, __, ___) =>
              Image.asset("assets/images/banner_error.png", fit: BoxFit.cover),
        ),
      ),
    );
  }
}
class _PromoBannerShimmer extends StatelessWidget {
  const _PromoBannerShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
