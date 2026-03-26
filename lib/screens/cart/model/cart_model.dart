
import 'dart:convert';

class CartResponse {
  final bool status;
  final String message;
  final CartData? data;

  CartResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    // Handle case where data might be null or empty
    final dataJson = json['data'];

    return CartResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: dataJson != null ? CartData.fromJson(dataJson) : null,
    );
  }
}

// In cart_model.dart, update the CartData class
class CartData {
  final List<CartItem> items;
  final double cartTotalAmount;

  CartData({
    required this.items,
    required this.cartTotalAmount,
  });

  factory CartData.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List)
        .map((item) => CartItem.fromJson(item))
        .toList();

    // Calculate total from items to ensure accuracy
    double calculatedTotal = 0;
    for (var item in items) {
      final itemPrice = item.selectedCombination != null
          ? double.parse(item.selectedCombination!.price)
          : item.product.getDisplayPrice();
      calculatedTotal += itemPrice * item.quantity;
    }

    // Use the calculated total or the API total
    final apiTotal = _parseDouble(json['cart_total_amount']);

    return CartData(
      items: items,
      cartTotalAmount: calculatedTotal > 0 ? calculatedTotal : apiTotal,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class CartItem {
  final int id;
  final int userId;
  final int productId;
  final int quantity;
  final String createdAt;
  final String updatedAt;
  final double itemTotal;
  final CartProduct product;
  final SelectedCombination? selectedCombination;


  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    required this.itemTotal,
    required this.product,
    this.selectedCombination,

  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      itemTotal: (json['item_total'] ?? 0).toDouble(),
      product: CartProduct.fromJson(json['product'] ?? {}),
      selectedCombination: json['selected_combination'] != null
          ? SelectedCombination.fromJson(json['selected_combination'])
          : null,
    );
  }
}
class SelectedCombination {
  final int id;
  final Map<String, dynamic> variant;
  final String price;
  final int stock;
  final List<String> images;

  SelectedCombination({
    required this.id,
    required this.variant,
    required this.price,
    required this.stock,
    required this.images,
  });

  factory SelectedCombination.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> variant;
    if (json['variant'] is String) {
      variant = jsonDecode(json['variant']);
    } else {
      variant = json['variant'] ?? {};
    }

    return SelectedCombination(
      id: json['id'] ?? 0,
      variant: variant,
      price: json['price']?.toString() ?? '0',
      stock: json['stock'] ?? 0,
      images: json['images'] is List
          ? List<String>.from(json['images'])
          : [],
    );
  }

  String get displayVariant {
    if (variant.isEmpty) return '';
    return variant.entries.map((e) => '${e.key}: ${e.value}').join(' • ');
  }
}
class CartProduct {
  final int id;
  final String name;
  final String price;
  final String discountPrice;
  final int storeId;
  final String primaryImage;
  final List<Bank>? banks; // Available banks for this product's store
  final Store? store; // Store details including vendor banks and payment modes

  CartProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.discountPrice,
    required this.storeId,
    required this.primaryImage,
    this.banks,
    this.store,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? '0.00',
      discountPrice: json['discount_price'] ?? '0.00',
      storeId: json['store_id'] ?? 0,
      primaryImage: json['primaryimage'] ?? '',
      banks: json['banks'] != null
          ? (json['banks'] as List).map((b) => Bank.fromJson(b)).toList()
          : null,
      store: json['store'] != null ? Store.fromJson(json['store']) : null,
    );
  }

  // Helper method to get display price
  double getDisplayPrice() {
    final discount = double.tryParse(discountPrice) ?? 0;
    final originalPrice = double.tryParse(price) ?? 0;
    return (discount > 0 && discount < originalPrice) ? discount : originalPrice;
  }
}

class Store {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String mobile;
  final String country;
  final String city;
  final String address;
  final int deliveryBySeller;
  final int selfPickup;
  final String? logo;
  final String? storeBackgroundImage;
  final String? description;
  final String? workingHours;
  final int statusId;
  final String? approvedAt;
  final String createdAt;
  final String updatedAt;
  final String? governmentId;
  final String? type;
  final User? user; // User details including payment modes
  final List<VendorBank>? vendorBanks; // Vendor's bank accounts

  Store({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.country,
    required this.city,
    required this.address,
    required this.deliveryBySeller,
    required this.selfPickup,
    this.logo,
    this.storeBackgroundImage,
    this.description,
    this.workingHours,
    required this.statusId,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.governmentId,
    this.type,
    this.user,
    this.vendorBanks,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      deliveryBySeller: json['delivery_by_seller'] ?? 0,
      selfPickup: json['self_pickup'] ?? 0,
      logo: json['logo'],
      storeBackgroundImage: json['store_background_image'],
      description: json['description'],
      workingHours: json['working_hours'],
      statusId: json['status_id'] ?? 0,
      approvedAt: json['approved_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      governmentId: json['government_id'],
      type: json['type'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      vendorBanks: json['vendor_banks'] != null
          ? (json['vendor_banks'] as List).map((vb) => VendorBank.fromJson(vb)).toList()
          : null,
    );
  }
}

class User {
  final int id;
  final String role;
  final int statusId;
  final List<String>? paymentModes; // Vendor's payment modes (cod, bank)
  final String name;
  final String email;
  final int? emailVerified;
  final String? mobile;
  final int? isMobileVerified;
  final String? mobileVerifiedAt;
  final String? altMobile;
  final String? country;
  final String? city;
  final String? profilePhoto;
  final String? govIdType;
  final String? govIdNumber;
  final String? governmentId;
  final int? termsAccepted;
  final String? approvedAt;
  final String? deviceType;
  final String? deviceToken;
  final String? apiToken;
  final String? fcmToken;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.role,
    required this.statusId,
    this.paymentModes,
    required this.name,
    required this.email,
    this.emailVerified,
    this.mobile,
    this.isMobileVerified,
    this.mobileVerifiedAt,
    this.altMobile,
    this.country,
    this.city,
    this.profilePhoto,
    this.govIdType,
    this.govIdNumber,
    this.governmentId,
    this.termsAccepted,
    this.approvedAt,
    this.deviceType,
    this.deviceToken,
    this.apiToken,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle payment_modes which might be a string or list
    List<String>? paymentModes;
    if (json['payment_modes'] != null) {
      if (json['payment_modes'] is List) {
        paymentModes = List<String>.from(json['payment_modes']);
      } else if (json['payment_modes'] is String) {
        // If it's a string like "cod,bank", split it
        paymentModes = (json['payment_modes'] as String)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return User(
      id: json['id'] ?? 0,
      role: json['role'] ?? '',
      statusId: json['status_id'] ?? 0,
      paymentModes: paymentModes,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      emailVerified: json['email_verified'],
      mobile: json['mobile'],
      isMobileVerified: json['is_mobile_verified'],
      mobileVerifiedAt: json['mobile_verified_at'],
      altMobile: json['alt_mobile'],
      country: json['country'],
      city: json['city'],
      profilePhoto: json['profile_photo'],
      govIdType: json['gov_id_type'],
      govIdNumber: json['gov_id_number'],
      governmentId: json['government_id'],
      termsAccepted: json['terms_accepted'],
      approvedAt: json['approved_at'],
      deviceType: json['device_type'],
      deviceToken: json['device_token'],
      apiToken: json['api_token'],
      fcmToken: json['fcm_token'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class VendorBank {
  final int id;
  final int userId;
  final int bankId;
  final String accountHolderName;
  final String accountNumber;
  final String createdAt;
  final String updatedAt;
  final Bank? bank;

  VendorBank({
    required this.id,
    required this.userId,
    required this.bankId,
    required this.accountHolderName,
    required this.accountNumber,
    required this.createdAt,
    required this.updatedAt,
    this.bank,
  });

  factory VendorBank.fromJson(Map<String, dynamic> json) {
    return VendorBank(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      bankId: json['bank_id'] ?? 0,
      accountHolderName: json['account_holder_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      bank: json['bank'] != null ? Bank.fromJson(json['bank']) : null,
    );
  }

  // Helper getters for easy access
  String get bankName => bank?.name ?? 'Bank';
  String? get bankLogo => bank?.logo;
}

class Bank {
  final int id;
  final String name;
  final String? logo;

  Bank({
    required this.id,
    required this.name,
    this.logo,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logo: json['logo'],
    );
  }
}

// class VendorBank {
//   final int id;
//   final int userId;
//   final int bankId;
//   final String accountHolderName;
//   final String accountNumber;
//   final String createdAt;
//   final String updatedAt;
//   final Bank? bank; // Bank details
//
//   VendorBank({
//     required this.id,
//     required this.userId,
//     required this.bankId,
//     required this.accountHolderName,
//     required this.accountNumber,
//     required this.createdAt,
//     required this.updatedAt,
//     this.bank,
//   });
//
//   factory VendorBank.fromJson(Map<String, dynamic> json) {
//     return VendorBank(
//       id: json['id'] ?? 0,
//       userId: json['user_id'] ?? 0,
//       bankId: json['bank_id'] ?? 0,
//       accountHolderName: json['account_holder_name'] ?? '',
//       accountNumber: json['account_number'] ?? '',
//       createdAt: json['created_at'] ?? '',
//       updatedAt: json['updated_at'] ?? '',
//       bank: json['bank'] != null ? Bank.fromJson(json['bank']) : null,
//     );
//   }
//
//   // Helper method to get bank name
//   String get bankName => bank?.name ?? 'Bank';
//
//   // Helper method to get bank logo
//   String? get bankLogo => bank?.logo;
// }

// Extension to get payment modes from cart items
extension CartPaymentModes on CartData {
  Set<String> getAvailablePaymentModes() {
    Set<String> paymentModes = {};

    for (var item in items) {
      if (item.product.store?.user?.paymentModes != null) {
        paymentModes.addAll(item.product.store!.user!.paymentModes!);
      }
    }

    return paymentModes;
  }

  bool hasCodPayment() {
    return getAvailablePaymentModes().contains('cod');
  }

  bool hasBankPayment() {
    return getAvailablePaymentModes().contains('bank');
  }

  // Get all vendor banks from the first item (assuming all items from same vendor)
  List<VendorBank>? getVendorBanks() {
    if (items.isEmpty) return null;
    return items.first.product.store?.vendorBanks;
  }

  // Check if all items are from the same vendor
  bool isSingleVendor() {
    if (items.isEmpty) return true;
    final firstVendorId = items.first.product.storeId;
    return items.every((item) => item.product.storeId == firstVendorId);
  }

  // Get vendor ID (returns null if multiple vendors)
  int? getVendorId() {
    if (!isSingleVendor()) return null;
    return items.first.product.storeId;
  }

  // Get vendor name (returns null if multiple vendors)
  String? getVendorName() {
    if (!isSingleVendor()) return null;
    return items.first.product.store?.name;
  }
}