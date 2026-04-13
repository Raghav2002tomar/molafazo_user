import 'dart:convert';
import 'dart:io';
import 'package:ecom/extensions/context_extension.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../chat/ConversationScreen.dart';
import '../chat/chat_service.dart';
import 'controller/order_services.dart';
import 'model/order_item_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = false;

  (String, Color) getOrderStatus(int status) {
    switch (status) {
      case 1:
        return ("Pending", const Color(0xFFF59E0B));
      case 2:
        return ("Accepted", const Color(0xFF3B82F6));
      case 3:
        return ("Completed", const Color(0xFF22C55E));
      case 4:
        return ("Cancelled", const Color(0xFFEF4444));
      default:
        return ("Unknown", Colors.grey);
    }
  }

  String formatPrice(dynamic price) {
    if (price == null) return '0';
    final num value = num.tryParse(price.toString()) ?? 0;
    if (value % 1 == 0) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(2);
    }
  }

  dynamic _getOrderValue(Map<String, dynamic> order, List<String> keys, {dynamic defaultValue = ''}) {
    for (var key in keys) {
      if (order.containsKey(key) && order[key] != null) {
        return order[key];
      }
    }
    return defaultValue;
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return 'Order date not available';
    String dateStr = raw.toString();
    if (dateStr.isEmpty) return 'Order date not available';
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      final formattedDate = _formatDate(dt);
      final formattedTime = _formatTime(dt);

      if (diff.inDays < 7) {
        if (diff.inDays > 0) return '$formattedDate • ${diff.inDays}d ago';
        if (diff.inHours > 0) return '$formattedDate • ${diff.inHours}h ago';
        if (diff.inMinutes > 0) return '$formattedDate • ${diff.inMinutes}m ago';
        return '$formattedDate • Just now';
      }
      return '$formattedDate at $formattedTime';
    } catch (_) {
      return 'Order date not available';
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final orderDay = DateTime(dt.year, dt.month, dt.day);

    if (orderDay == today) return 'Today';
    if (orderDay == yesterday) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    int h = dt.hour;
    final m = dt.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '$h:${m.toString().padLeft(2, '0')} $period';
  }

  double _calculateTotal(Map<String, dynamic> order) {
    final List items = order['items'] ?? [];
    double total = 0;

    // Try to get total from order first
    final orderTotal = _getOrderValue(order, ['total_amount', 'total', 'order_total']);
    if (orderTotal != null && orderTotal != '') {
      try {
        return double.parse(orderTotal.toString());
      } catch (e) {
        // Fall through to calculate from items
      }
    }

    // Calculate from items
    for (var item in items) {
      final itemTotal = _getOrderValue(item, ['total', 'item_total', 'price_total']);
      if (itemTotal != null) {
        try {
          total += double.parse(itemTotal.toString());
        } catch (e) {
          final price = _getOrderValue(item, ['price', 'unit_price']);
          final quantity = _getOrderValue(item, ['quantity', 'qty']);
          if (price != null && quantity != null) {
            try {
              total += double.parse(price.toString()) * int.parse(quantity.toString());
            } catch (e) {
              continue;
            }
          }
        }
      } else {
        // Try to calculate from price and quantity
        final price = _getOrderValue(item, ['price', 'unit_price']);
        final quantity = _getOrderValue(item, ['quantity', 'qty']);
        if (price != null && quantity != null) {
          try {
            total += double.parse(price.toString()) * int.parse(quantity.toString());
          } catch (e) {
            continue;
          }
        }
      }
    }
    return total;
  }

  Future<void> _generateReceiptPdf(Map<String, dynamic> order, List<OrderItemModel> items) async {
    final pdf = pw.Document();
    final statusData = getOrderStatus(order['status'] ?? 0);
    final totalAmount = _calculateTotal(order);
    final vendor = order['vendor'];

    // Get order ID for filename
    final orderId = order['order_id']?.toString() ?? widget.orderId.toString();

    // Load custom font for Unicode support (Russian, Tajik, etc.)
    final fontRegular = await pw.Font.ttf(await rootBundle.load('assets/fonts/CirceRounded-Regular.ttf'));
    final fontBold = await pw.Font.ttf(await rootBundle.load('assets/fonts/CirceRounded-Regular.ttf'));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 22, horizontal: 24),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green700,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      context.tr('txt_order_receipt'),
                      style: pw.TextStyle(
                        font: fontBold,
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${context.tr('txt_order')} #${order['order_id']}',
                      style: pw.TextStyle(font: fontRegular, color: PdfColors.white, fontSize: 14),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _formatDateTime(order['created_at'] ?? order['createdAt']),
                      style: pw.TextStyle(font: fontRegular, color: PdfColors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 22),

              // Status
              pw.Row(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: statusData.$2 == const Color(0xFF22C55E)
                          ? PdfColors.green100
                          : statusData.$2 == const Color(0xFFEF4444)
                          ? PdfColors.red100
                          : PdfColors.orange100,
                      borderRadius: pw.BorderRadius.circular(20),
                      border: pw.Border.all(
                        color: statusData.$2 == const Color(0xFF22C55E)
                            ? PdfColors.green700
                            : statusData.$2 == const Color(0xFFEF4444)
                            ? PdfColors.red700
                            : PdfColors.orange700,
                        width: 1,
                      ),
                    ),
                    child: pw.Text(
                      statusData.$1.toUpperCase(),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: statusData.$2 == const Color(0xFF22C55E)
                            ? PdfColors.green800
                            : statusData.$2 == const Color(0xFFEF4444)
                            ? PdfColors.red800
                            : PdfColors.orange800,
                      ),
                    ),
                  ),
                  pw.Spacer(),
                  pw.Text(
                    '${context.tr('txt_payment')}: ${(order['payment_type']?.toString() ?? 'N/A').toUpperCase()}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.SizedBox(height: 22),
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 16),

              // Store Information
              _pdfSectionTitle(context.tr('txt_store_info'), fontBold),
              pw.SizedBox(height: 10),
              _pdfRow(context.tr('txt_store_name'), vendor?['store_name']?.toString() ?? 'N/A', fontRegular, fontBold),
              _pdfRow(context.tr('txt_store_address'), vendor?['store_address']?.toString() ?? 'N/A', fontRegular, fontBold),
              _pdfRow(context.tr('txt_vendor'), vendor?['vendor_name']?.toString() ?? 'N/A', fontRegular, fontBold),
              _pdfRow(context.tr('txt_contact'), vendor?['vendor_mobile']?.toString() ?? 'N/A', fontRegular, fontBold),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 16),

              // Order Information
              _pdfSectionTitle(context.tr('txt_order_info'), fontBold),
              pw.SizedBox(height: 10),
              _pdfRow(context.tr('txt_order_id'), '#${order['order_id']}', fontRegular, fontBold),
              _pdfRow(context.tr('txt_order_date'), _formatDateTime(order['created_at'] ?? order['createdAt']), fontRegular, fontBold),
              _pdfRow(context.tr('txt_payment_method'), (order['payment_type']?.toString() ?? 'N/A').toUpperCase(), fontRegular, fontBold),
              _pdfRow(context.tr('txt_delivery_type'), order['delivery_method'] == 'store_pickup' ? context.tr('title_store_pickup') : context.tr('txt_home_delivery'), fontRegular, fontBold),
              if (order['delivery_method'] != 'store_pickup')
                _pdfRow(context.tr('txt_delivery_address'), order['delivery_address']?.toString() ?? context.tr('txt_no_address_provided'), fontRegular, fontBold),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 16),

              // Items
              _pdfSectionTitle(context.tr('txt_orders_item'), fontBold),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text(context.tr('txt_product'), style: pw.TextStyle(font: fontBold, fontSize: 11, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text(context.tr('txt_qty'), style: pw.TextStyle(font: fontBold, fontSize: 11, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 2, child: pw.Text(context.tr('txt_price'), style: pw.TextStyle(font: fontBold, fontSize: 11, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.SizedBox(height: 8),
              ...items.map((item) {
                final hasVariant = item.variant != null && item.variant!.isNotEmpty;
                return pw.Column(
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                item.productName,
                                style: pw.TextStyle(font: fontRegular, fontSize: 11, fontWeight: pw.FontWeight.bold),
                              ),
                              if (hasVariant) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  _getVariantDisplay(item.variant!),
                                  style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600),
                                ),
                              ],
                            ],
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            '${item.quantity}',
                            style: pw.TextStyle(font: fontRegular, fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '${formatPrice(item.price)} c.',
                            style: pw.TextStyle(font: fontRegular, fontSize: 11),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                  ],
                );
              }).toList(),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 14),

              // Subtotal and Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                    width: 200,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('${context.tr('txt_subtotal')}:', style: pw.TextStyle(font: fontRegular, fontSize: 11)),
                            pw.Text('${formatPrice(totalAmount)} c.', style: pw.TextStyle(font: fontRegular, fontSize: 11)),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('${context.tr('txt_shipping')}:', style: pw.TextStyle(font: fontRegular, fontSize: 11)),
                            pw.Text('Free', style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.green700)),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Divider(),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              context.tr('txt_total_caps'),
                              style: pw.TextStyle(font: fontBold, fontSize: 14, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              '${formatPrice(totalAmount)} c.',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 36),

              // Footer
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text(
                  context.tr('thanks_for_shopping'),
                  style: pw.TextStyle(font: fontRegular, fontSize: 12, color: PdfColors.grey600),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  context.tr('for_queries_contact'),
                  style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();

    // Create unique filename with order ID and timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'receipt_order_${orderId}_$timestamp.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('txt_receipt_generate')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt, size: 48, color: Color(0xFF22C55E)),
              const SizedBox(height: 12),
              Text('${context.tr('txt_receipt_for_order')} #$orderId'),
              const SizedBox(height: 8),
              Text(
                context.tr('receipt_generate_success'),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('txt_close')),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Printing.sharePdf(bytes: bytes, filename: fileName);
              },
              icon: const Icon(Icons.share),
              label: Text(context.tr('txt_share')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
              ),
            ),
          ],
        ),
      );
    }
  }

  pw.Widget _pdfRow(String label, String value, pw.Font regularFont, pw.Font boldFont) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 140,
          child: pw.Text(
            label,
            style: pw.TextStyle(font: regularFont, fontSize: 11, color: PdfColors.grey600),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: regularFont, fontSize: 11, ),
          ),
        ),
      ],
    ),
  );

  pw.Widget _pdfSectionTitle(String title, pw.Font boldFont) => pw.Text(
    title,
    style: pw.TextStyle(
      font: boldFont,
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey800,
    ),
  );


  String _getVariantDisplay(Map<String, dynamic> variant) {
    if (variant.isEmpty) return '';
    final List<String> variantParts = [];
    variant.forEach((key, value) {
      variantParts.add('$key: $value');
    });
    return variantParts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${context.tr('txt_order')} #${widget.orderId}",
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: OrderService.getOrderDetail(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF22C55E)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                    ),
                    child: Text(context.tr('txt_retry')),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('txt_failed_to_load_order'),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final order = snapshot.data!;
          final List itemsJson = order['items'] ?? [];
          final vendor = order['vendor'];
          final int status = order['status'] ?? 0;
          final String deliveryMethod = order['delivery_method'] ?? '';
          final items = itemsJson.map((e) => OrderItemModel.fromJson(e)).toList();
          final statusData = getOrderStatus(status);
          final totalAmount = _calculateTotal(order);

          final orderDate = _formatDateTime(order['created_at'] ?? order['createdAt']);
          final paymentType = order['payment_type']?.toString().toUpperCase() ?? 'N/A';
          final deliveryAddress = order['delivery_address']?.toString() ?? 'No address provided';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                _buildStatusCard(order['order_id'].toString(), orderDate, statusData, totalAmount),
                const SizedBox(height: 12),
                _buildStoreCard(vendor),
                const SizedBox(height: 12),
                _buildInfoCard(paymentType, deliveryAddress, deliveryMethod),
                const SizedBox(height: 12),
                _buildDeliveryCard(deliveryMethod),
                const SizedBox(height: 12),
                _buildItemsCard(items),
                const SizedBox(height: 12),
                _buildTotalCard(totalAmount),
                const SizedBox(height: 12),
                _buildReceiptButton(order, items),
                if (status == 3) ...[
                  const SizedBox(height: 16),
                  _buildReviewSection(context, order, items.first),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(String orderId, String orderDate, (String, Color) statusData, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusData.$2.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusData.$2.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: statusData.$2, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusData.$1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusData.$2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                "${context.tr('txt_order')} #$orderId",
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderDate,
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
              Text(
                "${formatPrice(totalAmount)} c.",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF22C55E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic>? vendor) {
    if (vendor == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            context.tr('txt_store_information'),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.store_rounded, context.tr('txt_store_name'), vendor['store_name']?.toString() ?? 'N/A'),
          const SizedBox(height: 8),
          _infoRow(Icons.location_on_rounded, context.tr('txt_store_address'), vendor['store_address']?.toString() ?? 'N/A'),
          const SizedBox(height: 8),
          _infoRow(Icons.person_outline_rounded, context.tr('txt_vendor'), vendor['vendor_name']?.toString() ?? 'N/A'),
          const SizedBox(height: 8),
          _infoRow(Icons.phone_outlined, context.tr('txt_phone'), vendor['vendor_mobile']?.toString() ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String paymentType, String deliveryAddress, String deliveryMethod) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            context.tr('txt_order_details'),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.payment_rounded, context.tr('txt_payment_method'), paymentType),
          const SizedBox(height: 8),
          _infoRow(
            deliveryMethod == 'store_pickup' ? Icons.store_rounded : Icons.location_on_rounded,
            context.tr('txt_delivery_address'),
            deliveryAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(String deliveryMethod) {
    final isPickup = deliveryMethod == 'store_pickup';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPickup ? Icons.store_rounded : Icons.local_shipping_rounded,
                size: 20,
                color: isPickup ? Colors.orange.shade700 : Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('txt_delivery_type'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPickup ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPickup ? context.tr('txt_self_pickup') : context.tr('txt_home_delivery'),
                  style: TextStyle(
                    color: isPickup ? Colors.orange.shade700 : Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isPickup
                ? context.tr('txt_self_pickup_order')
                : context.tr('txt_order_will_deliver'),
            style: TextStyle(
              fontSize: 13,
              color: isPickup ? Colors.orange.shade700 : Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(List<OrderItemModel> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('txt_order_items'),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.length - 1;
            return Column(
              children: [
                _buildItemTile(item),
                if (!isLast) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildItemTile(OrderItemModel item) {
    final hasVariant = item.variant != null && item.variant!.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 64,
            height: 64,
            color: Colors.grey.shade100,
            child: Image.network(
              '${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${item.image}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              if (hasVariant) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    _getVariantDisplay(item.variant!),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Qty: ${item.quantity}",
                  style: const TextStyle(fontSize: 11, color: Color(0xFF22C55E), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${formatPrice(item.price)} c.",
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              "${item.quantity} item${item.quantity > 1 ? 's' : ''}",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalCard(double totalAmount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text(
            context.tr('txt_total_amount'),
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black54),
          ),
          Text(
            "${formatPrice(totalAmount)} c.",
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF22C55E)),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptButton(Map<String, dynamic> order, List<OrderItemModel> items) {
    return GestureDetector(
      onTap: () => _generateReceiptPdf(order, items),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, color: Color(0xFF22C55E), size: 20),
            SizedBox(width: 8),
            Text(
              context.tr('txt_download_receipt'),
              style: TextStyle(
                color: Color(0xFF22C55E),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSection(BuildContext context, Map<String, dynamic> order, OrderItemModel firstItem) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ReviewForm(
        orderId: order['order_id'] ?? widget.orderId,
        productId: firstItem.productId,
        productName: firstItem.productName,
        productImage: firstItem.image,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

// ==================== REVIEW FORM WIDGET ====================

class ReviewForm extends StatefulWidget {
  final int orderId;
  final int productId;
  final String productName;
  final String productImage;

  const ReviewForm({
    super.key,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productImage,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  double _rating = 0;
  final TextEditingController _comment = TextEditingController();
  List<File> images = [];
  final picker = ImagePicker();
  bool loading = false;

  Future<void> pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        await Permission.camera.request();
      } else {
        await Permission.photos.request();
      }

      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (file == null) return;

      File image = File(file.path);
      File compressed = await compress(image);

      setState(() {
        images.add(compressed);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<File> compress(File file) async {
    final dir = await getTemporaryDirectory();
    final target = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      target,
      quality: 70,
    );
    return File(result!.path);
  }

  Future<void> submit() async {
    if (_rating == 0) {
      show(context.tr('txt_select_rating'));
      return;
    }

    if (_comment.text.isEmpty) {
      show(context.tr('txt_write_review'));
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      String token = await AuthStorage.getToken() ?? "";

      var uri = Uri.parse("${ApiService.baseUrl}/customer/product/review/store");
      var request = http.MultipartRequest("POST", uri);
      request.headers['Authorization'] = "Bearer $token";
      request.fields['product_id'] = widget.productId.toString();
      request.fields['review'] = _comment.text;
      request.fields['rating'] = _rating.toInt().toString();

      for (int i = 0; i < images.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "images[]",
            images[i].path,
          ),
        );
      }
      // 🔥 PRINT REQUEST
      print("===== REQUEST START =====");
      print("URL: ${request.url}");
      print("METHOD: ${request.method}");

      print("\nHEADERS:");
      request.headers.forEach((k, v) => print("$k: $v"));

      print("\nFIELDS:");
      request.fields.forEach((k, v) => print("$k: $v"));

      print("\nFILES:");
      for (var file in request.files) {
        print("Field: ${file.field}");
        print("Filename: ${file.filename}");
      }

      print("===== REQUEST END =====");

      var response = await request.send();
      var res = await http.Response.fromStream(response);
      var data = jsonDecode(res.body);

      setState(() {
        loading = false;
      });

      if (context.mounted) {
        Navigator.pop(context);
        show(data['message']);
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      show(e.toString());
    }
  }

  void show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                "${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${widget.productImage}",
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 55,
                  height: 55,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    context.tr('txt_write_review'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.productName,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
               Text(
                context.tr('txt_your_rating'),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = (i + 1).toDouble();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        i < _rating ? Icons.star : Icons.star_border,
                        size: 32,
                        color: Colors.amber,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
         Text(
          context.tr('txt_your_review'),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _comment,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: context.tr('txt_share_your_experience'),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
             Text(
              context.tr('txt_add_photo'),
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              "${images.length}/5",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 85,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length + 1,
            itemBuilder: (c, i) {
              if (i == images.length) {
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 50,
                                height: 5,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                               Text(
                                context.tr('txt_upload_photo'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                        pickImage(ImageSource.camera);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.camera_alt,
                                                color: Theme.of(context).primaryColor,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                             Text(
                                              context.tr('txt_camera'),
                                              style: TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                        pickImage(ImageSource.gallery);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.photo,
                                                color: Theme.of(context).primaryColor,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                             Text(
                                              context.tr('txt_gallery'),
                                              style: TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo),
                        SizedBox(height: 4),
                        Text("Add", style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(images[i]),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          images.removeAt(i);
                        });
                      },
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: loading ? null : submit,
            child: loading
                ? const SizedBox(
              height: 25,
              width: 25,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                :  Text(
              context.tr('txt_submit_review'),
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}