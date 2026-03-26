class ConversationModel {
  final int conversationId;
  final int? productId;
  final String? productName;
  final String? productImage;
  final String? storeImage;
  final String? storename;
  final int otherUserId;
  final String otherUserName;
  final String? otherUserPhone;
  final String? otherUserImage;
  final String? lastMessage;
  final String? lastMessageImage;
  final String? lastMessageType;
  final String? lastMessageTime;
  final int unreadCount;

  ConversationModel({
    required this.conversationId,
    this.productId,
    this.productName,
    this.productImage,
    this.storeImage,
    this.storename,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhone,
    this.otherUserImage,
    this.lastMessage,
    this.lastMessageImage,
    this.lastMessageType,
    this.lastMessageTime,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      conversationId: json['conversation_id'] ?? 0,
      productId: json['product_id'],
      productName: json['product_name'],
      productImage: json['product_image'],
      storeImage: json['store_image'],
      storename: json['store_name'],
      otherUserId: json['other_user_id'] ?? 0,
      otherUserName: json['other_user_name'] ?? 'Unknown User',
      otherUserPhone: json['other_user_phone'],
      otherUserImage: json['other_user_image'],
      lastMessage: json['last_message'],
      lastMessageImage: json['last_message_image'],
      lastMessageType: json['last_message_type'],
      lastMessageTime: json['last_message_time'],
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}