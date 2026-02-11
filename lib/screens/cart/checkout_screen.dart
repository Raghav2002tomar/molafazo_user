import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart' hide CartItem;
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../address/address_list_screen.dart';
import '../address/model/address_model.dart';
import '../bottombar/MainScreen.dart';
import 'controller/order_services.dart';
import 'model/cart_model.dart';


class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = 'cod';
  String _deliveryMethod = 'home_delivery';
  AddressModel? _selectedAddress;
  bool _isPlacingOrder = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? cs.surface : Colors.grey[100],
      appBar: AppBar(
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
        title: Text(
          "Checkout",
          style: tt.titleMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.cartData == null ||
              cartProvider.cartData!.data == null ||
              cartProvider.cartData!.data!.items.isEmpty) {
            return _buildEmptyCart(context, cs, tt);
          }

          final cartData = cartProvider.cartData!.data!;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // Delivery Address
                      _buildDeliveryAddressCard(context, cs, tt),

                      const SizedBox(height: 16),

                      // Delivery Method
                      _buildDeliveryMethodCard(context, cs, tt),

                      const SizedBox(height: 16),

                      // Product Items
                      _buildProductItemsCard(context, cs, tt, cartData.items),

                      const SizedBox(height: 16),

                      // Order Summary
                      _buildOrderSummaryCard(context, cs, tt, cartData),

                      const SizedBox(height: 16),

                      // Payment Method
                      _buildPaymentMethodCard(context, cs, tt),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildCheckoutBottomBar(context, cs, tt, isDark),
    );
  }

  Widget _buildEmptyCart(BuildContext context, ColorScheme cs, TextTheme tt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to proceed to checkout',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard(BuildContext context, ColorScheme cs, TextTheme tt) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: cs.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery Address',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  final selected = await Navigator.push<AddressModel>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddressListScreen(
                        isSelectionMode: true,
                        selectedAddress: _selectedAddress,
                      ),
                    ),
                  );
                  if (selected != null) {
                    setState(() {
                      _selectedAddress = selected;
                    });
                  }
                },
                child: Text(
                  _selectedAddress == null ? 'Select' : 'Change',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_selectedAddress != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _selectedAddress!.name,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      if (_selectedAddress!.isDefault)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Default",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedAddress!.fullName,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedAddress!.mobile,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${_selectedAddress!.address}, ${_selectedAddress!.city}, ${_selectedAddress!.state} - ${_selectedAddress!.pincode}",
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.error.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: cs.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please select a delivery address',
                      style: tt.bodyMedium?.copyWith(color: cs.error),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryMethodCard(BuildContext context, ColorScheme cs, TextTheme tt) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Method',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildDeliveryOption(
            title: 'Home Delivery',
            subtitle: 'Deliver to your doorstep',
            icon: Icons.home_outlined,
            value: 'home_delivery',
            cs: cs,
            tt: tt,
          ),
          const SizedBox(height: 12),
          _buildDeliveryOption(
            title: 'Store Pickup',
            subtitle: 'Pickup from nearest store',
            icon: Icons.store_outlined,
            value: 'store_pickup',
            cs: cs,
            tt: tt,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    final isSelected = _deliveryMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _deliveryMethod = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? cs.primaryContainer.withOpacity(0.2) : cs.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: cs.onSurface, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _deliveryMethod,
              onChanged: (val) => setState(() => _deliveryMethod = val!),
              activeColor: cs.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItemsCard(
      BuildContext context,
      ColorScheme cs,
      TextTheme tt,
      List<CartItem> items,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Items',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                '${items.length} item${items.length > 1 ? 's' : ''}',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildProductItem(item, cs, tt)).toList(),
        ],
      ),
    );
  }

  Widget _buildProductItem(CartItem item, ColorScheme cs, TextTheme tt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                '${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${item.product.primaryImage}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.product.getDisplayPrice().toStringAsFixed(2)}',
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                'Total: ₹${item.itemTotal.toStringAsFixed(2)}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(
      BuildContext context,
      ColorScheme cs,
      TextTheme tt,
      CartData cartData,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow(
            'Subtotal',
            '₹${cartData.cartTotalAmount.toStringAsFixed(2)}',
            cs,
            tt,
          ),
          _buildPriceRow('Delivery', 'FREE', cs, tt, isGreen: true),
          _buildPriceRow('Service Fee', 'FREE', cs, tt, isGreen: true),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                '₹${cartData.cartTotalAmount.toStringAsFixed(2)}',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
      String label,
      String value,
      ColorScheme cs,
      TextTheme tt, {
        bool isGreen = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          Text(
            value,
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isGreen ? Colors.green : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(BuildContext context, ColorScheme cs, TextTheme tt) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // COD
          _buildPaymentOption(
            title: 'Cash on Delivery',
            subtitle: 'Pay when you receive',
            icon: Icons.local_shipping_outlined,
            value: 'cod',
            cs: cs,
            tt: tt,
          ),
          const SizedBox(height: 12),

          // Online
          _buildPaymentOption(
            title: 'Pay Online',
            subtitle: 'UPI, Cards, Net Banking',
            icon: Icons.credit_card_outlined,
            value: 'online',
            cs: cs,
            tt: tt,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    final isSelected = _selectedPayment == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? cs.primaryContainer.withOpacity(0.2) : cs.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: cs.onSurface, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPayment,
              onChanged: (val) => setState(() => _selectedPayment = val!),
              activeColor: cs.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBottomBar(
      BuildContext context,
      ColorScheme cs,
      TextTheme tt,
      bool isDark,
      ) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final total = cart.cartData?.data?.cartTotalAmount ?? 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_selectedAddress != null && !_isPlacingOrder)
                        ? () => _placeOrder(context, cart)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      disabledBackgroundColor: cs.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isPlacingOrder
                        ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    )
                        : Text(
                      _selectedPayment == 'cod'
                          ? 'Place Order'
                          : 'Proceed to Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final result = await OrderService.placeOrder(
        addressId: _selectedAddress!.id,
        deliveryMethod: _deliveryMethod,
        paymentType: _selectedPayment,
      );

      setState(() {
        _isPlacingOrder = false;
      });

      if (result['status'] == true) {
        await cart.refreshCart();

        if (mounted) {
          _showOrderSuccessDialog(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to place order'),
              backgroundColor: Colors.red,
            ),
          );

          // 👇 GO BACK TO DASHBOARD (NO LOGOUT)
          if (result['goHome'] == true) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      }

    } catch (e) {
      setState(() {
        _isPlacingOrder = false;
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

  void _showOrderSuccessDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(Icons.check, color: Colors.green.shade700, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Order Placed Successfully!',
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you for your order. You will receive a confirmation shortly.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,

            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>SimpleBottomNavScreen()));
                  // Navigator.of(context).popUntil((route) => route.isFirst); // Go to home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue Shopping',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
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