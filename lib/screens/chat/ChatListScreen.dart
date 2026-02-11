import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../auth/LoginScreen.dart';
import 'ConversationScreen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {

  @override
  void initState() {
    // TODO: implement initState
    _loadChat();
    super.initState();
  }
  Future<void> _loadChat() async {

    final token = await AuthStorage.getToken();
    if (token == null) {
      // User not logged in, redirect to login
      if (mounted) {
        // Navigator.pushReplacementNamed(context, '/login');
        Navigator.push(context, MaterialPageRoute(builder: (context)=> AuthScreen()));
      }
      return;
    }


  }
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Chat", style: TextStyle(color: cs.onBackground)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatConversationScreen(),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color:isDark?  Colors.grey.shade800:  Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(
                      "https://randomuser.me/api/portraits/women/44.jpg",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Kristine Jones",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cs.onBackground)),
                        const SizedBox(height: 4),
                        Text("Last message preview...",
                            style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Text(
                    "4:35 am",
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}