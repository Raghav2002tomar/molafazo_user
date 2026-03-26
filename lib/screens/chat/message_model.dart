class MessageModel {

  final int id;
  final int conversationId;
  final int senderId;

  final bool isMe;

  final String senderName;
  final String senderPhone;
  final String senderImage;

  final String? message;
  final String? image;

  final String type;

  final String? sendAt;
  final String? readAt;
  final String? createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.isMe,
    required this.senderName,
    required this.senderPhone,
    required this.senderImage,
    this.message,
    this.image,
    required this.type,
    this.sendAt,
    this.readAt,
    this.createdAt,
  });

  factory MessageModel.fromJson(
      Map<String, dynamic> json) {

    return MessageModel(

      id: json['id'] ?? 0,

      conversationId:
      json['conversation_id'] ?? 0,

      senderId:
      json['sender_id'] ?? 0,

      isMe:
      json['is_me'] == true,

      senderName:
      json['sender_name']
          ?.toString() ?? "",

      senderPhone:
      json['sender_phone']
          ?.toString() ?? "",

      senderImage:
      json['sender_image']
          ?.toString() ?? "",

      message:
      json['message']
          ?.toString(),

      image:
      json['image']
          ?.toString(),

      type:
      json['type']
          ?.toString() ?? "text",

      sendAt:
      json['send_at']
          ?.toString(),

      readAt:
      json['read_at']
          ?.toString(),

      createdAt:
      json['created_at']
          ?.toString(),
    );
  }

}
