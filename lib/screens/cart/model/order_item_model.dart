class OrderItemModel {
  final String productName;
  final String image;
  final int quantity;
  final double price;

  OrderItemModel({
    required this.productName,
    required this.image,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productName: json['product_name'] ?? '',
      image: json['image'] ?? '',
      quantity: int.parse(json['quantity'].toString()),
      price: double.parse(json['price'].toString()),
    );
  }
}
