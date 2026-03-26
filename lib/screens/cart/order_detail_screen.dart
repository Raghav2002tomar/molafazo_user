

import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart'; // Add this import

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../chat/ConversationScreen.dart';
import '../chat/chat_service.dart';
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
    String formatPrice(dynamic price) {
      final num value = num.tryParse(price.toString()) ?? 0;

      if (value % 1 == 0) {
        return value.toInt().toString(); // remove .00
      } else {
        return value.toStringAsFixed(2);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Order #$orderId"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Trigger rebuild
              (context as Element).reassemble();
            },
          ),
        ],
      ),
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
          final vendor = order['vendor'];
          final int status = order['status'] ?? 0;

          final items = itemsJson
              .map((e) => OrderItemModel.fromJson(e))
              .toList();
          final statusData = getOrderStatus(status);

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
                          const Text(
                            "Status",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const Spacer(),
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
                      const SizedBox(height: 8),
                      _row("Payment", order['payment_type'].toString().toUpperCase()),
                      _row("Total", "${formatPrice(order['total_amount'])} c."),                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _sectionTitle(context, "Customer Information", true, vendor, items),

              const SizedBox(height: 16),

              // 🔹 DELIVERY ADDRESS
              const Text(
                "Delivery Address",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(order['delivery_address'] ?? 'No address provided'),
                ),
              ),
              const Divider(height: 32),

              // 🔹 ITEMS
              const Text(
                "Items",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

// Update the items section in your build method
              ...items.map(
                    (item) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${item.image}',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Product Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              // Variant Details
                              if (item.variant != null && item.variant!.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getVariantDisplay(item.variant!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
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
                                    "Qty: ${item.quantity}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    "${formatPrice(item.price)} c.",                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).toList(),

              const SizedBox(height: 20),

              // 🔹 TOTAL FOOTER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Grand Total:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${formatPrice(order['total_amount'])} c.",                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 REVIEW SECTION - Only show for completed orders
              if (status == 3) _buildReviewSection(context, order, items.first),
            ],
          );
        },
      ),
    );
  }

// Add this helper method in your class
  String _getVariantDisplay(Map<String, dynamic> variant) {
    if (variant.isEmpty) return '';

    final List<String> variantParts = [];
    variant.forEach((key, value) {
      variantParts.add('$key: $value');
    });

    return variantParts.join(' • ');
  }
  // ==================== REVIEW SECTION ====================

  Widget _buildReviewSection(BuildContext context, Map<String, dynamic> order, OrderItemModel firstItem) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ReviewForm(
        orderId: order['order_id'],
        productId: firstItem.productId,
        productName: firstItem.productName,
        productImage: firstItem.image,
        // v: order['vendor']?['vendor_id'],
      ),
    );
  }

  Widget _sectionTitle(
      BuildContext context,
      String text,
      bool showChat,
      Map<String, dynamic>? vendor,
      List<OrderItemModel> items,
      ) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),

        /// CHAT BUTTON
        if (showChat && vendor != null && items.isNotEmpty)
          InkWell(
            onTap: () async {
              final vendorId = vendor['vendor_id'];
              final vendorName = vendor['store_name'];
              final vendorImage = vendor['vendor_image'];
              final int productId = items.first.productId;
              final productName = items.first.productName;
              final productImage = items.first.image;

              if (vendorId == null) return;

              /// Show loader
              if (!context.mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              try {
                /// Start chat
                final conversationId = await ChatService.startConversation(
                  otherUserId: vendorId,
                  productId: productId,
                );

                if (context.mounted) Navigator.pop(context); // Close loader

                if (conversationId != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        productimage: productImage,
                        productname: productName,
                        name: vendorName ?? "Vendor",
                        image: vendorImage != null
                            ? "${ApiService.ImagebaseUrl}/${ApiService.profile_image_URL}$vendorImage"
                            : "",
                        conversationId: conversationId,
                      ),
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to start conversation"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loader
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chat,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
      ],
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


  /// IMAGE PICKER
  Future<void> pickImage(ImageSource source) async {

    try {

      if(source == ImageSource.camera){
        await Permission.camera.request();
      }else{
        await Permission.photos.request();
      }

      final XFile? file =
      await picker.pickImage(
          source: source,
          imageQuality: 70
      );

      if(file == null) return;

      File image = File(file.path);

      File compressed = await compress(image);

      setState(() {
        images.add(compressed);
      });

    } catch(e){

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()))
      );

    }

  }


  /// IMAGE COMPRESS
  Future<File> compress(File file) async {

    final dir = await getTemporaryDirectory();

    final target =
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final result =
    await FlutterImageCompress.compressAndGetFile(
        file.path,
        target,
        quality: 70
    );

    return File(result!.path);

  }


  /// SUBMIT REVIEW
  Future<void> submit() async {

    if(_rating == 0){
      show("Select rating");
      return;
    }

    if(_comment.text.isEmpty){
      show("Write review");
      return;
    }

    setState(() {
      loading = true;
    });

    try{

      String token = await AuthStorage.getToken() ?? "";

      var uri =
      Uri.parse("${ApiService.baseUrl}/product/review/store");

      var request =
      http.MultipartRequest("POST",uri);

      request.headers['Authorization']="Bearer $token";

      request.fields['product_id'] =
          widget.productId.toString();

      request.fields['review'] =
          _comment.text;

      request.fields['rating'] =
          _rating.toInt().toString();



      /// IMAGES
      for(int i=0;i<images.length;i++){

        request.files.add(
            await http.MultipartFile.fromPath(
                "images[]",
                images[i].path
            )
        );

      }

      var response =
      await request.send();

      var res =
      await http.Response.fromStream(response);

      var data =
      jsonDecode(res.body);


      setState(() {
        loading=false;
      });

      Navigator.pop(context);

      show(data['message']);


    }catch(e){

      setState(() {
        loading=false;
      });

      show(e.toString());

    }

  }


  void show(String msg){

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg))
    );

  }


  /// UI

  @override
  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// HEADER
        Row(
          children: [

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                "${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${widget.productImage}",
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                errorBuilder: (_,__,___)=>Container(
                  width:55,
                  height:55,
                  color:Colors.grey.shade200,
                  child:const Icon(Icons.image),
                ),
              ),
            ),

            const SizedBox(width:12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Write Review",
                    style: TextStyle(
                      fontSize:18,
                      fontWeight:FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height:4),

                  Text(
                    widget.productName,
                    style: TextStyle(
                      color:Colors.grey.shade600,
                      fontSize:13,
                    ),
                  ),

                ],
              ),
            )
          ],
        ),

        const SizedBox(height:20),


        /// RATING CARD

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [

              const Text(
                "Your Rating",
                style: TextStyle(
                    fontWeight: FontWeight.w600),
              ),

              const SizedBox(height:10),

              Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children:
                List.generate(5,(i){

                  return GestureDetector(
                    onTap: (){
                      setState(() {
                        _rating=(i+1).toDouble();
                      });
                    },
                    child: AnimatedContainer(
                      duration:
                      const Duration(milliseconds:200),

                      padding:
                      const EdgeInsets.all(6),

                      child: Icon(
                          i<_rating
                              ? Icons.star
                              : Icons.star_border,
                          size:32,
                          color:Colors.amber
                      ),
                    ),
                  );

                }),
              ),

            ],
          ),
        ),


        const SizedBox(height:18),



        /// COMMENT BOX

        const Text(
          "Your Review",
          style: TextStyle(
              fontWeight:FontWeight.w600),
        ),

        const SizedBox(height:8),

        TextField(
          controller:_comment,
          maxLines:4,
          decoration:
          InputDecoration(

            hintText:"Share your experience...",

            filled:true,

            fillColor:Colors.grey.shade50,

            contentPadding:
            const EdgeInsets.all(14),

            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(14),
              borderSide:
              BorderSide(
                  color:Colors.grey.shade300),
            ),

            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(14),
              borderSide:
              BorderSide(
                  color:Colors.grey.shade300),
            ),

            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(14),
              borderSide:
              BorderSide(
                  color:
                  Theme.of(context)
                      .primaryColor),
            ),

          ),
        ),


        const SizedBox(height:18),



        /// PHOTO TITLE

        Row(
          children: [

            const Text(
              "Add Photos",
              style: TextStyle(
                  fontWeight:FontWeight.w600),
            ),

            const Spacer(),

            Text(
              "${images.length}/5",
              style: TextStyle(
                  color:Colors.grey.shade600),
            )

          ],
        ),


        const SizedBox(height:10),



        /// IMAGE LIST

        SizedBox(
          height:85,
          child: ListView.builder(
            scrollDirection:
            Axis.horizontal,

            itemCount:
            images.length+1,

            itemBuilder:(c,i){

              if(i==images.length){

                return GestureDetector(
                  onTap:(){

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

                              /// TOP HANDLE
                              Container(
                                width: 50,
                                height: 5,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),

                              const Text(
                                "Upload Photo",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 20),

                              Row(
                                children: [

                                  /// CAMERA
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

                                          borderRadius:
                                          BorderRadius.circular(16),

                                          border: Border.all(
                                              color: Colors.grey.shade200
                                          ),

                                        ),

                                        child: Column(
                                          children: [

                                            Container(
                                              padding: const EdgeInsets.all(12),

                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(0.1),

                                                shape: BoxShape.circle,
                                              ),

                                              child: Icon(
                                                Icons.camera_alt,
                                                color: Theme.of(context).primaryColor,
                                                size: 28,
                                              ),
                                            ),

                                            const SizedBox(height: 10),

                                            const Text(
                                              "Camera",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )

                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  /// GALLERY
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

                                          borderRadius:
                                          BorderRadius.circular(16),

                                          border: Border.all(
                                              color: Colors.grey.shade200
                                          ),

                                        ),

                                        child: Column(
                                          children: [

                                            Container(
                                              padding: const EdgeInsets.all(12),

                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(0.1),

                                                shape: BoxShape.circle,
                                              ),

                                              child: Icon(
                                                Icons.photo,
                                                color: Theme.of(context).primaryColor,
                                                size: 28,
                                              ),
                                            ),

                                            const SizedBox(height: 10),

                                            const Text(
                                              "Gallery",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )

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

                    width:80,

                    margin:
                    const EdgeInsets.only(right:10),

                    decoration:BoxDecoration(

                        color:Colors.grey.shade100,

                        borderRadius:
                        BorderRadius.circular(12),

                        border:Border.all(
                            color:
                            Colors.grey.shade300
                        )

                    ),

                    child:
                    Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: const [

                        Icon(Icons.add_a_photo),

                        SizedBox(height:4),

                        Text(
                            "Add",
                            style:
                            TextStyle(fontSize:11)
                        )

                      ],
                    ),

                  ),
                );

              }


              return Stack(
                children:[

                  Container(
                    width:80,

                    margin:
                    const EdgeInsets.only(right:10),

                    decoration:BoxDecoration(

                        image:DecorationImage(
                            image:FileImage(
                                images[i]),
                            fit:BoxFit.cover
                        ),

                        borderRadius:
                        BorderRadius.circular(12)

                    ),
                  ),

                  Positioned(
                      right:4,
                      top:4,
                      child:GestureDetector(

                          onTap:(){

                            setState(() {
                              images.removeAt(i);
                            });

                          },

                          child:
                          const CircleAvatar(
                              radius:11,
                              backgroundColor:
                              Colors.red,
                              child:
                              Icon(Icons.close,
                                  size:14,
                                  color:Colors.white)
                          )

                      )
                  )

                ],
              );

            },
          ),
        ),


        const SizedBox(height:25),



        /// SUBMIT BUTTON

        SizedBox(
          width:double.infinity,
          height:52,

          child:ElevatedButton(

              style:
              ElevatedButton.styleFrom(

                  shape:
                  RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(14)
                  )

              ),

              onPressed:
              loading?null:submit,

              child:
              loading
                  ? const SizedBox(
                  height:25,
                  width:25,
                  child:
                  CircularProgressIndicator(
                      color:Colors.white,
                      strokeWidth:2
                  )
              )
                  : const Text(
                  "Submit Review",
                  style:
                  TextStyle(fontSize:16)
              )

          ),
        )

      ],
    );

  }}