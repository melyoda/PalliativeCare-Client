import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart'; 
import '../models/chat_models.dart';  
import '../pages/chat_detail_screen.dart';
import '../models/user_account.dart';
import '../pages/new_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<ChatConversation>> futureConversations;
  final ApiService apiService = ApiService();

   String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData(); 
    futureConversations = apiService.getConversations();
  }

  Future<void> _loadCurrentUserData() async {
    UserAccount? userAccount = await apiService.loadUserProfile();
    if (mounted && userAccount != null) {
      setState(() {
        _currentUserId = userAccount.id;
        print('ChatListScreen: User ID Loaded: $_currentUserId');
      });
    } else {
      // Handle user not found, maybe pop back to login
      print('ChatListScreen: User profile not found.');
    }
  }

    void _refreshConversations() {
    setState(() {
      futureConversations = apiService.getConversations();
    });
  }
   void _navigateToNewChat() async {
    // Navigate to the new screen and wait for it to be closed
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewChatScreen(currentUserId: _currentUserId),
      ),
    );

    // When we come back from the NewChatScreen, refresh the list
    _refreshConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
      ),
      body: FutureBuilder<List<ChatConversation>>(
        future: futureConversations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No conversations found.'));
          }

          // If we have data, show it in a ListView
          final conversations = snapshot.data!;
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final convo = conversations[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(convo.otherParticipantName.substring(0, 1)),
                ),
                title: Text(convo.otherParticipantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(convo.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis,),
                trailing: convo.timestamp != null
                    ? Text(DateFormat('h:mm a').format(convo.timestamp!))
                    : const Text(''),
                onTap: () {
                  // ✅ 4. Use the state variable for navigation
                  if (_currentUserId.isEmpty) {
                    // Optional: Show a snackbar or prevent navigation if ID hasn't loaded yet
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User data is still loading...'))
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        roomId: convo.roomId,
                        otherParticipantName: convo.otherParticipantName,
                        currentUserId: _currentUserId, // Pass the loaded ID
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      // 👇👇👇 ADD THE BUTTON CODE RIGHT HERE 👇👇👇
      floatingActionButton: FloatingActionButton(
        onPressed: () { // 🚀 MODIFIED
          if (_currentUserId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot start chat: User ID not loaded.'))
            );
            return;
          }
          // Navigate to the user selection screen
          _navigateToNewChat();
        },
        tooltip: 'Start New Chat',
        child: const Icon(Icons.add),
    ),
    );
  }
}