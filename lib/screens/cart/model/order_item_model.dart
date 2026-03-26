class OrderItemModel {
  final int productId; // Add this field
  final String productName;
  final String image;
  final int quantity;
  final Map<String, dynamic>? variant;

  final double price;

  OrderItemModel({
    required this.productId, // Add to constructor
    required this.productName,
    required this.image,
    required this.quantity,
    required this.price,
    this.variant,

  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['product_id'] ?? 0, // Extract product_id from JSON
      productName: json['product_name'] ?? '',
      image: json['image'] ?? '',
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      variant: json['variant'] != null
          ? Map<String, dynamic>.from(json['variant'])
          : null,

    );
  }
}