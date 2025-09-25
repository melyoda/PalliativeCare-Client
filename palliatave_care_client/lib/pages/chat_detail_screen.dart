import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:convert';
import '../models/chat_models.dart'; // Adjust import path
import '../services/api_service.dart'; // We need this to get the token

class ChatDetailScreen extends StatefulWidget {
  final String roomId;
  final String otherParticipantName;
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
  final ScrollController _scrollController = ScrollController(); // For auto-scrolling
  StompClient? stompClient;
  final ApiService apiService = ApiService(); // Create an instance of your service
 bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    // _connectAndSubscribe();
    _loadHistoryAndConnect();
  }

Future<void> _connectAndSubscribe() async {
  final String? token = await apiService.getToken();
  if (token == null) {
    print("--- FATAL ERROR: No token found. Cannot connect to WebSocket. ---");
    return;
  }
  
  // 1. Double-check this URL. No typos, no trailing slashes, no '#'
  const String websocketUrl = "wss://palliativecare-k6g2.onrender.com/ws";
  print("--- Attempting to connect to: $websocketUrl ---"); // Add a log to be sure

  stompClient = StompClient(
    config: StompConfig(
      url: websocketUrl,
      onConnect: _onConnectCallback,
      onWebSocketError: (dynamic error) => print('--- WEBSOCKET ERROR: ${error.toString()} ---'),
      
      // 2. This header is for the initial HTTP handshake. It's the most important one for this error.
      webSocketConnectHeaders: {
        'Authorization': 'Bearer $token',
      },
      // 3. This header is for the STOMP protocol frame after the WebSocket is open.
      stompConnectHeaders: {
        'Authorization': 'Bearer $token',
      },
    ),
  );

  stompClient!.activate();
}

 Future<void> _loadHistoryAndConnect() async {
    // Start loading
    setState(() => _isLoading = true);

    try {
      // Fetch history from the API
      final history = await apiService.getChatHistory(widget.roomId);
      setState(() {
        _messages.addAll(history);
      });
      _scrollToBottom(); // Scroll down after loading history
    } catch (e) {
      print("--- Error loading history: $e ---");
      // Optionally show a snackbar with the error
    } finally {
      // Stop loading and connect to WebSocket
      setState(() => _isLoading = false);
      _connectAndSubscribe();
    }
  }


  void _onConnectCallback(StompFrame connectFrame) {
    print("--- WebSocket Connected ---");
    stompClient!.subscribe(
      destination: '/topic/room/${widget.roomId}',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final result = json.decode(frame.body!);
            final newMessage = ChatMessage.fromJson(result);
            if (mounted) {
              setState(() {
                _messages.add(newMessage);
              });
              // Auto-scroll to the bottom when a new message arrives
              _scrollToBottom();
            }
          } catch (e) {
            print("--- Error parsing message body: ${e.toString()} ---");
          }
        }
      },
    );
    
    final joinMessage = ChatMessage(
      content: '${widget.currentUserId} has joined!',
      sender: widget.currentUserId,
      roomId: widget.roomId,
      type: 'JOIN',
    );
    stompClient!.send(
      destination: '/app/chat.addUser',
      body: json.encode(joinMessage.toJson()),
    );
  }

  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isNotEmpty && stompClient?.connected == true) {
      final chatMessage = ChatMessage(
        content: messageText,
        sender: widget.currentUserId,
        roomId: widget.roomId,
        type: 'CHAT',
      );

      stompClient!.send(
        destination: '/app/chat.send',
        body: json.encode(chatMessage.toJson()),
      );
      _messageController.clear();
      _scrollToBottom();
    } else {
      print("--- Cannot send message: Not connected or message is empty. ---");
    }
  }

  void _scrollToBottom() {
    // Add a small delay to allow the ListView to rebuild before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    print("--- Deactivating WebSocket client ---");
    stompClient?.deactivate();
    _messageController.dispose();
    _scrollController.dispose();
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
              // The child is now a conditional expression based on the _isLoading flag
              child: _isLoading
                  // If _isLoading is true, show a centered loading spinner
                  ? const Center(child: CircularProgressIndicator())
                  // If _isLoading is false, show your original ListView
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
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

class _MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInputField({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
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
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMyMessage;

  const _MessageBubble({required this.message, required this.isMyMessage});

  @override
  Widget build(BuildContext context) {
    // A simple check to see if the message is a system notification (like JOIN/LEAVE)
    if (message.type == 'JOIN' || message.type == 'LEAVE') {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              message.content,
              style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)
            ),
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
          style: TextStyle(color: isMyMessage ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}