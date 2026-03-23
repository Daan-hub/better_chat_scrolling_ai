enum MessageRole { user, assistant }

class Message {
  final String id;
  final MessageRole role;
  String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == MessageRole.user;
}
