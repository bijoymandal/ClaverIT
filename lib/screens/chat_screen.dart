import 'package:claverit/models/ChatMessage.dart';
import 'package:claverit/screens/chat_screen/widgets/chat_bubble.dart';
import 'package:claverit/screens/chat_screen/widgets/type_indicator.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();

  final List<ChatMessage> messages = [
    ChatMessage(
      text: "Hey! Thanks for connecting.",
      isMe: false,
      time: "10:30 AM",
    ),
    ChatMessage(
      text: "Absolutely! Let's discuss the IoT project.",
      isMe: true,
      time: "10:32 AM",
      isSeen: true,
    ),
    ChatMessage(
      text: "Could you send some details about requirements?",
      isMe: false,
      time: "10:33 AM",
    ),
  ];

  bool isTyping = false;

  void sendMessage() {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      messages.add(ChatMessage(text: controller.text, isMe: true, time: "Now"));
      controller.clear();
      isTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Row(
          children: [
            CircleAvatar(radius: 18),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Pavan Vijay Kumar", style: TextStyle(fontSize: 16)),
                Text(
                  "Online",
                  style: TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          /// MESSAGE LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return ChatBubble(message: msg);
              },
            ),
          ),

          /// TYPING INDICATOR
          if (isTyping)
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TypingIndicator(),
              ),
            ),

          /// MESSAGE INPUT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: const Color(0xFF121212),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (v) {
                        setState(() {
                          isTyping = v.isNotEmpty;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
