// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
//
// import '../../models/cart_item.dart' hide CartItem;
// import '../../providers/cart_provider.dart';
// import '../../services/api_service.dart';
// import '../address/address_list_screen.dart';
// import '../address/model/address_model.dart';
// import '../bottombar/MainScreen.dart';
// import 'controller/order_services.dart';
// import 'model/cart_model.dart';
//
// class CheckoutScreen extends StatefulWidget {
//   const CheckoutScreen({super.key});
//
//   @override
//   State<CheckoutScreen> createState() => _CheckoutScreenState();
// }
//
// class _CheckoutScreenState extends State<CheckoutScreen> {
//   String _selectedPayment = 'cod';
//   String _deliveryMethod = 'home_delivery';
//   AddressModel? _selectedAddress;
//   bool _isPlacingOrder = false;
//
//   // Payment mode flags
//   bool _hasCodPayment = false;
//   bool _hasBankPayment = false;
//
//   // Selected bank details for bank payment
//   Map<String, dynamic>? _selectedBankDetails;
//
//   // Store all available payment modes from cart items
//   Set<String> _availablePaymentModes = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _extractPaymentModes();
//   }
//
//   void _extractPaymentModes() {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//     final cartData = cartProvider.cartData?.data;
//
//     if (cartData != null) {
//       Set<String> paymentModes = {};
//
//       for (var item in cartData.items) {
//         if (item.product.store?.user?.paymentModes != null) {
//           paymentModes.addAll(item.product.store!.user!.paymentModes!);
//         }
//       }
//
//       setState(() {
//         _availablePaymentModes = paymentModes;
//         _hasCodPayment = paymentModes.contains('cod');
//         _hasBankPayment = paymentModes.contains('bank');
//
//         // Set default payment mode
//         if (_hasCodPayment) {
//           _selectedPayment = 'cod';
//         } else if (_hasBankPayment) {
//           _selectedPayment = 'online';
//         }
//       });
//
//       debugPrint('Available payment modes: $_availablePaymentModes');
//     }
//   }
//
//   Future<void> _showBankSelectionDialog() async {
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);
//     final cartData = cartProvider.cartData?.data;
//
//     if (cartData == null || cartData.items.isEmpty) return;
//
//     final vendorBanks = cartData.items.first.product.store?.vendorBanks ?? [];
//
//     if (vendorBanks.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('No bank accounts available for payment'),
//           backgroundColor: Colors.black,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }
//
//     final selectedBank = await showModalBottomSheet<Map<String, dynamic>>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => BankPaymentDialog(
//         banks: vendorBanks,
//         totalAmount: cartData.cartTotalAmount,
//         currentSelectedBankId: _selectedBankDetails?['bank_id'],
//       ),
//     );
//
//     if (selectedBank != null) {
//       setState(() {
//         _selectedBankDetails = selectedBank;
//         _selectedPayment = 'online';
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Bank changed to: ${selectedBank['bank_name']}'),
//           backgroundColor: Colors.black,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }
//
//   void _handlePaymentModeChange(String paymentMode) {
//     setState(() {
//       _selectedPayment = paymentMode;
//       // If switching to COD, clear bank selection
//       if (paymentMode == 'cod') {
//         _selectedBankDetails = null;
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final tt = Theme.of(context).textTheme;
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Scaffold(
//       backgroundColor: isDark ? Colors.black : Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: isDark ? Colors.black : Colors.white,
//         elevation: 0,
//         leading: Padding(
//           padding: const EdgeInsets.all(6.0),
//           child: _CircleAction(
//             icon: Icons.keyboard_double_arrow_left_outlined,
//             bg: Colors.black,
//             fg: Colors.white,
//             onTap: () => Navigator.pop(context),
//           ),
//         ),
//         title: Text(
//           "Checkout",
//           style: tt.titleMedium?.copyWith(
//             color: isDark ? Colors.white : Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: Consumer<CartProvider>(
//         builder: (context, cartProvider, child) {
//           if (cartProvider.cartData == null ||
//               cartProvider.cartData!.data == null ||
//               cartProvider.cartData!.data!.items.isEmpty) {
//             return _buildEmptyCart(context, isDark);
//           }
//
//           final cartData = cartProvider.cartData!.data!;
//
//           return Column(
//             children: [
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       const SizedBox(height: 16),
//
//
//
//                       // Delivery Method
//                       _buildDeliveryMethodCard(context, isDark),
//
//                       const SizedBox(height: 16),
//                       // Delivery Address
//                       _buildDeliveryAddressCard(context, isDark),
//
//                       const SizedBox(height: 16),
//
//                       // Product Items
//                       _buildProductItemsCard(context, isDark, cartData.items),
//
//                       const SizedBox(height: 16),
//
//                       // Order Summary
//                       _buildOrderSummaryCard(context, isDark, cartData),
//
//                       const SizedBox(height: 16),
//
//                       // Payment Method
//                       _buildPaymentMethodCard(context, isDark, cartData),
//
//                       const SizedBox(height: 100),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//       bottomNavigationBar: _buildCheckoutBottomBar(context, isDark),
//     );
//   }
//
//   Widget _buildEmptyCart(BuildContext context, bool isDark) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
//           const SizedBox(height: 16),
//           Text(
//             'Your cart is empty',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: isDark ? Colors.white : Colors.black,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Add items to proceed to checkout',
//             style: TextStyle(
//               color: Colors.grey,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDeliveryAddressCard(BuildContext context, bool isDark) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: isDark ? Colors.grey[900] : Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.location_on_outlined, color: Colors.black, size: 24),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Delivery Address',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: isDark ? Colors.white : Colors.black,
//                     ),
//                   ),
//                 ],
//               ),
//               TextButton(
//                 onPressed: () async {
//                   final selected = await Navigator.push<AddressModel>(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => AddressListScreen(
//                         isSelectionMode: true,
//                         selectedAddress: _selectedAddress,
//                       ),
//                     ),
//                   );
//                   if (selected != null) {
//                     setState(() {
//                       _selectedAddress = selected;
//                     });
//                   }
//                 },
//                 child: Text(
//                   _selectedAddress == null ? 'Select' : 'Change',
//                   style: const TextStyle(
//                     color: Colors.black,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           if (_selectedAddress != null) ...[
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: isDark ? Colors.grey[800] : Colors.grey[100],
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Text(
//                         _selectedAddress!.name,
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w700,
//                           color: isDark ? Colors.white : Colors.black,
//                         ),
//                       ),
//                       if (_selectedAddress!.isDefault)
//                         Container(
//                           margin: const EdgeInsets.only(left: 8),
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.black,
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                           child: const Text(
//                             "Default",
//                             style: TextStyle(
//                               fontSize: 11,
//                               color: Colors.white,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     _selectedAddress!.fullName,
//                     style: TextStyle(
//                       fontWeight: FontWeight.w600,
//                       color: isDark ? Colors.white : Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     _selectedAddress!.mobile,
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     "${_selectedAddress!.address}, ${_selectedAddress!.city}, ${_selectedAddress!.state} - ${_selectedAddress!.pincode}",
//                     style: TextStyle(
//                       color: Colors.grey,
//                       height: 1.4,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ] else
//             Container(
//               margin: const EdgeInsets.only(top: 12),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.red.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.red.withOpacity(0.5)),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.info_outline, color: Colors.red, size: 20),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       'Please select a delivery address',
//                       style: TextStyle(color: Colors.red),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDeliveryMethodCard(BuildContext context, bool isDark) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: isDark ? Colors.grey[900] : Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Delivery Method',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: isDark ? Colors.white : Colors.black,
//             ),
//           ),
//           const SizedBox(height: 12),
//           _buildDeliveryOption(
//             title: 'Home Delivery',
//             subtitle: 'Deliver to your doorstep',
//             icon: Icons.home_outlined,
//             value: 'home_delivery',
//             isDark: isDark,
//           ),
//           const SizedBox(height: 12),
//           _buildDeliveryOption(
//             title: 'Store Pickup',
//             subtitle: 'Pickup from nearest store',
//             icon: Icons.store_outlined,
//             value: 'store_pickup',
//             isDark: isDark,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDeliveryOption({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required String value,
//     required bool isDark,
//   }) {
//     final isSelected = _deliveryMethod == value;
//     return GestureDetector(
//       onTap: () => setState(() => _deliveryMethod = value),
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: isSelected ? Colors.black : Colors.grey.shade300,
//             width: isSelected ? 2 : 1,
//           ),
//           borderRadius: BorderRadius.circular(12),
//           color: isSelected
//               ? (isDark ? Colors.grey[800] : Colors.grey[200])
//               : (isDark ? Colors.grey[900] : Colors.white),
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: isDark ? Colors.grey[700] : Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(icon,
//                   color: isSelected ? Colors.black : Colors.grey,
//                   size: 20
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: isDark ? Colors.white : Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     subtitle,
//                     style: TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//             Radio<String>(
//               value: value,
//               groupValue: _deliveryMethod,
//               onChanged: (val) => setState(() => _deliveryMethod = val!),
//               activeColor: Colors.black,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildProductItemsCard(
//       BuildContext context,
//       bool isDark,
//       List<CartItem> items,
//       ) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: isDark ? Colors.grey[900] : Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Order Items',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : Colors.black,
//                 ),
//               ),
//               Text(
//                 '${items.length} item${items.length > 1 ? 's' : ''}',
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           ...items.map((item) => _buildProductItem(item, isDark)).toList(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildProductItem(CartItem item, bool isDark) {
//     // Get the correct price from selected combination
//     final double itemPrice = item.selectedCombination != null
//         ? double.parse(item.selectedCombination!.price)
//         : item.product.getDisplayPrice();
//
//     final double itemTotal = itemPrice * item.quantity;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: isDark ? Colors.grey[800] : Colors.grey[50],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Product Image
//           Container(
//             width: 70,
//             height: 70,
//             decoration: BoxDecoration(
//               color: isDark ? Colors.grey[800] : Colors.grey[200],
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: Image.network(
//                 '${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${item.product.primaryImage}',
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => Icon(
//                   Icons.image_not_supported,
//                   color: Colors.grey,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//
//           // Product Details
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Product Name
//                 Text(
//                   item.product.name,
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: isDark ? Colors.white : Colors.black,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 4),
//
//                 // Variant/Combination Details
//                 if (item.selectedCombination != null &&
//                     item.selectedCombination!.variant.isNotEmpty) ...[
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       item.selectedCombination!.displayVariant,
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: isDark ? Colors.grey[300] : Colors.grey[700],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                 ],
//
//                 // Quantity and Price
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Qty: ${item.quantity}',
//                       style: const TextStyle(
//                         color: Colors.grey,
//                         fontSize: 12,
//                       ),
//                     ),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Text(
//                           '${itemPrice.toStringAsFixed(2)} c.',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                           ),
//                         ),
//                         Text(
//                           'Total: ${itemTotal.toStringAsFixed(2)} c.',
//                           style: const TextStyle(
//                             color: Colors.grey,
//                             fontSize: 11,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//   Widget _buildOrderSummaryCard(
//       BuildContext context,
//       bool isDark,
//       CartData cartData,
//       ) {
//     // Calculate total from items using combination prices
//     double calculatedTotal = 0;
//     for (var item in cartData.items) {
//       final itemPrice = item.selectedCombination != null
//           ? double.parse(item.selectedCombination!.price)
//           : item.product.getDisplayPrice();
//       calculatedTotal += itemPrice * item.quantity;
//     }
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: isDark ? Colors.grey[900] : Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Order Summary',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: isDark ? Colors.white : Colors.black,
//             ),
//           ),
//           const SizedBox(height: 12),
//           _buildPriceRow(
//             'Subtotal',
//             '${calculatedTotal.toStringAsFixed(2)} c.',
//           ),
//           _buildPriceRow('Delivery', 'FREE', isGreen: true),
//           _buildPriceRow('Service Fee', 'FREE', isGreen: true),
//           const Divider(height: 24, color: Colors.grey),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Total Amount',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : Colors.black,
//                 ),
//               ),
//               Text(
//                 '${calculatedTotal.toStringAsFixed(2)} c.',
//                 style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPriceRow(String label, String value, {bool isGreen = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(color: Colors.grey),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontWeight: FontWeight.w600,
//               color: isGreen ? Colors.green : Colors.black,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPaymentMethodCard(
//       BuildContext context,
//       bool isDark,
//       CartData cartData,
//       ) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: isDark ? Colors.grey[900] : Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Payment Method',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : Colors.black,
//                 ),
//               ),
//               if (_availablePaymentModes.isNotEmpty)
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.black,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     _availablePaymentModes.map((m) => m.toUpperCase()).join(' + '),
//                     style: const TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 12),
//
//           if (_hasCodPayment)
//             _buildPaymentOption(
//               title: 'Cash on Delivery',
//               subtitle: 'Pay when you receive',
//               icon: Icons.local_shipping_outlined,
//               value: 'cod',
//               isDark: isDark,
//             ),
//
//           if (_hasCodPayment && _hasBankPayment)
//             const SizedBox(height: 12),
//
//           if (_hasBankPayment)
//             _buildBankPaymentOption(
//               context,
//               isDark,
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBankPaymentOption(
//       BuildContext context,
//       bool isDark,
//       ) {
//     final isSelected = _selectedPayment == 'online';
//
//     return GestureDetector(
//       onTap: () {
//         if (_selectedBankDetails != null) {
//           _handlePaymentModeChange('online');
//         } else {
//           _showBankSelectionDialog();
//         }
//       },
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: isSelected ? Colors.black : Colors.grey.shade300,
//             width: isSelected ? 2 : 1,
//           ),
//           borderRadius: BorderRadius.circular(12),
//           color: isSelected
//               ? (isDark ? Colors.grey[800] : Colors.grey[200])
//               : (isDark ? Colors.grey[900] : Colors.white),
//         ),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: isDark ? Colors.grey[700] : Colors.grey[100],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(Icons.account_balance,
//                       color: isSelected ? Colors.black : Colors.grey,
//                       size: 20
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Bank Transfer',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: isDark ? Colors.white : Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         _selectedBankDetails != null
//                             ? 'Change bank or pay'
//                             : 'Select bank to pay',
//                         style: const TextStyle(color: Colors.grey, fontSize: 12),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (_selectedBankDetails == null)
//                   ElevatedButton(
//                     onPressed: _showBankSelectionDialog,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.black,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       minimumSize: const Size(0, 30),
//                     ),
//                     child: const Text('Select'),
//                   )
//                 else
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: Icon(Icons.edit, color: Colors.black, size: 20),
//                         onPressed: _showBankSelectionDialog,
//                         padding: EdgeInsets.zero,
//                         constraints: const BoxConstraints(),
//                       ),
//                       Radio<String>(
//                         value: 'online',
//                         groupValue: _selectedPayment,
//                         onChanged: (val) => _handlePaymentModeChange('online'),
//                         activeColor: Colors.black,
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//
//             if (_selectedBankDetails != null) ...[
//               const SizedBox(height: 12),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: isDark ? Colors.grey[800] : Colors.grey[100],
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(Icons.check_circle, color: Colors.black, size: 16),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             'Bank Account Selected',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Bank: ${_selectedBankDetails!['bank_name']}',
//                       style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black),
//                     ),
//                     GestureDetector(
//                       onTap: (){
//                         final text = "${_selectedBankDetails!['account_number']}" ?? '';
//                         Clipboard.setData(ClipboardData(text: text));
//
//                       },
//                       child: Row(
//                         children: [
//                           Text(
//                             'Account: ${_selectedBankDetails!['account_number']}',
//                             style: TextStyle(fontSize: 13, color: Colors.grey),
//                           ),
//                           const SizedBox(width: 6),
//                           const Icon(Icons.copy, size: 16, color: Colors.grey),
//
//                         ],
//                       ),
//                     ),
//                     Text(
//                       'Holder: ${_selectedBankDetails!['account_holder_name']}',
//                       style: TextStyle(fontSize: 13, color: Colors.grey),
//                     ),
//                     const SizedBox(height: 8),
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.black.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Row(
//                         children: [
//                           Icon(Icons.info_outline, color: Colors.black, size: 16),
//                           SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               'Please complete the payment manually to the above account',
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPaymentOption({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required String value,
//     required bool isDark,
//   }) {
//     final isSelected = _selectedPayment == value;
//     return GestureDetector(
//       onTap: () => _handlePaymentModeChange(value),
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: isSelected ? Colors.black : Colors.grey.shade300,
//             width: isSelected ? 2 : 1,
//           ),
//           borderRadius: BorderRadius.circular(12),
//           color: isSelected
//               ? (isDark ? Colors.grey[800] : Colors.grey[200])
//               : (isDark ? Colors.grey[900] : Colors.white),
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: isDark ? Colors.grey[700] : Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(icon,
//                   color: isSelected ? Colors.black : Colors.grey,
//                   size: 20
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: isDark ? Colors.white : Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     subtitle,
//                     style: const TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//             Radio<String>(
//               value: value,
//               groupValue: _selectedPayment,
//               onChanged: (val) => _handlePaymentModeChange(val!),
//               activeColor: Colors.black,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCheckoutBottomBar(
//       BuildContext context,
//       bool isDark,
//       ) {
//     return Consumer<CartProvider>(
//       builder: (context, cart, child) {
//         final cartData = cart.cartData?.data;
//
//         // Calculate total from items using combination prices
//         double calculatedTotal = 0;
//         if (cartData != null) {
//           for (var item in cartData.items) {
//             final itemPrice = item.selectedCombination != null
//                 ? double.parse(item.selectedCombination!.price)
//                 : item.product.getDisplayPrice();
//             calculatedTotal += itemPrice * item.quantity;
//           }
//         }
//
//         return Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: isDark ? Colors.grey[900] : Colors.white,
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 12,
//                 offset: const Offset(0, -4),
//               ),
//             ],
//           ),
//           child: SafeArea(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'Total Amount',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                     Text(
//                       '${calculatedTotal.toStringAsFixed(2)} c.',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: isDark ? Colors.white : Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton(
//                     onPressed: _canPlaceOrder() && !_isPlacingOrder
//                         ? () => _placeOrder(context, cart)
//                         : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.black,
//                       foregroundColor: Colors.white,
//                       disabledBackgroundColor: Colors.grey.shade300,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       elevation: 0,
//                     ),
//                     child: _isPlacingOrder
//                         ? const SizedBox(
//                       width: 24,
//                       height: 24,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     )
//                         : Text(
//                       _getButtonText(),
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   bool _canPlaceOrder() {
//     if (_selectedAddress == null) return false;
//     if (_selectedPayment == 'online' && _selectedBankDetails == null) return false;
//     return true;
//   }
//
//   String _getButtonText() {
//     if (_selectedPayment == 'cod') {
//       return 'Place Order (Pay on Delivery)';
//     } else if (_selectedPayment == 'online') {
//       return 'Confirm & Pay Manually';
//     }
//     return 'Place Order';
//   }
//
//   Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
//     if (_selectedAddress == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select a delivery address'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     if (_selectedPayment == 'online' && _selectedBankDetails == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select a bank for payment'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }
//
//     setState(() {
//       _isPlacingOrder = true;
//     });
//
//     try {
//       final result = await OrderService.placeOrder(
//         addressId: _selectedAddress!.id,
//         deliveryMethod: _deliveryMethod,
//         paymentType: _selectedPayment,
//         bankDetails: _selectedPayment == 'online' ? _selectedBankDetails : null,
//       );
//
//       setState(() {
//         _isPlacingOrder = false;
//       });
//
//       if (result['status'] == true) {
//         await cart.refreshCart();
//
//         if (mounted) {
//           _showOrderSuccessDialog(context);
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(result['message'] ?? 'Failed to place order'),
//               backgroundColor: Colors.red,
//             ),
//           );
//
//           if (result['goHome'] == true) {
//             Navigator.of(context).popUntil((route) => route.isFirst);
//           }
//         }
//       }
//
//     } catch (e) {
//       setState(() {
//         _isPlacingOrder = false;
//       });
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         );
//       }
//     }
//   }
//
//   void _showOrderSuccessDialog(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         backgroundColor: isDark ? Colors.grey[900] : Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         contentPadding: const EdgeInsets.all(32),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 80,
//               height: 80,
//               decoration: const BoxDecoration(
//                 color: Colors.black,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(Icons.check, color: Colors.white, size: 40),
//             ),
//             const SizedBox(height: 24),
//             Text(
//               _selectedPayment == 'cod'
//                   ? 'Order Placed Successfully!'
//                   : 'Order Initiated!',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: isDark ? Colors.white : Colors.black,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               _selectedPayment == 'cod'
//                   ? 'Thank you for your order. You will receive a confirmation shortly.'
//                   : 'Please complete the payment to the bank account shown. Your order will be processed after payment confirmation.',
//               style: const TextStyle(color: Colors.grey),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 32),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(builder: (context) => const SimpleBottomNavScreen())
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.black,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   'Continue Shopping',
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _CircleAction extends StatelessWidget {
//   final IconData icon;
//   final Color bg;
//   final Color fg;
//   final VoidCallback onTap;
//
//   const _CircleAction({
//     required this.icon,
//     required this.bg,
//     required this.fg,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(20),
//         child: Container(
//           height: 40,
//           width: 40,
//           decoration: BoxDecoration(
//             color: bg,
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Icon(icon, color: fg, size: 20),
//         ),
//       ),
//     );
//   }
// }
//
// class BankPaymentDialog extends StatefulWidget {
//   final List<VendorBank> banks;
//   final double totalAmount;
//   final int? currentSelectedBankId;
//
//   const BankPaymentDialog({
//     Key? key,
//     required this.banks,
//     required this.totalAmount,
//     this.currentSelectedBankId,
//   }) : super(key: key);
//
//   @override
//   State<BankPaymentDialog> createState() => _BankPaymentDialogState();
// }
//
// class _BankPaymentDialogState extends State<BankPaymentDialog> {
//   VendorBank? _selectedBank;
//
//   @override
//   void initState() {
//     super.initState();
//     // Pre-select the currently selected bank if available
//     if (widget.currentSelectedBankId != null) {
//       try {
//         _selectedBank = widget.banks.firstWhere(
//               (bank) => bank.bankId == widget.currentSelectedBankId,
//         );
//       } catch (e) {
//         _selectedBank = widget.banks.isNotEmpty ? widget.banks.first : null;
//       }
//     } else {
//       _selectedBank = widget.banks.isNotEmpty ? widget.banks.first : null;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Container(
//       decoration: BoxDecoration(
//         color: isDark ? Colors.grey[900] : Colors.white,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Drag handle
//           Center(
//             child: Container(
//               width: 40,
//               height: 4,
//               margin: const EdgeInsets.only(top: 12, bottom: 8),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//
//           // Header
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Icon(Icons.account_balance, color: Colors.black, size: 20),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         widget.currentSelectedBankId != null
//                             ? 'Change Bank Account'
//                             : 'Select Bank Account',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: isDark ? Colors.white : Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       const Text(
//                         'Choose the bank account for payment',
//                         style: TextStyle(color: Colors.grey, fontSize: 12),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           Divider(height: 1, color: Colors.grey.shade300),
//
//           // Bank List
//           Flexible(
//             child: ListView.builder(
//               shrinkWrap: true,
//               padding: const EdgeInsets.all(16),
//               itemCount: widget.banks.length,
//               itemBuilder: (context, index) {
//                 final bank = widget.banks[index];
//                 final isSelected = _selectedBank?.bankId == bank.bankId;
//
//                 return GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _selectedBank = bank;
//                     });
//                   },
//                   child: Container(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       border: Border.all(
//                         color: isSelected ? Colors.black : Colors.grey.shade300,
//                         width: isSelected ? 2 : 1,
//                       ),
//                       borderRadius: BorderRadius.circular(12),
//                       color: isSelected
//                           ? (isDark ? Colors.grey[800] : Colors.grey[200])
//                           : (isDark ? Colors.grey[900] : Colors.white),
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: isDark ? Colors.grey[700] : Colors.grey[100],
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: bank.bankLogo != null
//                               ? Image.network(
//                             '${ApiService.ImagebaseUrl}/banks/${bank.bankLogo}',
//                             width: 30,
//                             errorBuilder: (_, __, ___) => Icon(
//                               Icons.account_balance,
//                               color: Colors.grey,
//                             ),
//                           )
//                               : const Icon(Icons.account_balance, color: Colors.grey),
//                         ),
//                         const SizedBox(width: 12),
//
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 bank.bankName,
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w600,
//                                   color: isDark ? Colors.white : Colors.black,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               GestureDetector(
//                                 onLongPress: () {
//                                   final text = bank.accountNumber ?? '';
//                                   Clipboard.setData(ClipboardData(text: text));
//
//                                 },
//                                 onTap: (){
//                                   final text = bank.accountNumber ?? '';
//                                   Clipboard.setData(ClipboardData(text: text));
//                                 },
//                                 child: Row(
//                                   children: [
//                                     Text(
//                                       'A/C: ${bank.accountNumber}',
//                                       style: const TextStyle(color: Colors.grey, fontSize: 12),
//                                     ),
//                                     SizedBox(width: 8,),
//                                     const Icon(Icons.copy, size: 16, color: Colors.grey),
//
//                                   ],
//                                 ),
//                               ),
//                               Text(
//                                 'Name: ${bank.accountHolderName}',
//                                 style: const TextStyle(color: Colors.grey, fontSize: 12),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         if (isSelected)
//                           const Icon(Icons.check_circle, color: Colors.black, size: 24)
//                         else
//                           Container(
//                             width: 24,
//                             height: 24,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               border: Border.all(color: Colors.grey, width: 2),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//
//           // Amount Summary
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: isDark ? Colors.grey[800] : Colors.grey[100],
//               border: Border(top: BorderSide(color: Colors.grey.shade300)),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Total Amount',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 Text(
//                   '${widget.totalAmount.toStringAsFixed(2)} c.',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Action Buttons
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.black,
//                       side: const BorderSide(color: Colors.grey),
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text('Cancel'),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _selectedBank != null
//                         ? () {
//                       Navigator.pop(context, {
//                         'bank_id': _selectedBank!.bankId,
//                         'bank_name': _selectedBank!.bankName,
//                         'account_number': _selectedBank!.accountNumber,
//                         'account_holder_name': _selectedBank!.accountHolderName,
//                       });
//                     }
//                         : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.black,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: Text(
//                       widget.currentSelectedBankId != null
//                           ? 'Change Bank'
//                           : 'Confirm Selection',
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 80,),
//           // SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
//         ],
//       ),
//     );
//   }
// }

import 'package:ecom/extensions/context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Payment mode flags
  bool _hasCodPayment = false;
  bool _hasBankPayment = false;

  // Selected bank details for bank payment
  Map<String, dynamic>? _selectedBankDetails;

  // Store all available payment modes from cart items
  Set<String> _availablePaymentModes = {};

  // Store address for store pickup
  String? _storePickupAddress;

  @override
  void initState() {
    super.initState();
    _extractPaymentModes();
    _extractStoreAddress();
  }

  void _extractPaymentModes() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartData = cartProvider.cartData?.data;

    if (cartData != null) {
      Set<String> paymentModes = {};

      for (var item in cartData.items) {
        if (item.product.store?.user?.paymentModes != null) {
          paymentModes.addAll(item.product.store!.user!.paymentModes!);
        }
      }

      setState(() {
        _availablePaymentModes = paymentModes;
        _hasCodPayment = paymentModes.contains('cod');
        _hasBankPayment = paymentModes.contains('bank');

        // Set default payment mode
        if (_hasCodPayment) {
          _selectedPayment = 'cod';
        } else if (_hasBankPayment) {
          _selectedPayment = 'online';
        }
      });

      debugPrint('Available payment modes: $_availablePaymentModes');
    }
  }

  void _extractStoreAddress() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartData = cartProvider.cartData?.data;

    if (cartData != null && cartData.items.isNotEmpty) {
      final store = cartData.items.first.product.store;
      if (store != null) {
        setState(() {
          _storePickupAddress =
          '${store.name}\n'
              '${store.address}\n'
              '${store.city}, ${store.country}\n'
              '${context.tr('txt_phone')}: ${store.mobile}';
        });
      }
    }
  }

  Future<void> _showBankSelectionDialog() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartData = cartProvider.cartData?.data;

    if (cartData == null || cartData.items.isEmpty) return;

    final vendorBanks = cartData.items.first.product.store?.vendorBanks ?? [];

    if (vendorBanks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('txt_no_bank_accounts')),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedBank = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BankPaymentDialog(
        banks: vendorBanks,
        totalAmount: cartData.cartTotalAmount,
        currentSelectedBankId: _selectedBankDetails?['bank_id'],
      ),
    );

    if (selectedBank != null) {
      setState(() {
        _selectedBankDetails = selectedBank;
        _selectedPayment = 'online';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('txt_bank_changed_to')}: ${selectedBank['bank_name']}'),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handlePaymentModeChange(String paymentMode) {
    setState(() {
      _selectedPayment = paymentMode;
      // If switching to COD, clear bank selection
      if (paymentMode == 'cod') {
        _selectedBankDetails = null;
      }
    });
  }

  void _handleDeliveryMethodChange(String method) {
    setState(() {
      _deliveryMethod = method;
      // Clear selected address when switching to store pickup
      if (method == 'store_pickup') {
        _selectedAddress = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: _CircleAction(
            icon: Icons.keyboard_double_arrow_left_outlined,
            bg: Colors.black,
            fg: Colors.white,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          context.tr('txt_checkout'),
          style: tt.titleMedium?.copyWith(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.cartData == null ||
              cartProvider.cartData!.data == null ||
              cartProvider.cartData!.data!.items.isEmpty) {
            return _buildEmptyCart(context, isDark);
          }

          final cartData = cartProvider.cartData!.data!;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // Delivery Method
                      _buildDeliveryMethodCard(context, isDark),

                      const SizedBox(height: 16),

                      // Delivery Address OR Store Address (based on selection)
                      _buildAddressCard(context, isDark, cartData),

                      const SizedBox(height: 16),

                      // Product Items
                      _buildProductItemsCard(context, isDark, cartData.items),

                      const SizedBox(height: 16),

                      // Order Summary
                      _buildOrderSummaryCard(context, isDark, cartData),

                      const SizedBox(height: 16),

                      // Payment Method
                      _buildPaymentMethodCard(context, isDark, cartData),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildCheckoutBottomBar(context, isDark),
    );
  }

  Widget _buildEmptyCart(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            context.tr('txt_your_cart_empty'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('txt_add_items_to_proceed'),
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, bool isDark, CartData cartData) {
    if (_deliveryMethod == 'store_pickup') {
      // Show store address for pickup
      return _buildStorePickupCard(context, isDark, cartData);
    } else {
      // Show delivery address selection
      return _buildDeliveryAddressCard(context, isDark);
    }
  }

  Widget _buildStorePickupCard(BuildContext context, bool isDark, CartData cartData) {
    final store = cartData.items.isNotEmpty ? cartData.items.first.product.store : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store_outlined, color: Colors.black, size: 24),
              const SizedBox(width: 8),
              Text(
                context.tr('txt_store_pickup'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store?.name ?? context.tr('txt_store_name'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  store?.address ?? context.tr('txt_address_not_available'),
                  style: TextStyle(
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                // if (store?.city != null && store?.country != null) ...[
                //   const SizedBox(height: 2),
                //   Text(
                //     '${store!.city}, ${store.country}',
                //     style: TextStyle(color: Colors.grey),
                //   ),
                // ],
                if (store?.mobile != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        store!.mobile,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.black, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('please_collect_order'),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  Icon(Icons.location_on_outlined, color: Colors.black, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('txt_delivery_address'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
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
                  _selectedAddress == null ? context.tr('txt_select') : context.tr('txt_change'),
                  style: const TextStyle(
                    color: Colors.black,
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
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _selectedAddress!.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
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
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            context.tr('txt_default'),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedAddress!.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedAddress!.mobile,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${_selectedAddress!.address}, ${_selectedAddress!.city}, ${_selectedAddress!.state} - ${_selectedAddress!.pincode}",
                    style: TextStyle(
                      color: Colors.grey,
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('txt_please_select_delivery'),
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryMethodCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('txt_delivery_method'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildDeliveryOption(
            title: context.tr('txt_home_delivery'),
            subtitle: context.tr('desc_home_delivery'),
            icon: Icons.home_outlined,
            value: 'home_delivery',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildDeliveryOption(
            title: context.tr('title_store_pickup'),
            subtitle: context.tr('desc_store_pickup'),
            icon: Icons.store_outlined,
            value: 'store_pickup',
            isDark: isDark,
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
    required bool isDark,
  }) {
    final isSelected = _deliveryMethod == value;
    return GestureDetector(
      onTap: () => _handleDeliveryMethodChange(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? (isDark ? Colors.grey[800] : Colors.grey[200])
              : (isDark ? Colors.grey[900] : Colors.white),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: isSelected ? Colors.black : Colors.grey,
                  size: 20
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _deliveryMethod,
              onChanged: (val) => _handleDeliveryMethodChange(val!),
              activeColor: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItemsCard(
      BuildContext context,
      bool isDark,
      List<CartItem> items,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                context.tr('txt_order_items'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '${items.length} ${context.tr('txt_item')}${items.length > 1 ? 's' : ''}',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildProductItem(item, isDark)).toList(),
        ],
      ),
    );
  }

  Widget _buildProductItem(CartItem item, bool isDark) {
    // Get the correct price from selected combination
    final double itemPrice = item.selectedCombination != null
        ? double.parse(item.selectedCombination!.price)
        : item.product.getDisplayPrice();

    final double itemTotal = itemPrice * item.quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                '${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${item.product.primaryImage}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                ),
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
                  item.product.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Variant/Combination Details
                if (item.selectedCombination != null &&
                    item.selectedCombination!.variant.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.selectedCombination!.displayVariant,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Quantity and Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${context.tr('txt_qty')}: ${item.quantity}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${itemPrice.toInt()} c.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${context.tr('txt_total')}: ${itemTotal.toInt()} c.',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
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


  Widget _buildOrderSummaryCard(
      BuildContext context,
      bool isDark,
      CartData cartData,
      ) {
    // Calculate total from items using combination prices
    double calculatedTotal = 0;
    for (var item in cartData.items) {
      final itemPrice = item.selectedCombination != null
          ? double.parse(item.selectedCombination!.price)
          : item.product.getDisplayPrice();
      calculatedTotal += itemPrice * item.quantity;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('txt_order_summary'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow(
            context.tr('txt_subtotal'),
            '${calculatedTotal.toInt()} c.',
          ),
          _buildPriceRow(context.tr('txt_delivery'), context.tr('txt_free'), isGreen: true),
          _buildPriceRow(context.tr('txt_service_fee'), context.tr('txt_free'), isGreen: true),
          const Divider(height: 24, color: Colors.grey),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('txt_total_amount'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '${calculatedTotal.toInt()} c.',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isGreen ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
      BuildContext context,
      bool isDark,
      CartData cartData,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                context.tr('txt_payment_method'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              if (_availablePaymentModes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _availablePaymentModes.map((m) => m.toUpperCase()).join(' + '),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_hasCodPayment)
            _buildPaymentOption(
              title: context.tr('title_cod'),
              subtitle: context.tr('desc_cod'),
              icon: Icons.local_shipping_outlined,
              value: 'cod',
              isDark: isDark,
            ),

          if (_hasCodPayment && _hasBankPayment)
            const SizedBox(height: 12),

          if (_hasBankPayment)
            _buildBankPaymentOption(
              context,
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildBankPaymentOption(
      BuildContext context,
      bool isDark,
      ) {
    final isSelected = _selectedPayment == 'online';

    return GestureDetector(
      onTap: () {
        if (_selectedBankDetails != null) {
          _handlePaymentModeChange('online');
        } else {
          _showBankSelectionDialog();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? (isDark ? Colors.grey[800] : Colors.grey[200])
              : (isDark ? Colors.grey[900] : Colors.white),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.account_balance,
                      color: isSelected ? Colors.black : Colors.grey,
                      size: 20
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('txt_bank_transfer'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedBankDetails != null
                            ? context.tr('txt_change_bank_to_pay')
                            : context.tr('txt_select_to_pay'),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (_selectedBankDetails == null)
                  ElevatedButton(
                    onPressed: _showBankSelectionDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: const Size(0, 30),
                    ),
                    child: Text(context.tr('txt_select')),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.black, size: 20),
                        onPressed: _showBankSelectionDialog,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Radio<String>(
                        value: 'online',
                        groupValue: _selectedPayment,
                        onChanged: (val) => _handlePaymentModeChange('online'),
                        activeColor: Colors.black,
                      ),
                    ],
                  ),
              ],
            ),

            if (_selectedBankDetails != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.black, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr('txt_bank_acc_selected'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${context.tr('txt_bank')}: ${_selectedBankDetails!['bank_name']}',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                    ),
                    GestureDetector(
                      onTap: (){
                        final text = "${_selectedBankDetails!['account_number']}" ?? '';
                        Clipboard.setData(ClipboardData(text: text));

                      },
                      child: Row(
                        children: [
                          Text(
                            'Account: ${_selectedBankDetails!['account_number']}',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy, size: 16, color: Colors.grey),

                        ],
                      ),
                    ),
                    Text(
                      'Holder: ${_selectedBankDetails!['account_holder_name']}',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.black, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please complete the payment manually to the above account',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required bool isDark,
  }) {
    final isSelected = _selectedPayment == value;
    return GestureDetector(
      onTap: () => _handlePaymentModeChange(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? (isDark ? Colors.grey[800] : Colors.grey[200])
              : (isDark ? Colors.grey[900] : Colors.white),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: isSelected ? Colors.black : Colors.grey,
                  size: 20
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPayment,
              onChanged: (val) => _handlePaymentModeChange(val!),
              activeColor: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBottomBar(
      BuildContext context,
      bool isDark,
      ) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final cartData = cart.cartData?.data;

        // Calculate total from items using combination prices
        double calculatedTotal = 0;
        if (cartData != null) {
          for (var item in cartData.items) {
            final itemPrice = item.selectedCombination != null
                ? double.parse(item.selectedCombination!.price)
                : item.product.getDisplayPrice();
            calculatedTotal += itemPrice * item.quantity;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                      context.tr('txt_total_amount'),
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '${calculatedTotal.toInt()} c.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canPlaceOrder() && !_isPlacingOrder
                        ? () => _placeOrder(context, cart)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isPlacingOrder
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      _getButtonText(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

  bool _canPlaceOrder() {
    if (_deliveryMethod == 'home_delivery') {
      if (_selectedAddress == null) return false;
    }
    if (_selectedPayment == 'online' && _selectedBankDetails == null) return false;
    return true;
  }

  String _getButtonText() {
    if (_selectedPayment == 'cod') {
      return context.tr('txt_place_order');
    } else if (_selectedPayment == 'online') {
      return context.tr('txt_confirm_pay');
    }
    return context.tr('txt_oder_placed');
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
    // Validation based on delivery method
    if (_deliveryMethod == 'home_delivery' && _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(context.tr('txt_please_select_delivery')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedPayment == 'online' && _selectedBankDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(context.tr('txt_please_select_bank')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final result = await OrderService.placeOrder(
        addressId: _deliveryMethod == 'home_delivery' ? _selectedAddress!.id.toString() : "",
        deliveryMethod: _deliveryMethod,
        paymentType: _selectedPayment,
        bankDetails: _selectedPayment == 'online' ? _selectedBankDetails : null,
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
              content: Text(result['message'] ?? context.tr('txt_failed_to_place_order')),
              backgroundColor: Colors.red,
            ),
          );

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedPayment == 'cod'
                  ? context.tr('txt_order_placed_successfully')
                  : context.tr('txt_order_initiated'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedPayment == 'cod'
                  ? context.tr('txt_order_placed')
                  : context.tr('txt_please_complete_bank_details'),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SimpleBottomNavScreen())
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.tr('txt_continue_shopping'),
                  style: TextStyle(fontWeight: FontWeight.w600),
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

class BankPaymentDialog extends StatefulWidget {
  final List<VendorBank> banks;
  final double totalAmount;
  final int? currentSelectedBankId;

  const BankPaymentDialog({
    Key? key,
    required this.banks,
    required this.totalAmount,
    this.currentSelectedBankId,
  }) : super(key: key);

  @override
  State<BankPaymentDialog> createState() => _BankPaymentDialogState();
}

class _BankPaymentDialogState extends State<BankPaymentDialog> {
  VendorBank? _selectedBank;

  @override
  void initState() {
    super.initState();
    // Pre-select the currently selected bank if available
    if (widget.currentSelectedBankId != null) {
      try {
        _selectedBank = widget.banks.firstWhere(
              (bank) => bank.bankId == widget.currentSelectedBankId,
        );
      } catch (e) {
        _selectedBank = widget.banks.isNotEmpty ? widget.banks.first : null;
      }
    } else {
      _selectedBank = widget.banks.isNotEmpty ? widget.banks.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.currentSelectedBankId != null
                            ? context.tr('txt_change_bank_account')
                            : context.tr('txt_select_bank_account'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                       Text(
                        context.tr('txt_choose_bank_acc_for_payment'),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade300),

          // Bank List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: widget.banks.length,
              itemBuilder: (context, index) {
                final bank = widget.banks[index];
                final isSelected = _selectedBank?.bankId == bank.bankId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedBank = bank;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? (isDark ? Colors.grey[800] : Colors.grey[200])
                          : (isDark ? Colors.grey[900] : Colors.white),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[700] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: bank.bankLogo != null
                              ? Image.network(
                            '${ApiService.ImagebaseUrl}/banks/${bank.bankLogo}',
                            width: 30,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.account_balance,
                              color: Colors.grey,
                            ),
                          )
                              : const Icon(Icons.account_balance, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bank.bankName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onLongPress: () {
                                  final text = bank.accountNumber ?? '';
                                  Clipboard.setData(ClipboardData(text: text));

                                },
                                onTap: (){
                                  final text = bank.accountNumber ?? '';
                                  Clipboard.setData(ClipboardData(text: text));
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      'A/C: ${bank.accountNumber}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    SizedBox(width: 8,),
                                    const Icon(Icons.copy, size: 16, color: Colors.grey),

                                  ],
                                ),
                              ),
                              Text(
                                '${context.tr('txt_name')}: ${bank.accountHolderName}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        if (isSelected)
                          const Icon(Icons.check_circle, color: Colors.black, size: 24)
                        else
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey, width: 2),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Amount Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  context.tr('txt_total_amount'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.totalAmount.toInt()} c.',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(context.tr('txt_cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedBank != null
                        ? () {
                      Navigator.pop(context, {
                        'bank_id': _selectedBank!.bankId,
                        'bank_name': _selectedBank!.bankName,
                        'account_number': _selectedBank!.accountNumber,
                        'account_holder_name': _selectedBank!.accountHolderName,
                      });
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.currentSelectedBankId != null
                          ? context.tr('txt_change_banks')
                          : context.tr('txt_confirm_selection'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 80,),
          // SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}