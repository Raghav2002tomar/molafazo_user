// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/user_details.dart';
// import '../providers/cart_provider.dart';
//
// class CustomModals {
//   static void showSuccessModal(BuildContext context, String title, String message) {
//     final cs = Theme.of(context).colorScheme;
//     final tt = Theme.of(context).textTheme;
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: cs.primary,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Icon(Icons.check, color: cs.onPrimary, size: 20),
//             ),
//             const SizedBox(width: 12),
//             Text(title, style: tt.titleMedium?.copyWith(color: cs.onSurface)),
//           ],
//         ),
//         content: Text(message, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
//         actions: [
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: cs.secondary,
//               foregroundColor: cs.onSecondary,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   static void showCheckoutModal(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => CheckoutModal(),
//     );
//   }
// }
//
// class CheckoutModal extends StatefulWidget {
//   @override
//   _CheckoutModalState createState() => _CheckoutModalState();
// }
//
// class _CheckoutModalState extends State<CheckoutModal> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _addressController = TextEditingController();
//   String _paymentMethod = 'Credit Card';
//
//   final List<String> _paymentMethods = [
//     'Credit Card',
//     'Debit Card',
//     'PayPal',
//     'Cash on Delivery',
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final tt = Theme.of(context).textTheme;
//
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Container(
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.8,
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Checkout',
//                     style: tt.headlineSmall?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: cs.onSurface,
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//
//                   // Name Field
//                   TextFormField(
//                     controller: _nameController,
//                     decoration: InputDecoration(
//                       labelText: 'Full Name',
//                       border: const OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.person, color: cs.primary),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.trim().isEmpty) {
//                         return 'Please enter your name';
//                       }
//                       return null;
//                     },
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   // Address Field
//                   TextFormField(
//                     controller: _addressController,
//                     decoration: InputDecoration(
//                       labelText: 'Delivery Address',
//                       border: const OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.location_on, color: cs.primary),
//                     ),
//                     maxLines: 3,
//                     validator: (value) {
//                       if (value == null || value.trim().isEmpty) {
//                         return 'Please enter your address';
//                       }
//                       return null;
//                     },
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   // Payment Method
//                   Text(
//                     'Payment Method',
//                     style: tt.titleMedium?.copyWith(
//                       fontWeight: FontWeight.w600,
//                       color: cs.onSurface,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   DropdownButtonFormField<String>(
//                     value: _paymentMethod,
//                     decoration: InputDecoration(
//                       border: const OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.payment, color: cs.primary),
//                     ),
//                     items: _paymentMethods.map((method) {
//                       return DropdownMenuItem(
//                         value: method,
//                         child: Text(method),
//                       );
//                     }).toList(),
//                     onChanged: (value) {
//                       setState(() {
//                         _paymentMethod = value!;
//                       });
//                     },
//                   ),
//
//                   const SizedBox(height: 24),
//
//                   // Order Summary
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: cs.surfaceVariant,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: cs.outlineVariant),
//                     ),
//                     child: Consumer<CartProvider>(
//                       builder: (context, cart, child) {
//                         return Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Order Summary',
//                               style: tt.titleMedium?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: cs.onSurface,
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text('Items (${cart.itemCount}):',
//                                     style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
//                                 Text('\$${cart.totalAmount.toStringAsFixed(2)}',
//                                     style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
//                               ],
//                             ),
//                             const Divider(),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text('Total:',
//                                     style: tt.titleMedium?.copyWith(
//                                       fontWeight: FontWeight.bold,
//                                       color: cs.onSurface,
//                                     )),
//                                 Text(
//                                   '\$${cart.totalAmount.toStringAsFixed(2)}',
//                                   style: tt.titleMedium?.copyWith(
//                                     fontWeight: FontWeight.bold,
//                                     color: cs.primary,
//                                     fontSize: 18,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         );
//                       },
//                     ),
//                   ),
//
//                   const SizedBox(height: 24),
//
//                   // Action Buttons
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextButton(
//                           onPressed: () => Navigator.pop(context),
//                           child: Text('Cancel',
//                               style: tt.bodyMedium?.copyWith(color: cs.secondary)),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: () {
//                             // TODO: place order logic
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: cs.primary,
//                             foregroundColor: cs.onPrimary,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           child: const Text('Place Order'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _addressController.dispose();
//     super.dispose();
//   }
// }
