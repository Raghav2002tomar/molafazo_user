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
    return CartResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? CartData.fromJson(json['data']) : null,
    );
  }
}

class CartData {
  final List<CartItem> items;
  final double cartTotalAmount;

  CartData({
    required this.items,
    required this.cartTotalAmount,
  });

  factory CartData.fromJson(Map<String, dynamic> json) {
    return CartData(
      items: (json['items'] as List?)
          ?.map((item) => CartItem.fromJson(item))
          .toList() ??
          [],
      cartTotalAmount: (json['cart_total_amount'] ?? 0).toDouble(),
    );
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

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    required this.itemTotal,
    required this.product,
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
    );
  }
}

class CartProduct {
  final int id;
  final String name;
  final String price;
  final String discountPrice;
  final int storeId;
  final String primaryImage;

  CartProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.discountPrice,
    required this.storeId,
    required this.primaryImage,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? '0.00',
      discountPrice: json['discount_price'] ?? '0.00',
      storeId: json['store_id'] ?? 0,
      primaryImage: json['primaryimage'] ?? '',
    );
  }

  // Helper method to get display price
  double getDisplayPrice() {
    final discount = double.tryParse(discountPrice) ?? 0;
    final originalPrice = double.tryParse(price) ?? 0;
    return (discount > 0 && discount < originalPrice) ? discount : originalPrice;
  }
}