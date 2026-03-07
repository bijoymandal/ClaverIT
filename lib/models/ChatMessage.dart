class ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final bool isSeen;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.isSeen = false,
  });
}
