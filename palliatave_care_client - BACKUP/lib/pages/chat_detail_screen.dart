import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'dart:convert';
import '../models/chat_models.dart'; // Adjust import path

class ChatDetailScreen extends StatefulWidget {
  final String roomId;
  final String otherParticipantName;

  // We need to know who the current user is to align messages left/right
  final String currentUserId; 

  const ChatDetailScreen({
    super.key,
    required this.roomId,
    required this.otherParticipantName,
    required this.currentUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  StompClient? stompClient;

  @override
  void initState() {
    super.initState();
    _connectAndSubscribe();
  }

  void _connectAndSubscribe() {
    // NOTE: For WebSocket, use 'ws://' not 'http://'
    // For your Render deployment, use 'wss://' for secure websockets
    final String websocketUrl = "wss://palliativecare-k6g2.onrender.com/ws";
    // final String websocketUrl = "ws://10.0.2.2:8080/ws"; // For Android emulator

    stompClient = StompClient(
      config: StompConfig(
        url: websocketUrl,
        onConnect: _onConnectCallback,
        onWebSocketError: (dynamic error) => print(error.toString()),
        stompConnectHeaders: {'Authorization': 'Bearer your_jwt_token_here'}, // Add auth if needed
        webSocketConnectHeaders: {'Authorization': 'Bearer your_jwt_token_here'}, // Add auth if needed
      ),
    );

    stompClient!.activate();
  }

  void _onConnectCallback(StompFrame connectFrame) {
    // Subscription to the specific room topic
    stompClient!.subscribe(
      destination: '/topic/room/${widget.roomId}',
      callback: (frame) {
        if (frame.body != null) {
          final Map<String, dynamic> result = json.decode(frame.body!);
          final newMessage = ChatMessage.fromJson(result);
          
          setState(() {
            _messages.add(newMessage);
          });
        }
      },
    );
    
    // Send a JOIN message when connecting
    final joinMessage = ChatMessage(
      content: '${widget.currentUserId} has joined!',
      sender: widget.currentUserId,
      roomId: widget.roomId,
    );
    stompClient!.send(
      destination: '/app/chat.addUser',
      body: json.encode(joinMessage.toJson()),
    );
  }

  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isNotEmpty && stompClient != null && stompClient!.connected) {
      final chatMessage = ChatMessage(
        content: messageText,
        sender: widget.currentUserId,
        roomId: widget.roomId,
      );

      stompClient!.send(
        destination: '/app/chat.send',
        body: json.encode(chatMessage.toJson()),
      );
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    stompClient?.deactivate();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherParticipantName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                // Align message bubble based on the sender
                final isMyMessage = message.sender == widget.currentUserId;
                return _MessageBubble(message: message, isMyMessage: isMyMessage);
              },
            ),
          ),
          _MessageInputField(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// Widget for the text input field
class _MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInputField({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}

// Widget for an individual message bubble
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMyMessage;

  const _MessageBubble({required this.message, required this.isMyMessage});

  @override
  Widget build(BuildContext context) {
    // Show JOIN/LEAVE messages in the center
    if (message.content.contains('has joined!')) { // Simple check for join message
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(message.content, style: const TextStyle(color: Colors.grey)),
          ),
        );
    }
    
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMyMessage ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          message.content,
          style: TextStyle(color: isMyMessage ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}