import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'controller/order_services.dart';
import 'model/order_item_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  (String, Color) getOrderStatus(int status) {
    switch (status) {
      case 1:
        return ("Pending", Colors.orange);
      case 2:
        return ("Accepted", Colors.blue);
      case 3:
        return ("Completed", Colors.green);
      case 4:
        return ("Cancelled", Colors.red);
      default:
        return ("Unknown", Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text("Order #$orderId")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: OrderService.getOrderDetail(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Failed to load order"));
          }

          final order = snapshot.data!;
          final List itemsJson = order['items'] ?? [];
          final items = itemsJson
              .map((e) => OrderItemModel.fromJson(e))
              .toList();
          final statusData = getOrderStatus(order['status']);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 🔹 ORDER SUMMARY
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row("Order ID", "#${order['order_id']}"),
                      Row(
                        children: [
                          Text(
                            "Status",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusData.$2.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusData.$1,
                              style: TextStyle(
                                color: statusData.$2,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      _row("Payment", order['payment_type'].toUpperCase()),
                      // _row("Status", order['status'] == 1 ? "Placed" : "Pending"),
                      _row("Total", "₹${order['total_amount']}"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 DELIVERY ADDRESS
              Text(
                "Delivery Address",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(order['delivery_address'] ?? ''),
              const Divider(height: 32),

              // 🔹 ITEMS
              Text("Items", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),

              ...items.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${item.image}',
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image),
                      ),
                    ),
                    title: Text(item.productName),
                    subtitle: Text("Quantity: ${item.quantity}"),
                    trailing: Text(
                      "₹${item.price}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 TOTAL FOOTER
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Grand Total: ₹${order['total_amount']}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
