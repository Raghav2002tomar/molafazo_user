import 'package:ecom/extensions/context_extension.dart';
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
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen())
        );
      }
      return;
    }

    setState(() {
      _isLoading = false;

      // Check if the response has data and items
      if (result['data'] != null) {
        _cartData = CartResponse.fromJson(result);
        _errorMessage = null;
      } else {
        // This handles the "Cart is empty" case
        _cartData = null;
        _errorMessage = result['message'] ?? context.tr('txt_cart_empty');
      }
    });
  }
  Future<void> _updateQuantity(int cartItemId, int newQuantity) async {
    if (newQuantity < 1) {
      // Remove item if quantity is 0
      _removeItem(cartItemId);
      await context.read<CartProvider>().refreshCart();

      return;
    }

    final result = await CartService.updateCartItem(
      cartItemId: cartItemId,
      quantity: newQuantity,
    );

    if (result['status'] == true) {
      context.read<CartProvider>().refreshCart(); // update bottom badge
      _loadCart();
// Reload cart
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? context.tr('txt_failed_to_update')),
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
      context.read<CartProvider>().refreshCart(); // update bottom badge
      _loadCart(); // Reload cart
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('txt_item_removed_cart')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? context.tr('txt_failed_to_remove')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
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
        title: Text(
          context.tr('txt_my_cart'),
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!_isLoading && _cartData?.data != null && _cartData!.data!.items.isNotEmpty)
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
          : _cartData?.data?.items.isEmpty ?? true
          ? _buildEmptyCart()  // Show empty cart
          : _buildCartContent(), // Show cart content
    );
  }
  Widget _buildEmptyCart() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated empty cart illustration
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 1500),
                tween: Tween<double>(begin: 0.8, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, double scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            cs.primary.withOpacity(0.2),
                            cs.primary.withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 80,
                            color: cs.primary.withOpacity(0.3),
                          ),
                          Positioned(
                            right: 40,
                            top: 40,
                            child: TweenAnimationBuilder(
                              duration: const Duration(milliseconds: 2000),
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              curve: Curves.bounceOut,
                              builder: (context, double value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, -20 * (1 - value)),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: cs.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.remove_shopping_cart,
                                        color: Colors.white,
                                        size: 24,
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
                  );
                },
              ),

              const SizedBox(height: 32),

              // Empty cart message
              Text(
                context.tr('txt_your_cart_is_empty'),
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                  fontSize: 24,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                context.tr('txt_cart_description'),
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),



              // Continue shopping button
              // SizedBox(
              //   width: double.infinity,
              //   height: 56,
              //   child: ElevatedButton(
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: isDark ? Colors.white : Colors.black,
              //       foregroundColor: isDark ? Colors.black : Colors.white,
              //       elevation: 0,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(28),
              //       ),
              //     ),
              //     onPressed: () {},
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         const Text(
              //           'Continue Shopping',
              //           style: TextStyle(
              //             fontSize: 16,
              //             fontWeight: FontWeight.w600,
              //           ),
              //         ),
              //
              //       ],
              //     ),
              //   ),
              // ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
      }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        // Navigate to respective category
        // You can implement navigation based on the label
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
              context.tr('txt_error_loading_cart'),
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? context.tr('txt_something_went_wrong'),
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCart,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('txt_retry')),
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
                onDismissed: (direction) async {

                  final removedItem = cartData.items[index];

                  setState(() {
                    cartData.items.removeAt(index);
                  });

                  final result = await CartService.removeFromCart(removedItem.id);

                  if (result['status'] == true) {
                    await context.read<CartProvider>().refreshCart(); // update badge
                    _loadCart();
                  } else {
                    _loadCart(); // restore if API failed
                  }
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
                      '${context.tr('txt_total')} (${cartData.items.length} ${context.tr('txt_item')}${cartData.items.length > 1 ? 's' : ''}):',
                      style: TextStyle(
                        fontSize: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${cartData.cartTotalAmount.toInt()} c.',
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
                         Text(
                          context.tr('txt_proceed_to_checkout'),
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
        title: Text(context.tr('txt_remove_item')),
        content: Text(
          context.tr('txt_sure_remove'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('txt_cancel'), style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(context.tr('txt_remove')),
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

    // Get the price from the selected combination or product
    final double itemPrice = cartItem.selectedCombination != null
        ? double.parse(cartItem.selectedCombination!.price)
        : cartItem.product.getDisplayPrice();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
                // Product Name
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

                // Combination/Variant Details
                if (cartItem.selectedCombination != null &&
                    cartItem.selectedCombination!.variant.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cartItem.selectedCombination!.displayVariant,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Store Name
                Row(
                  children: [
                    Icon(Icons.store, size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        cartItem.product.store!.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Price and Quantity Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${itemPrice.toInt()} c.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                        // Original price if discounted
                        if (cartItem.selectedCombination != null) ...[
                          // No need for original price here as combination already has discounted price
                        ] else if (double.parse(cartItem.product.discountPrice) > 0 &&
                            double.parse(cartItem.product.discountPrice) <
                                double.parse(cartItem.product.price))
                          Text(
                            '${double.parse(cartItem.product.price).toInt()} c.',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        // Subtotal
                        Text(
                          '${context.tr('txt_subtotal')}: ${(itemPrice * cartItem.quantity).toInt()} c.',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    // Quantity Controls
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
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
                              size: 18,
                              color: cs.onSurface,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              cartItem.quantity.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
                              size: 18,
                              color: cs.onSurface,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
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
