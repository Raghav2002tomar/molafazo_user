import 'package:flutter/material.dart';

class ChatConversationScreen extends StatelessWidget {
  const ChatConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final messages = [
      {"fromMe": false, "text": "Hi, Kristine! How’s your day going?", "time": "4:35 am"},
      {"fromMe": true, "text": "You know how it goes..", "time": "4:36 am"},
      {"fromMe": false, "text": "Do you want Starbucks?", "time": "4:37 am"},
      {"fromMe": true, "text": "Only if you say man. Let’s see how it is.", "time": "4:45 am"},
      {"fromMe": true, "text": "Great! Thank you, I’m going to work on IRR Calculation.", "time": "4:50 am"},
    ];

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: _CircleAction(
            icon: Icons.keyboard_double_arrow_left_outlined,
            bg: isDark ? Colors.white : Colors.black,
            fg: isDark ? Colors.black : Colors.white,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(
                  "https://randomuser.me/api/portraits/women/44.jpg"),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Kristine Jones",
                    style: TextStyle(
                        color: cs.onBackground,
                        fontWeight: FontWeight.w600)),
                Text("Online",
                    style: TextStyle(
                        fontSize: 12, color: Colors.green.shade400)),
              ],
            )
          ],
        ),
        actions: [

          IconButton(
              icon: Icon(Icons.more_vert, color: cs.onBackground),
              onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final fromMe = msg["fromMe"] as bool;
                return Align(
                  alignment: fromMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: fromMe
                          ? (isDark ? Colors.black : Colors.grey.shade900)
                          : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg["text"].toString(),
                          style: TextStyle(
                            color: fromMe
                                ? Colors.white
                                : cs.onBackground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg["time"].toString(),
                          style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon(Icons.camera_alt_outlined, color: cs.onSurfaceVariant),
                // const SizedBox(width: 12),
                // Icon(Icons.emoji_emotions_outlined, color: cs.onSurfaceVariant),
                // const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: "Type message...",
                      hintStyle: TextStyle(color: cs.onSurfaceVariant),
                      border: InputBorder.none,
                      isDense: true,
                      suffixIcon: Icon(Icons.attach_file_outlined, color: cs.onSurfaceVariant),

                    ),
                  ),
                ),
                // Icon(Icons.attach_file_outlined, color: cs.onSurfaceVariant),
                // const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _CircleAction(
                    icon: Icons.send_rounded,
                    bg: isDark ? Colors.white : Colors.black,
                    fg: isDark ? Colors.black : Colors.white,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                // CircleAvatar(
                //
                //   radius: 22,
                //   backgroundColor: isDark? Colors.white: Colors.black,
                //   child: const Icon(Icons.send_rounded, color: Colors.white),
                // ),
              ],
            ),
          )

        ],
      ),
    );
  }
}
class _CircleAction extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: fg, size: 20),
        ),
      ),
    );
  }
}
