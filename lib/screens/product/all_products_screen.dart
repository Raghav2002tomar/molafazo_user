import 'package:ecom/screens/product/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../services/api_service.dart';
import '../bottombar/controller/category_service.dart';
import '../bottombar/controller/product_services.dart';
import '../bottombar/model/category_model.dart';
import '../bottombar/model/product_model.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final ValueNotifier<int?> selectedCategoryId = ValueNotifier(null);
  final ValueNotifier<int?> selectedSubCategoryId = ValueNotifier(null);
  final ValueNotifier<int?> selectedChildCategoryId = ValueNotifier(null);

  final ValueNotifier<List<ProductModel>> products = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<List<CategoryModel>> categories = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _fetchProducts();
  }

  Future<void> _loadCategories() async {
    categories.value = await CategoryService.fetchCategories();
  }


  Future<void> _fetchProducts() async {
    try {
      isLoading.value = true;
      final result = await ProductService.fetchProducts(
        categoryId: selectedCategoryId.value,
        subCategoryId: selectedSubCategoryId.value,
        childCategoryId: selectedChildCategoryId.value,
      );
      products.value = result;
    } catch (_) {
      products.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  void _clearFilters() {
    selectedCategoryId.value = null;
    selectedSubCategoryId.value = null;
    selectedChildCategoryId.value = null;
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text("All Products")),
      body: CustomScrollView(
        slivers: [

          /// 🔹 MAIN CATEGORIES
          SliverToBoxAdapter(
            child: SizedBox(
              height: 80, // ✅ MUST be >= chip height

              child: FutureBuilder<List<CategoryModel>>(
                future: CategoryService.fetchCategories(),
                builder: (_, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final cat = snapshot.data![i];
                      return GestureDetector(
                        onTap: () {
                          selectedCategoryId.value = cat.id;
                          selectedSubCategoryId.value = null;
                          selectedChildCategoryId.value = null;
                          _fetchProducts();
                        },
                        child: ValueListenableBuilder<int?>(
                          valueListenable: selectedCategoryId,
                          builder: (_, id, __) {
                            return _CompactBigCategoryChip(
                              image: cat.image,
                              label: cat.name,
                              selected: id == cat.id,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          /// 🔹 SUB CATEGORIES
          ValueListenableBuilder<int?>(
            valueListenable: selectedCategoryId,
            builder: (_, catId, __) {
              if (catId == null) return const SliverToBoxAdapter(child: SizedBox());

              return ValueListenableBuilder<List<CategoryModel>>(
                valueListenable: categories,
                builder: (_, cats, __) {
                  final category = cats.firstWhere((c) => c.id == catId);

                  if (category.subCategories.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox());
                  }

                  return SliverToBoxAdapter(
                    child: Column(
                      children: [
                SizedBox(height: 8,),
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: category.subCategories.length,
                            itemBuilder: (_, i) {
                              final sub = category.subCategories[i];
                              return GestureDetector(
                                onTap: () {
                                  selectedSubCategoryId.value = sub.id;
                                  selectedChildCategoryId.value = null;
                                  _fetchProducts();
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
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          /// 🔹 CHILD CATEGORIES
          ValueListenableBuilder<int?>(
            valueListenable: selectedSubCategoryId,
            builder: (_, subId, __) {
              if (subId == null) return const SliverToBoxAdapter(child: SizedBox());

              return ValueListenableBuilder<List<CategoryModel>>(
                valueListenable: categories,
                builder: (_, cats, __) {
                  final sub = cats
                      .expand((c) => c.subCategories)
                      .firstWhere((s) => s.id == subId);

                  if (sub.childCategories.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox());
                  }

                  return SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(height: 8,),
                        SizedBox(
                          height: 34,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: sub.childCategories.length,
                            itemBuilder: (_, i) {
                              final child = sub.childCategories[i];
                              return GestureDetector(
                                onTap: () {
                                  selectedChildCategoryId.value = child.id;
                                  _fetchProducts();
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
                            separatorBuilder: (_, __) => const SizedBox(width: 6),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          /// 🔹 CLEAR FILTER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ClearFilterButton(onClear: _clearFilters),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          /// 🔹 PRODUCTS GRID
          ValueListenableBuilder<bool>(
            valueListenable: isLoading,
            builder: (_, loading, __) {
              if (loading) return const _ProductGridShimmer();

              return ValueListenableBuilder<List<ProductModel>>(
                valueListenable: products,
                builder: (_, list, __) {
                  if (list.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(child: Text("No products found")),
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
                        childCount: list.length,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 16),
            sliver: SliverToBoxAdapter(child: SizedBox()),
          ),
        ],
      ),
    );
  }
}

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
      width: 80,        // ✅ narrower
      height: 70,      // ✅ taller
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
              height: 40,
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
                fontWeight:
                selected ? FontWeight.w700 : FontWeight.w600,
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
