class ChatConversation {
  final String roomId;
  final String otherParticipantName;
  final String lastMessage;
  final DateTime? timestamp;

  ChatConversation({
    required this.roomId,
    required this.otherParticipantName,
    required this.lastMessage,
    this.timestamp,
  });

  // A 'factory constructor' to create a ChatConversation from JSON
  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      roomId: json['roomId'],
      otherParticipantName: json['otherParticipantName'],
      lastMessage: json['lastMessage'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }
}

// Add this class to your existing chat_models.dart file

// Represents a single message in a conversation
class ChatMessage {
  final String content;
  final String sender;
  final String roomId;
  final String type;
  // You might also want to add timestamp and message type if needed

  ChatMessage({
    required this.content,
    required this.sender,
    required this.roomId,
    required this.type,
  });

  // Create a ChatMessage object from JSON received from the WebSocket
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      content: json['content'],
      sender: json['sender'],
      roomId: json['roomId'],
      type: json['type'],
    );
  }

  // Convert a ChatMessage object to JSON to send to the WebSocket
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'sender': sender,
      'roomId': roomId,
      'type': 'CHAT', // Always send as CHAT type
    };
  }
}