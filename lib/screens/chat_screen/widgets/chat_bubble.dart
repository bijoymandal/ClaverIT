import 'package:claverit/models/ChatMessage.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,

      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 260),

        decoration: BoxDecoration(
          color: message.isMe
              ? const Color(0xFF10B981)
              : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: message.isMe ? const Radius.circular(18) : Radius.zero,
            bottomRight: message.isMe ? Radius.zero : const Radius.circular(18),
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.text, style: const TextStyle(color: Colors.white)),

            const SizedBox(height: 4),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),

                if (message.isMe) ...[
                  const SizedBox(width: 4),

                  Icon(
                    message.isSeen ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.isSeen ? Colors.blue : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
