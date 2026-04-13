// import 'package:flutter/material.dart';
//
// import '../../services/api_service.dart';
// import 'ConversationScreen.dart';
// import 'chat_service.dart';
// import 'conversation_model.dart';
//
// class ChatListScreen extends StatefulWidget {
//   const ChatListScreen({super.key});
//
//   @override
//   State<ChatListScreen> createState() => _ChatListScreenState();
// }
//
// class _ChatListScreenState extends State<ChatListScreen> {
//   List<ConversationModel> conversations = [];
//   bool _isLoading = true; // ← tracks whether fetch is in progress
//
//   @override
//   void initState() {
//     super.initState();
//     loadConversations();
//   }
//
//   Future<void> loadConversations() async {
//     setState(() => _isLoading = true); // start loading
//
//     final data = await ChatService.getConversations();
//
//     setState(() {
//       conversations = data
//           .map((e) => ConversationModel.fromJson(e))
//           .toList();
//       _isLoading = false; // done loading
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final cs     = Theme.of(context).colorScheme;
//     final tt     = Theme.of(context).textTheme;
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Scaffold(
//       backgroundColor: cs.surface,
//       appBar: AppBar(
//         title: Text(
//           'Chats',
//           style: tt.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold, color: cs.onSurface),
//         ),
//         backgroundColor: cs.surface,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//       ),
//       body: _buildBody(cs, tt, isDark),
//     );
//   }
//
//   Widget _buildBody(ColorScheme cs, TextTheme tt, bool isDark) {
//     // ── 1. Still fetching ────────────────────────────────────────────────────
//     if (_isLoading) {
//       return Center(
//         child: CircularProgressIndicator(color: cs.primary),
//       );
//     }
//
//     // ── 2. Loaded but no conversations ──────────────────────────────────────
//     if (conversations.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 90,
//               height: 90,
//               decoration: BoxDecoration(
//                 color: isDark ? Colors.white12 : Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(24),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: Icon(
//                 Icons.chat_bubble_outline_rounded,
//                 size: 42,
//                 color: cs.onSurfaceVariant,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               "No Conversations Yet",
//               style: tt.titleMedium?.copyWith(
//                   fontWeight: FontWeight.w700, color: cs.onSurface),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               "Start a chat to see it here",
//               style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
//             ),
//           ],
//         ),
//       );
//     }
//
//     // ── 3. Has conversations ─────────────────────────────────────────────────
//     return RefreshIndicator(
//       onRefresh: loadConversations,
//       color: cs.primary,
//       child: ListView.separated(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         itemCount: conversations.length,
//         separatorBuilder: (_, __) =>
//             Divider(height: 1, color: Colors.grey.shade200),
//         itemBuilder: (context, index) {
//           final chat = conversations[index];
//           final imageUrl =
//               "${ApiService.ImagebaseUrl}${ApiService.profile_image_URL}${chat.otherUserImage}";
//
//           return InkWell(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ChatDetailScreen(
//                     name: chat.otherUserName,
//                     image: imageUrl,
//                     conversationId: chat.conversationId,
//                   ),
//                 ),
//               );
//             },
//             borderRadius: BorderRadius.circular(12),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               child: Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 24,
//                     backgroundColor: Colors.grey.shade200,
//                     backgroundImage: NetworkImage(imageUrl),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           chat.otherUserName,
//                           style: tt.bodyMedium?.copyWith(
//                               fontWeight: FontWeight.w700,
//                               color: cs.onSurface),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           chat.lastMessage ?? "Start chatting",
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: tt.bodySmall?.copyWith(
//                               color: cs.onSurfaceVariant),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:ecom/extensions/context_extension.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'ConversationScreen.dart';
import 'chat_service.dart';
import 'conversation_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ConversationModel> conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadConversations();
  }

  Future<void> loadConversations() async {
    setState(() => _isLoading = true);

    final data = await ChatService.getConversations();

    setState(() {
      conversations = data
          .map((e) => ConversationModel.fromJson(e))
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          context.tr('txt_chat'),
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _buildBody(cs, tt, isDark),
    );
  }

  Widget _buildBody(ColorScheme cs, TextTheme tt, bool isDark) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: cs.primary),
      );
    }

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 42,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('txt_no_conversation'),
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('txt_start_chat'),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadConversations,
      color: cs.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: conversations.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final chat = conversations[index];

          // Build image URL for product or user
          String imageUrl;
          if (chat.productImage != null && chat.productImage!.isNotEmpty) {
            imageUrl = "${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${chat.productImage}";
          } else {
            imageUrl = "${ApiService.ImagebaseUrl}${ApiService.profile_image_URL}${chat.otherUserImage ?? ''}";
          }

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    productname: chat.productName,
                    productimage: chat.productImage,
                    name: chat.storename.toString(),
                    image: imageUrl,
                    conversationId: chat.conversationId,
                    // productId: chat.productId, // Pass product ID if needed
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product/User Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : null,
                        child: imageUrl.isEmpty
                            ? Text(
                          chat.otherUserName.isNotEmpty
                              ? chat.otherUserName[0].toUpperCase()
                              : "?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        )
                            : null,
                      ),
                      // if (chat.unreadCount > 0)
                      //   Positioned(
                      //     right: 0,
                      //     top: 0,
                      //     child: Container(
                      //       padding: const EdgeInsets.all(4),
                      //       decoration: const BoxDecoration(
                      //         color: Colors.red,
                      //         shape: BoxShape.circle,
                      //       ),
                      //       constraints: const BoxConstraints(
                      //         minWidth: 18,
                      //         minHeight: 18,
                      //       ),
                      //       child: Text(
                      //         chat.unreadCount > 9 ? '9+' : chat.unreadCount.toString(),
                      //         style: const TextStyle(
                      //           color: Colors.white,
                      //           fontSize: 10,
                      //           fontWeight: FontWeight.bold,
                      //         ),
                      //         textAlign: TextAlign.center,
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Chat Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Name
                        Text(
                          chat.storename.toString(),
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),

                        const SizedBox(height: 2),

                        // Product Name (if available)
                        if (chat.productName != null && chat.productName!.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 12,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  chat.productName!,
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 4),

                        // Last Message
                        if (chat.lastMessage != null && chat.lastMessage!.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.message_outlined,
                                size: 12,
                                color: cs.onSurfaceVariant.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  chat.lastMessage!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.bodySmall?.copyWith(
                                    color: chat.unreadCount > 0
                                        ? cs.onSurface
                                        : cs.onSurfaceVariant,
                                    fontWeight: chat.unreadCount > 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 4),

                        // Time
                        if (chat.lastMessageTime != null)
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 10,
                                color: cs.onSurfaceVariant.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTime(chat.lastMessageTime!),
                                style: tt.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: cs.onSurfaceVariant.withOpacity(0.7),
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
          );
        },
      ),
    );
  }

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return context.tr('txt_just_now');
      }
    } catch (e) {
      return dateTimeString;
    }
  }
}