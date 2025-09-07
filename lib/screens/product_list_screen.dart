import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/translate_provider.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<CartProvider>().loadCartItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.watch<TranslateProvider>().t('checkout'),
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        backgroundColor: cs.surface,
        elevation: 1,
        shadowColor: cs.shadow.withOpacity(0.04),
        actions: [
          PopupMenuButton<String>(
            onSelected: (lang) {
              context.read<TranslateProvider>().setLocale(lang);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'ru', child: Text('Русский')),
              const PopupMenuItem(value: 'tg', child: Text('Тоҷикӣ')),
            ],
            icon: const Icon(Icons.language),
          ),
          IconButton(
            tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
            icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined),
            onPressed: () => context.read<ThemeProvider>().toggle(),
            color: cs.onSurfaceVariant,
          ),
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              final hasItems = cart.itemCount > 0;
              return Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                height: 40,
                width: 50,
                decoration: BoxDecoration(
                  color: hasItems ? cs.primary : cs.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: hasItems ? cs.primary : cs.outlineVariant,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: IconButton(
                        icon: Icon(
                          Icons.shopping_cart_outlined,
                          size: 22,
                          color: hasItems ? cs.onPrimary : cs.onSurfaceVariant,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CartScreen()),
                          );
                        },
                      ),
                    ),
                    if (hasItems)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: cs.tertiary,
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '${cart.itemCount}',
                            style: textTheme.labelSmall?.copyWith(
                              color: cs.onTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productProvider.error != null) {
            return Center(
              child: Text(
                'Something went wrong\n${productProvider.error!}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (productProvider.products.isEmpty) {
            return const Center(
              child: Text('No products found'),
            );
          }

          return CustomScrollView(
            slivers: [
              // 🔍 Search Bar
              SliverToBoxAdapter(
                child: Container(
                  color: cs.surface,
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cs.outlineVariant, width: 0.8),
                    ),
                    child: TextField(
                      style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search ShopEase',
                        hintStyle: textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ),
              ),

              // 🛒 Product Grid with ProductCard
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => ProductCard(product: productProvider.products[index]),
                    childCount: productProvider.products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.70,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
