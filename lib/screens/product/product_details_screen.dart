import 'package:ecom/screens/cart/cart_screen.dart';
import 'package:ecom/screens/product/store_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../providers/cart_provider.dart';
import '../cart/controller/cart_services.dart';
import 'controller/product_detail_services.dart';
import 'model/Product_Detail_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  String? selectedSize;
  String? selectedColor;
  int selectedImageIndex = 0;
  bool _isAddingToCart = false;

  // Cache the product data to avoid reloading
  ProductDetailResponse? _cachedProductData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await ProductDetailService.fetchProductDetail(widget.productId);

      setState(() {
        _cachedProductData = data;
        _isLoading = false;

        // Initialize selected size and color from API data
        final productData = data.data;
        if (selectedSize == null && productData.attributesJson?.size.isNotEmpty == true) {
          selectedSize = productData.attributesJson!.size.first;
        }
        if (selectedColor == null && productData.attributesJson?.color.isNotEmpty == true) {
          selectedColor = productData.attributesJson!.color.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _handleAddToCart(ProductDetail product) async {
    // Check if user is logged in
    final isLoggedIn = await AuthStorage.isLoggedIn();

    if (!isLoggedIn) {
      // Show login dialog
      _showLoginDialog();
      return;
    }

    // Show loading
    setState(() {
      _isAddingToCart = true;
    });

    try {
      // Call API to add to cart
      final result = await CartService.addToCart(
        productId: product.id,
        quantity: quantity,
      );

      setState(() {
        _isAddingToCart = false;
      });

      if (result['status'] == true) {
        // Update cart count in provider
        if (mounted) {
          context.read<CartProvider>().fetchCartCount();
        }

        // Success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result['message'] ?? '${product.name} added to cart',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: SnackBarAction(
                label: 'VIEW CART',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to cart screen
                  // Navigator.pushNamed(context, '/cart');
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>CartScreen()));
                },
              ),
            ),
          );
        }
      } else {
        // Error
        if (result['requiresLogin'] == true) {
          _showLoginDialog();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to add to cart'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isAddingToCart = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showLoginDialog() {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.login, color: cs.primary),
            const SizedBox(width: 12),
            const Text('Login Required'),
          ],
        ),
        content: const Text(
          'Please login to add items to your cart and continue shopping.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _buildLoadingState(context);
    }

    if (_errorMessage != null || _cachedProductData == null) {
      return _buildErrorState(context, _errorMessage ?? 'No product data available');
    }

    final productData = _cachedProductData!.data;
    final relatedProducts = _cachedProductData!.relatedProducts;

    return Scaffold(
      backgroundColor: isDark ? cs.surface : Colors.grey[100],
      body: _buildProductDetail(context, productData, relatedProducts),
      bottomNavigationBar: _buildBottomBar(context, productData, isDark),
    );
  }

  Widget _buildProductDetail(
      BuildContext context,
      ProductDetail product,
      List<RelatedProduct> relatedProducts,
      ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get current image URL
    final currentImage = product.images.isNotEmpty
        ? product.images[selectedImageIndex].image
        : product.primaryImage;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: MediaQuery.of(context).size.height * 0.45,
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
            // Cart icon with badge
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: _CartIconWithBadge(
                isDark: isDark,
                onTap: () {
                  // Navigator.pushNamed(context, '/cart');
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>CartScreen()));
                },
              ),
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
            background: Container(
              color: isDark ? cs.surface : Colors.grey[100],
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Hero(
                        tag: 'product-${product.id}',
                        child: Image.network(
                          '${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}$currentImage',
                          fit: BoxFit.cover,
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_not_supported,
                            size: 80,
                            color: cs.onSurface.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Image thumbnails
                  if (product.images.length > 1)
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: product.images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final isSelected = i == selectedImageIndex;
                          return GestureDetector(
                            onTap: () => setState(() => selectedImageIndex = i),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected ? cs.primary : cs.outlineVariant,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.network(
                                  '${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${product.images[i].image}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image,
                                    size: 20,
                                    color: cs.onSurface.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Content section
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + qty
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (product.category != null)
                              Text(
                                product.category!.name,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _QtyPill(
                        onMinus: quantity > 1 ? () => setState(() => quantity--) : null,
                        onPlus: () => setState(() => quantity++),
                        quantity: quantity,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stock status and store info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (product.store != null)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.store_outlined, size: 16, color: cs.primary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  product.store!.name,
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: product.availableQuantity > 0
                              ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50)
                              : (isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: product.availableQuantity > 0 ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          product.availableQuantity > 0
                              ? 'In Stock (${product.availableQuantity})'
                              : 'Out of Stock',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: product.availableQuantity > 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Delivery info
                  if (product.deliveryAvailable == 1)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? cs.surfaceVariant : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? cs.outlineVariant : Colors.blue.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 20, color: cs.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery Available',
                                  style: tt.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                                Text(
                                  '₹${product.deliveryPrice} • ${product.deliveryTime}',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Size and Color selection
                  if (product.attributesJson != null)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Size
                            if (product.attributesJson!.size.isNotEmpty)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Size',
                                      style: tt.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _SizeRow(
                                      sizes: product.attributesJson!.size,
                                      selected: selectedSize ?? '',
                                      onSelect: (s) => setState(() => selectedSize = s),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(width: 20),
                            // Color
                            if (product.attributesJson!.color.isNotEmpty)
                              _ColorSelection(
                                colors: product.attributesJson!.color,
                                selected: selectedColor ?? '',
                                onChanged: (c) => setState(() => selectedColor = c),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Description
                  Text(
                    'Description',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (product.store != null)
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Navigate to store detail screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StoreDetailScreen(
                                    storeId: product.store!.id,
                                    storeName: product.store!.name,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: cs.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.store_outlined,
                                      size: 16, color: cs.primary),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      product.store!.name,
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios,
                                      size: 10, color: cs.primary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: product.availableQuantity > 0
                              ? (isDark
                              ? Colors.green.withOpacity(0.2)
                              : Colors.green.shade50)
                              : (isDark
                              ? Colors.red.withOpacity(0.2)
                              : Colors.red.shade50),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: product.availableQuantity > 0
                                ? Colors.green
                                : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          product.availableQuantity > 0
                              ? 'In Stock (${product.availableQuantity})'
                              : 'Out of Stock',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: product.availableQuantity > 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8,),

                  // Related Products
                  if (relatedProducts.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Related Products',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          '${relatedProducts.length} items',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: relatedProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => _RelatedProductCard(
                          product: relatedProducts[i],
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  productId: relatedProducts[i].id,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), // Add space for bottom bar
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, ProductDetail product, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final hasDiscount = double.parse(product.discountPrice) > 0 &&
        double.parse(product.discountPrice) < double.parse(product.price);
    final displayPrice = hasDiscount
        ? double.parse(product.discountPrice)
        : double.parse(product.price);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Price',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '₹${(displayPrice * quantity).toStringAsFixed(2)}',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text(
                        '₹${(double.parse(product.price) * quantity).toStringAsFixed(2)}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: (product.availableQuantity > 0 && !_isAddingToCart)
                      ? () => _handleAddToCart(product)
                      : null,
                  icon: _isAddingToCart
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  )
                      : Icon(
                    Icons.shopping_bag_outlined,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                  label: Text(
                    _isAddingToCart ? 'Adding...' : 'Add to Cart',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    disabledBackgroundColor: cs.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
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

  Widget _buildLoadingState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? cs.surface : Colors.grey[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'Loading product details...',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
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
              Icon(
                Icons.error_outline,
                size: 80,
                color: cs.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Product',
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadProductData(),
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

/// Cart Icon with Badge
class _CartIconWithBadge extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _CartIconWithBadge({
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: isDark ? Colors.black : Colors.white,
                      size: 20,
                    ),
                  ),
                  if (cartProvider.cartCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${cartProvider.cartCount > 99 ? '99+' : cartProvider.cartCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Circle floating action used on image
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

/// Quantity stepper pill
class _QtyPill extends StatelessWidget {
  final VoidCallback? onMinus;
  final VoidCallback onPlus;
  final int quantity;
  const _QtyPill({
    required this.onMinus,
    required this.onPlus,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.remove,
              color: onMinus != null ? cs.onSurface : cs.onSurface.withOpacity(0.3),
              size: 18,
            ),
            onPressed: onMinus,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.add, color: cs.onSurface, size: 18),
            onPressed: onPlus,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

/// Size choices row
class _SizeRow extends StatelessWidget {
  final List<String> sizes;
  final String selected;
  final ValueChanged<String> onSelect;

  const _SizeRow({
    required this.sizes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: sizes.map((s) {
        final isSel = s == selected;

        return GestureDetector(
          onTap: () => onSelect(s),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSel
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? cs.surfaceVariant : cs.surface),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSel
                    ? (isDark ? Colors.white : Colors.black)
                    : cs.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Text(
              s,
              style: TextStyle(
                color: isSel
                    ? (isDark ? Colors.black : Colors.white)
                    : cs.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Color selection widget
class _ColorSelection extends StatelessWidget {
  final List<String> colors;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ColorSelection({
    required this.colors,
    required this.selected,
    required this.onChanged,
  });

  Color _parseColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: colors.map((c) {
            final isSel = c == selected;
            final color = _parseColor(c);

            return GestureDetector(
              onTap: () => onChanged(c),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSel ? cs.primary : cs.outlineVariant,
                    width: isSel ? 3 : 1.5,
                  ),
                ),
                child: isSel
                    ? Icon(
                  Icons.check,
                  size: 16,
                  color: color == Colors.white || color == Colors.yellow
                      ? Colors.black
                      : Colors.white,
                )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Related Product Card
class _RelatedProductCard extends StatelessWidget {
  final RelatedProduct product;
  final VoidCallback onTap;

  const _RelatedProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
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
                    '₹${product.discountPrice != "0.00" && double.parse(product.discountPrice) < double.parse(product.price) ? product.discountPrice : product.price}',
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