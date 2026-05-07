import 'dart:async';
import 'dart:io';
import 'package:ecom/extensions/context_extension.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../../providers/notification_handler.dart';
import '../../services/api_service.dart';
import 'chat_service.dart';
import 'message_model.dart';


class ChatDetailScreen extends StatefulWidget {

  final String name;
  final String image;
  final String? productname;
  final String? productimage;
  final int conversationId;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.image,
     this.productname,
     this.productimage,
    required this.conversationId,
  });

  @override
  State<ChatDetailScreen> createState() =>
      _ChatDetailScreenState();
}

class _ChatDetailScreenState
    extends State<ChatDetailScreen> {

  final TextEditingController controller =
  TextEditingController();

  final ScrollController scrollController =
  ScrollController();

  final ImagePicker picker = ImagePicker();

  List<MessageModel> messages = [];

  Timer? timer;
  bool isBlocked = false;
  bool blockedByMe = false;
  bool blockedByOtherUser = false;
  int? chatUserId;
  bool blockLoading = false;
  bool isLoading = true;
  final TextEditingController reportCtrl = TextEditingController();
  final List<String> blockedWords = [

    /// ================= ENGLISH =================
    'abuse','abusive','abusing',
    'scam','fraud','cheat','fake',
    'idiot','stupid','dumb','moron','loser',
    'kill','die','murder','suicide',
    'sex','nude','porn','xxx','naked',
    'fuck','shit','bitch','asshole','bastard','damn','hell',
    'slut','whore','dick','pussy','cock',

    /// ================= RUSSIAN =================
    'дурак','идиот','тупой','дебил',
    'убью','убить','сдохни','умри',
    'секс','порно','голый','раздетый',
    'мошенник','обман','скам',
    'блять','сука','хуй','пизда','ебать',

    /// ================= TAJIK =================
    'ахмак','аблах','девона','беақл',
    'куштан','мир','мемирам',
    'секc','урён','фоҳиша',
    'қаллоб','фиреб','дурӯғ',

  ];

  String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Zа-яА-Я0-9]'), '');
  }

  bool containsBadWords(String text) {
    final normalized = normalizeText(text);

    return blockedWords.any((word) {
      final cleanWord = normalizeText(word);
      return normalized.contains(cleanWord);
    });
  }

  String? selectedReportReason;
  bool reportLoading = false;

  final List<String> reportReasonKeys = [
    'reason_abusive',
    'reason_spam',
    'reason_fake',
    'reason_inappropriate',
    'reason_harassment',
    'reason_other',
  ];
  Future<void> showReportDialog() async {
    selectedReportReason = null;
    reportCtrl.clear();

    final tr = Provider.of<TranslateProvider>(
      context,
      listen: false,
    ).t;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(tr('txt_report_user')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...reportReasonKeys.map((reasonKey) {
                      return RadioListTile<String>(
                        value: reasonKey,
                        groupValue: selectedReportReason,
                        contentPadding: EdgeInsets.zero,
                        title: Text(tr(reasonKey)),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedReportReason = value;
                          });
                        },
                      );
                    }).toList(),

                    const SizedBox(height: 10),

                    TextField(
                      controller: reportCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: tr('txt_type_custom_reason'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: reportLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(tr('txt_cancel')),
                ),
                ElevatedButton(
                  onPressed: reportLoading
                      ? null
                      : () async {
                    final customText = reportCtrl.text.trim();

                    if (selectedReportReason == null &&
                        customText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tr('txt_select_report_reason')),
                        ),
                      );
                      return;
                    }

                    final description = [
                      if (selectedReportReason != null)
                        tr(selectedReportReason!),
                      if (customText.isNotEmpty) customText,
                    ].join(" - ");

                    setDialogState(() {
                      reportLoading = true;
                    });

                    try {
                      final data = await ChatService.reportUser(
                        reportedUserId: chatUserId!,
                        description: description,
                      );

                      if (mounted) Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            data['message']?.toString() ??
                                tr('txt_report_sent'),
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tr('txt_something_wrong')),
                        ),
                      );
                    } finally {
                      reportLoading = false;
                    }
                  },
                  child: reportLoading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(tr('txt_submit')),
                ),
              ],
            );
          },
        );
      },
    );
  }
  final baseImageUrl =
      "${ApiService.ImagebaseUrl}${ApiService.chat_images_URL}/";

  /// ================= INIT =================

  @override
  void initState() {
    super.initState();

    loadMessages();

    controller.addListener(() {
      setState(() {});
    });

    timer = Timer.periodic(
      const Duration(seconds: 2),
          (_) => loadMessages(),
    );
  }

  Future<void> pickCameraImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (picked == null) return;

    final file = File(picked.path);

    final valid = await isValidChatImage(file);
    if (!valid) return;

    await ChatService.sendImage(
      conversationId: widget.conversationId,
      imagePath: picked.path,
    );

    loadMessages();
  }

  String buildImageUrl(String? image) {

    if (image == null || image.isEmpty) {
      return "";
    }

    if (image.startsWith("http")) {
      return image;
    }

    return "$baseImageUrl$image";
  }




  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    scrollController.dispose();
    reportCtrl.dispose();
    super.dispose();
  }

  /// ================= LOAD =================

  Future<void> loadMessages() async {
    try {
      final data = await ChatService.getMessagesWithStatus(
        widget.conversationId,
      );

      final list = data['messages'] ?? [];

      final newMessages = list
          .map<MessageModel>((e) => MessageModel.fromJson(e))
          .toList();

      if (mounted) {
        setState(() {
          messages = newMessages;
          isBlocked = data['is_blocked'] == true;
          blockedByMe = data['blocked_by_me'] == true;
          blockedByOtherUser = data['blocked_by_other_user'] == true;
          chatUserId = data['chat_user_id'];
          isLoading = false;
        });
      }

      scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  Future<void> toggleBlockUser() async {
    if (chatUserId == null || blockLoading) return;
    final tr = Provider.of<TranslateProvider>(
      context,
      listen: false,
    ).t;
    setState(() {
      blockLoading = true;
    });

    try {
      final data = await ChatService.toggleBlockUser(
        blockedUserId: chatUserId!,
      );

      if (data['status'] == true) {
        setState(() {
          isBlocked = data['is_blocked'] == true;
          blockedByMe = data['is_blocked'] == true;
          blockedByOtherUser = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']?.toString() ?? ''),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(tr('txt_something_wrong')),
         ),
      );
    } finally {
      if (mounted) {
        setState(() {
          blockLoading = false;
        });
      }
    }
  }
  /// ================= SCROLL =================

  void scrollToBottom() {

    if (!scrollController.hasClients)
      return;

    Future.delayed(
      const Duration(milliseconds: 100),
          () {

        scrollController.animateTo(
          scrollController.position
              .maxScrollExtent,
          duration:
          const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );

      },
    );
  }

  /// ================= SEND MESSAGE =================

  Future<void> sendMessage() async {
    final tr = Provider.of<TranslateProvider>(
      context,
      listen: false,
    ).t;

    final text = controller.text.trim();

    if (text.isEmpty) return;

    if (containsBadWords(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('txt_message_not_allowed')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    controller.clear();

    setState(() {
      messages.add(
        MessageModel(
          id: 0,
          conversationId: widget.conversationId,
          senderId: 0,
          isMe: true,
          senderName: "",
          senderPhone: "",
          senderImage: "",
          message: text,
          image: null,
          type: "text",
          sendAt: DateTime.now().toString(),
          createdAt: DateTime.now().toString(),
        ),
      );
    });

    scrollToBottom();

    await ChatService.sendMessage(
      conversationId: widget.conversationId,
      message: text,
    );
  }
  Future<bool> isValidChatImage(File file) async {
    final tr = Provider.of<TranslateProvider>(
      context,
      listen: false,
    ).t;

    final ext = path.extension(file.path).toLowerCase();
    final allowedExt = ['.jpg', '.jpeg', '.png', '.webp'];

    if (!allowedExt.contains(ext)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('txt_invalid_image_type')),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final sizeInBytes = await file.length();
    final sizeInMb = sizeInBytes / (1024 * 1024);

    if (sizeInMb > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('txt_image_size_limit')),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }
  /// ================= SEND IMAGE =================

  Future<void> pickImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    final file = File(picked.path);

    final valid = await isValidChatImage(file);
    if (!valid) return;

    await ChatService.sendImage(
      conversationId: widget.conversationId,
      imagePath: picked.path,
    );

    loadMessages();
  }

  /// ================= FORMAT TIME =================

  String formatTime(String? time) {

    if (time == null) return "";

    final date =
    DateTime.parse(time);

    return
      "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  /// ================= PROFILE IMAGE =================

  Widget profileImage(String? image, double size) {

    final cs = Theme.of(context).colorScheme;
    final imageUrl = buildImageUrl(image);

    return CircleAvatar(
      radius: size,
      backgroundColor: cs.surfaceVariant,
      backgroundImage:
      imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
      child: imageUrl.isEmpty
          ? Icon(Icons.person, color: cs.onSurfaceVariant)
          : null,
    );
  }


  /// ================= MESSAGE BUBBLE =================

  Widget messageBubble(MessageModel msg) {

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fromMe = msg.isMe;

    final hasImage = msg.image != null && msg.image!.isNotEmpty;
    final hasText = msg.message != null && msg.message!.trim().isNotEmpty;

    final maxBubbleWidth =
        MediaQuery.of(context).size.width * 0.72;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          /// Avatar
          if (!fromMe)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: profileImage(
                  "${ApiService.ImagebaseUrl}/${ApiService.profile_image_URL}${msg.senderImage}"
                  , 14),
            ),

          /// Bubble
          Flexible(
            child: IntrinsicWidth(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: maxBubbleWidth,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: fromMe
                      ? (isDark ? Colors.white : Colors.black)
                      : cs.surfaceVariant,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft:
                    Radius.circular(fromMe ? 16 : 4),
                    bottomRight:
                    Radius.circular(fromMe ? 4 : 16),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    /// IMAGE (dynamic size)
                    /// IMAGE (click → fullscreen)
                    if (hasImage)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _buildImageMessage(msg.image),

                      ),


                    /// TEXT (dynamic width)
                    if (hasText)
                      Padding(
                        padding: EdgeInsets.only(
                          top: hasImage ? 8 : 0,
                        ),
                        child: Text(
                          msg.message!,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            color: fromMe
                                ? (isDark
                                ? Colors.black
                                : Colors.white)
                                : cs.onSurface,
                          ),
                        ),
                      ),

                    /// TIME
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding:
                        const EdgeInsets.only(top: 4),
                        child: Text(
                          formatTime(msg.sendAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= UI =================


  Widget _buildImageMessage(String? imagePath) {

    final imageUrl = buildImageUrl(imagePath);
    print("Final Image URL = $imageUrl");

    if (imageUrl.isEmpty) {
      return Container(
        width: 200,
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.broken_image, size: 40),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(
              imageUrl: imageUrl,
            ),
          ),
        );
      },
      child: Hero(
        tag: imageUrl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
              maxHeight: 260,
            ),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,

              /// Loading indicator
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;

                return Container(
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              },

              /// Error handling
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.broken_image,
                    size: 40,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {

    final cs =
        Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(

      backgroundColor:
      cs.background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: _CircleAction(
            icon: Icons.arrow_back,
            bg: isDark ? Colors.white : Colors.black,
            fg: isDark ? Colors.black : Colors.white,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          children: [
            // Show product image if available, otherwise user image
            profileImage(
              widget.productimage != null && widget.productimage!.isNotEmpty
                  ? "${ApiService.ImagebaseUrl}/${ApiService.product_images_URL}${widget.productimage}"
                  : widget.image,
              18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onBackground,
                      fontSize: 14,
                    ),
                  ),
                  if (widget.productname != null && widget.productname!.isNotEmpty)
                    Text(
                      widget.productname!,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onBackground.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') {
                toggleBlockUser();
              } else if (value == 'report') {
                if (chatUserId != null) {
                  showReportDialog();
                }
              }
            },
            itemBuilder: (popupContext) {
              final tr = Provider.of<TranslateProvider>(
                context,
                listen: false,
              ).t;

              return [
                PopupMenuItem(
                  value: 'block',
                  child: Text(
                    blockedByMe
                        ? tr('txt_unblock_user')
                        : tr('txt_block_user'),
                  ),
                ),
                PopupMenuItem(
                  value: 'report',
                  child: Text(tr('txt_report_user')),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [

          /// MESSAGE LIST

          Expanded(
            child: isLoading
                ? const Center(
                child:
                CircularProgressIndicator())
                : ListView.builder(
              controller:
              scrollController,
              padding:
              const EdgeInsets
                  .fromLTRB(
                  16,
                  12,
                  16,
                  12),
              itemCount:
              messages.length,
              itemBuilder:
                  (_, index) =>
                  messageBubble(
                      messages[
                      index]),
            ),
          ),

          /// INPUT BAR
          if (isBlocked)
            SafeArea(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                color: cs.surface,
                child: Text(
                  blockedByMe
                      ? context.tr('txt_blocked_by_me')
                      : context.tr('txt_blocked_by_other'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [

                  /// CAMERA BUTTON
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: pickCameraImage,
                      icon: Icon(
                        Icons.camera_alt_rounded,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  /// MAIN INPUT CARD
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: cs.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [

                          /// TEXT FIELD
                          Expanded(
                            child:  TextFormField(
                              controller: controller,
                              minLines: 1,
                              maxLines: 5,
                              style: TextStyle(
                                fontSize: 15,
                                color: cs.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: context.tr('txt_type_a_message'),
                                hintStyle: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 15,
                                ),

                                /// REMOVE ALL BORDERS
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,

                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 0,
                                ),
                              ),
                            ),

                          ),

                          /// GALLERY BUTTON
                          if (controller.text.isEmpty)
                            Container(
                              height: 36,
                              width: 36,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: pickImage,
                                icon: Icon(
                                  Icons.photo_outlined,
                                  color: cs.primary,
                                  size: 20,
                                ),
                              ),
                            ),

                          /// SEND BUTTON
                          if (controller.text.trim().isNotEmpty)
                            Container(
                              height: 38,
                              width: 38,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: sendMessage,
                                icon: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

/// BUTTON

class _CircleAction
    extends StatelessWidget {

  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context) {

    return InkWell(

      onTap: onTap,

      borderRadius:
      BorderRadius.circular(12),

      child: Container(

        height: 42,
        width: 42,

        decoration:
        BoxDecoration(
          color: bg,
          borderRadius:
          BorderRadius.circular(
              12),
        ),

        child: Icon(
          icon,
          color: fg,
          size: 20,
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [

          /// Image Viewer
          Center(
            child: Hero(
              tag: imageUrl,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const CircularProgressIndicator(
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
          ),

          /// Close Button
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
