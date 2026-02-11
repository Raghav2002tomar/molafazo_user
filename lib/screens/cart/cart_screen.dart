import 'package:ecom/screens/auth/LoginScreen.dart';
import 'package:ecom/screens/cart/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import 'controller/cart_services.dart';
import 'model/cart_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = true;
  CartResponse? _cartData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await CartService.getCartList();

    if (result['requiresLogin'] == true) {
      // User not logged in, redirect to login
      if (mounted) {
        // Navigator.pushReplacementNamed(context, '/login');
        Navigator.push(context, MaterialPageRoute(builder: (context)=> AuthScreen()));
      }
      return;
    }

    setState(() {
      _isLoading = false;
      if (result['status'] == true) {
        _cartData = CartResponse.fromJson(result);
      } else {
        _errorMessage = result['message'] ?? 'Failed to load cart';
      }
    });
  }

  Future<void> _updateQuantity(int cartItemId, int newQuantity) async {
    if (newQuantity < 1) {
      // Remove item if quantity is 0
      _removeItem(cartItemId);
      return;
    }

    final result = await CartService.updateCartItem(
      cartItemId: cartItemId,
      quantity: newQuantity,
    );

    if (result['status'] == true) {
      _loadCart(); // Reload cart
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update quantity'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeItem(int cartItemId) async {
    final confirmed = await _showDeleteConfirmation(context);
    if (confirmed != true) return;

    final result = await CartService.removeFromCart(cartItemId);

    if (result['status'] == true) {
      _loadCart(); // Reload cart
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item removed from cart'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to remove item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        // leading: Padding(
        //   padding: const EdgeInsets.all(6.0),
        //   child: _CircleAction(
        //     icon: Icons.keyboard_double_arrow_left_outlined,
        //     bg: isDark ? Colors.white : Colors.black,
        //     fg: isDark ? Colors.black : Colors.white,
        //     onTap: () => Navigator.pop(context),
        //   ),
        // ),
        title: Text(
          'My Cart',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isLoading && _cartData?.data != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.outline, width: 0.5),
                ),
                child: IconButton(
                  icon: Stack(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: cs.onSurface,
                        size: 20,
                      ),
                      if (_cartData!.data!.items.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${_cartData!.data!.items.length}',
                              style: TextStyle(
                                color: cs.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {},
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _errorMessage != null
          ? _buildErrorState()
          : _cartData?.data?.items.isEmpty ?? true
          ? _buildEmptyCart()
          : _buildCartContent(),
    );
  }

  Widget _buildEmptyCart() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text('Continue Shopping'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Error Loading Cart',
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCart,
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
    );
  }

  Widget _buildCartContent() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartData = _cartData!.data!;

    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: cartData.items.length,
            itemBuilder: (context, index) {
              final item = cartData.items[index];
              return Dismissible(
                key: Key(item.id.toString()),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await _showDeleteConfirmation(context);
                },
                onDismissed: (direction) {
                  _removeItem(item.id);
                },
                background: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(
                    Icons.delete_outline,
                    color: isDark ? Colors.black : Colors.white,
                    size: 24,
                  ),
                ),
                child: _CartItemCard(
                  cartItem: item,
                  onQuantityChanged: (newQty) {
                    _updateQuantity(item.id, newQty);
                  },
                ),
              );
            },
          ),
        ),

        // Bottom Checkout Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total (${cartData.items.length} item${cartData.items.length > 1 ? 's' : ''}):',
                      style: TextStyle(
                        fontSize: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '₹${cartData.cartTotalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final cart = context.read<CartProvider>();
                      await cart.refreshCart(); // 🔥 IMPORTANT

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckoutScreen(),
                          ),
                        );
                      }
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? cs.onPrimary : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.double_arrow_sharp,
                            size: 16,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Item'),
        content: const Text(
          'Are you sure you want to remove this item from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem cartItem;
  final Function(int) onQuantityChanged;

  const _CartItemCard({
    required this.cartItem,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 5,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                '${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${cartItem.product.primaryImage}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.image_not_supported, color: cs.onSurfaceVariant),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.product.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Product ID: ${cartItem.product.id}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${cartItem.product.getDisplayPrice().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                        if (double.parse(cartItem.product.discountPrice) > 0 &&
                            double.parse(cartItem.product.discountPrice) <
                                double.parse(cartItem.product.price))
                          Text(
                            '₹${cartItem.product.price}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    // Quantity Controls
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              onQuantityChanged(cartItem.quantity - 1);
                            },
                            icon: Icon(
                              Icons.remove,
                              size: 16,
                              color: cs.onSurface,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              cartItem.quantity.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              onQuantityChanged(cartItem.quantity + 1);
                            },
                            icon: Icon(
                              Icons.add,
                              size: 16,
                              color: cs.onSurface,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
