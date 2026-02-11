import 'package:ecom/screens/product/product_details_screen.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'controller/store_detil_service.dart';
import 'model/store_detail.dart';


class StoreDetailScreen extends StatefulWidget {
  final int storeId;
  final String? storeName;

  const StoreDetailScreen({
    Key? key,
    required this.storeId,
    this.storeName,
  }) : super(key: key);

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  StoreDetailResponse? _cachedStoreData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await StoreDetailService.fetchStoreDetail(widget.storeId);

      setState(() {
        _cachedStoreData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? cs.surface : Colors.grey[100],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: cs.primary),
              const SizedBox(height: 16),
              Text(
                'Loading store details...',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _cachedStoreData == null) {
      return _buildErrorState(context);
    }

    final store = _cachedStoreData!.data.store;
    final products = _cachedStoreData!.data.products;

    return Scaffold(
      backgroundColor: isDark ? cs.surface : Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // Store Header with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: cs.surface,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(6.0),
              child: _CircleAction(
                icon: Icons.keyboard_double_arrow_left_outlined,
                bg: isDark ? Colors.white : Colors.black,
                fg: isDark ? Colors.black : Colors.white,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              _CircleAction(
                icon: Icons.share_outlined,
                bg: isDark ? Colors.white : Colors.black,
                fg: isDark ? Colors.black : Colors.white,
                onTap: () {},
              ),
              const SizedBox(width: 6),
              _CircleAction(
                icon: Icons.favorite_border,
                bg: isDark ? Colors.white : Colors.black,
                fg: isDark ? Colors.black : Colors.white,
                onTap: () {},
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Image.network(
                    "https://wallpapers.com/images/featured/grocery-store-background-c41zd4y08ityrnw1.jpg",
                    fit: BoxFit.cover,
                  ),

                  // Gradient overlay to make logo readable
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          cs.primaryContainer.withOpacity(0.3),
                          cs.surface.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),

                  // Center logo
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      margin: const EdgeInsets.only(top: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: store.logo.isNotEmpty
                            ? Image.network(
                          '${ApiService.ImagebaseUrl}/${ApiService.store_logo_URL}${store.logo}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.store,
                            size: 60,
                            color: cs.primary,
                          ),
                        )
                            : Icon(
                          Icons.store,
                          size: 60,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Store Information
          SliverToBoxAdapter(
            child: Container(
              color: cs.surface,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Name
                  Text(
                    store.name,
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Store Type Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cs.primary, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              store.type == 1 ? Icons.store : Icons.shopping_bag,
                              size: 14,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              store.type == 1 ? 'Physical Store' : 'Online Store',
                              style: tt.bodySmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.access_time,
                          title: 'Working Hours',
                          value: store.workingHours,
                          cs: cs,
                          tt: tt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.inventory_2_outlined,
                          title: 'Products',
                          value: '${products.length} items',
                          cs: cs,
                          tt: tt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Delivery Options
                  Row(
                    children: [
                      if (store.deliveryBySeller == 1)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? cs.surfaceVariant
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_shipping,
                                    size: 16, color: Colors.green.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  'Home Delivery',
                                  style: tt.bodySmall?.copyWith(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (store.deliveryBySeller == 1 && store.selfPickup == 1)
                        const SizedBox(width: 8),
                      if (store.selfPickup == 1)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? cs.surfaceVariant
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.store_outlined,
                                    size: 16, color: Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  'Self Pickup',
                                  style: tt.bodySmall?.copyWith(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  if (store.description.isNotEmpty) ...[
                    Text(
                      'About Store',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      store.description,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Contact Information
                  Text(
                    'Contact Information',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ContactRow(
                    icon: Icons.location_on_outlined,
                    text: '${store.address}, ${store.city}, ${store.country}',
                    cs: cs,
                    tt: tt,
                  ),
                  const SizedBox(height: 8),
                  _ContactRow(
                    icon: Icons.phone_outlined,
                    text: store.mobile,
                    cs: cs,
                    tt: tt,
                  ),
                  const SizedBox(height: 8),
                  _ContactRow(
                    icon: Icons.email_outlined,
                    text: store.email,
                    cs: cs,
                    tt: tt,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Products Section Header
          SliverToBoxAdapter(
            child: Container(
              color: cs.surface,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Store Products',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${products.length} items',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Products Grid
          if (products.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: cs.surface,
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
                      'No products available',
                      style: tt.bodyLarge?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                      (_, i) => _StoreProductCard(
                    product: products[i],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            productId: products[i].id,
                          ),
                        ),
                      );
                    },
                  ),
                  childCount: products.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: cs.error),
              const SizedBox(height: 16),
              Text(
                'Error Loading Store',
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadStoreData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circle Action Button
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: fg, size: 20),
        ),
      ),
    );
  }
}

/// Info Card Widget
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final ColorScheme cs;
  final TextTheme tt;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Contact Row Widget
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;
  final TextTheme tt;

  const _ContactRow({
    required this.icon,
    required this.text,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Store Product Card
class _StoreProductCard extends StatelessWidget {
  final StoreProduct product;
  final VoidCallback onTap;

  const _StoreProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final hasDiscount = product.discountPrice != "0.00" &&
        double.parse(product.discountPrice) < double.parse(product.price);

    return GestureDetector(
      onTap: onTap,
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
            // Product Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      '${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${product.primaryImage}',
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
                  // Stock Badge
                  if (product.availableQuantity == 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Out of Stock',
                          style: tt.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product Info
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
                  Row(
                    children: [
                      Text(
                        '₹${hasDiscount ? product.discountPrice : product.price}',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${product.price}',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 10,
                          ),
                        ),
                      ],
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