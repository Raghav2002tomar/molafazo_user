import 'order_item_model.dart';

class OrderModel {
  final int orderId;
  final double totalAmount;
  final String paymentType;
  final String createdAt;
  final int status;
  final List<OrderItemModel> products;

  OrderModel({
    required this.orderId,
    required this.totalAmount,
    required this.paymentType,
    required this.createdAt,
    required this.status,
    required this.products,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['order_id'],
      totalAmount: double.parse(json['total_amount'].toString()),
      paymentType: json['payment_type'],
      createdAt: json['created_at'],
      status: json['status'],
      products: (json['products'] as List? ?? [])
          .map((e) => OrderItemModel.fromJson(e))
          .toList(),
    );
  }
}
