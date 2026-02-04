import 'package:ecom/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../product/all_products_screen.dart';
import '../product/product_details_screen.dart';
import '../product/store_detail_screen.dart';
import 'controller/BannerService.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchAllProducts();
  }

  /// Fetch all products initially
  Future<void> _fetchAllProducts() async {
    try {
      isLoading.value = true;
      final result = await ProductService.fetchAllProducts();
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
            // SliverAppBar(
            //   pinned: true,
            //   elevation: 0,
            //   backgroundColor: cs.surface,
            //   title: _Header(),
            // ),
            SliverToBoxAdapter(
                child:   Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // 🔍 Search Box
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: cs.shadow.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: cs.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  cursorColor: cs.onSurface,
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search...',
                                    hintStyle: tt.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    isCollapsed: true, // tight layout
                                    contentPadding: EdgeInsets.zero, // remove default padding
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),


                      const SizedBox(width: 12),

                      // ⚙️ Filter Button
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: isDark? Colors.white: Colors.black,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.tune_rounded, color:isDark? Colors.black: Colors.white),
                      ),
                    ],
                  ),
                )

            ),
            /// BANNERS
            SliverToBoxAdapter(
              child: SizedBox(
                height: 130,
                child: FutureBuilder<List<BannerModel>>(
                  future: BannerService.fetchBanners(),
                  builder: (_, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, __) => const _PromoCardShimmer(),
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemCount: 3,
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No banners"));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) =>
                          _PromoCardDynamic(banner: snapshot.data![i]),
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemCount: snapshot.data!.length,
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            /// FILTER BREADCRUMB & CLEAR BUTTON
            ValueListenableBuilder<int?>(
              valueListenable: selectedCategoryId,
              builder: (_, catId, __) {
                if (catId == null) return const SliverToBoxAdapter(child: SizedBox());

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

            /// MAIN CATEGORIES
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, size: 18, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      "Categories",
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AllProductsScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "See all",
                        style: tt.labelLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 38,
                child: FutureBuilder<List<CategoryModel>>(
                  future: CategoryService.fetchCategories(),
                  builder: (_, snapshot) {
                    if (!snapshot.hasData) {
                      return _CategoryScrollShimmer();
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) {
                        final cat = snapshot.data![i];
                        return GestureDetector(
                          onTap: () {
                            selectedCategoryId.value = cat.id;
                            selectedSubCategoryId.value = null;
                            selectedChildCategoryId.value = null;
                            _fetchFilteredProducts();
                          },
                          child: ValueListenableBuilder<int?>(
                            valueListenable: selectedCategoryId,
                            builder: (_, id, __) {
                              return _CompactCategoryChip(
                                label: cat.name,
                                selected: id == cat.id,
                              );
                            },
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: snapshot.data!.length,
                    );
                  },
                ),
              ),
            ),

            /// SUB CATEGORIES
            ValueListenableBuilder<int?>(
              valueListenable: selectedCategoryId,
              builder: (_, catId, __) {
                if (catId == null) {
                  return const SliverToBoxAdapter(child: SizedBox());
                }

                return SliverToBoxAdapter(
                  child: FutureBuilder<List<CategoryModel>>(
                    future: CategoryService.fetchCategories(),
                    builder: (_, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      final category =
                      snapshot.data!.firstWhere((c) => c.id == catId);

                      if (category.subCategories.isEmpty) {
                        return const SizedBox();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.subdirectory_arrow_right,
                                    size: 16, color: cs.primary),
                                const SizedBox(width: 6),
                                Text(
                                  "Sub Categories",
                                  style: tt.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 36,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (_, i) {
                                final sub = category.subCategories[i];
                                return GestureDetector(
                                  onTap: () {
                                    selectedSubCategoryId.value = sub.id;
                                    selectedChildCategoryId.value = null;
                                    _fetchFilteredProducts();
                                  },
                                  child: ValueListenableBuilder<int?>(
                                    valueListenable: selectedSubCategoryId,
                                    builder: (_, id, __) {
                                      return _CompactCategoryChip(
                                        label: sub.name,
                                        selected: id == sub.id,
                                        isSecondary: true,
                                      );
                                    },
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemCount: category.subCategories.length,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),

            /// CHILD CATEGORIES
            ValueListenableBuilder<int?>(
              valueListenable: selectedSubCategoryId,
              builder: (_, subId, __) {
                if (subId == null) {
                  return const SliverToBoxAdapter(child: SizedBox());
                }

                return SliverToBoxAdapter(
                  child: FutureBuilder<List<CategoryModel>>(
                    future: CategoryService.fetchCategories(),
                    builder: (_, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      final sub = snapshot.data!
                          .expand((c) => c.subCategories)
                          .firstWhere((s) => s.id == subId);

                      if (sub.childCategories.isEmpty) {
                        return const SizedBox();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.arrow_right_alt,
                                    size: 16, color: cs.primary),
                                const SizedBox(width: 6),
                                Text(
                                  "Types",
                                  style: tt.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 34,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (_, i) {
                                final child = sub.childCategories[i];
                                return GestureDetector(
                                  onTap: () {
                                    selectedChildCategoryId.value = child.id;
                                    _fetchFilteredProducts();
                                  },
                                  child: ValueListenableBuilder<int?>(
                                    valueListenable: selectedChildCategoryId,
                                    builder: (_, id, __) {
                                      return _CompactCategoryChip(
                                        label: child.name,
                                        selected: id == child.id,
                                        isChild: true,
                                      );
                                    },
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemCount: sub.childCategories.length,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            /// PRODUCTS SECTION HEADER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 18, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      "Products",
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<List<ProductModel>>(
                      valueListenable: products,
                      builder: (_, list, __) {
                        return Text(
                          "${list.length} items",
                          style: tt.labelMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

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
                              Icon(Icons.inventory_2_outlined,
                                  size: 64, color: cs.onSurface.withOpacity(0.3)),
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
                          childAspectRatio: 0.75,
                        ),
                          delegate: SliverChildBuilderDelegate(
                                (_, i) => _ProductCardCompact(product: list[i]),
                            childCount: list.length > 6 ? 6 : list.length, // 👈 LIMIT
                          )
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
                    Icon(Icons.storefront, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      "Stores",
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),

            /// STORES LIST
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: FutureBuilder(
                  future: StoreService.fetchStores(),
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
                      return const Center(child: Text("No stores available"));
                    }

                    final stores = snapshot.data!;

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) => _StoreCard(store: stores[i]),
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
          final cat = categories.firstWhere((c) => c.id == selectedCategoryId.value);
          breadcrumb = cat.name;

          if (selectedSubCategoryId.value != null) {
            final sub = cat.subCategories
                .firstWhere((s) => s.id == selectedSubCategoryId.value);
            breadcrumb += " > ${sub.name}";

            if (selectedChildCategoryId.value != null) {
              final child = sub.childCategories
                  .firstWhere((c) => c.id == selectedChildCategoryId.value);
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
          banner.image,
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
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/banner_error.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// PRODUCT CARD COMPACT
/// ------------------------------
class _ProductCardCompact extends StatelessWidget {
  final ProductModel product;
  const _ProductCardCompact({required this.product});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(onTap: (){
      print("ghjkl");
      Navigator.push(context, MaterialPageRoute(builder: (context)=>ProductDetailScreen(productId: product.id
        ,)));
    },
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant, width: 1),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  "${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${product.image}",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: cs.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: cs.onSurface.withOpacity(0.3),
                    ),
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
                    style: tt.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${product.price}",
                    style: tt.bodyMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
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

/// ------------------------------
/// SHIMMERS
/// ------------------------------
class _PromoCardShimmer extends StatelessWidget {
  const _PromoCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _CategoryScrollShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: cs.surfaceContainerHighest,
        highlightColor: cs.surface,
        child: Container(
          height: 38,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemCount: 5,
    );
  }
}

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
class _StoreCard extends StatelessWidget {
  final StoreModel store;
  const _StoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(onTap: (){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoreDetailScreen(
            storeId: store!.id,
            storeName:store!.name,
          ),
        ),
      );
    },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LOGO
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: store.logo != null
                  ? Image.network(
                "${ApiService.ImagebaseUrl}/${ApiService.store_logo_URL}${store.logo}",
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 120,
                color: cs.surfaceContainerHighest,
                child: Icon(Icons.store,
                    size: 40, color: cs.onSurface.withOpacity(0.4)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.city,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 2),

                  Text(
                    store.description.toString(),
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        store.workingHours,
                        style: tt.labelSmall?.copyWith(color: cs.primary),
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
