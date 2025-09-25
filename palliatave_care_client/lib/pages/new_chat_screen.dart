// new_chat_screen.dart

import 'package:flutter/material.dart';
import '../models/user_account.dart'; // Make sure this model is correct
import '../services/api_service.dart';
import 'chat_detail_screen.dart';

class NewChatScreen extends StatefulWidget {
  final String currentUserId;

  const NewChatScreen({super.key, required this.currentUserId});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  late Future<List<UserAccount>> futureUsers;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    futureUsers = apiService.getAllUsers(); // You'll need to add this method to ApiService
  }

  void _startChatWithUser(UserAccount otherUser) {
    // This is the same logic from your old FloatingActionButton
    List<String> ids = [widget.currentUserId, otherUser.id];
    ids.sort();
    final roomId = ids.join('_');

    // Use Navigator.popAndPushNamed or similar for better navigation flow
    // For simplicity, we'll just push a replacement
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          roomId: roomId,
          otherParticipantName: otherUser.email, // Or user.fullName
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start a new chat'),
      ),
      body: FutureBuilder<List<UserAccount>>(
        future: futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No other users found.'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.email.substring(0, 1).toUpperCase()),
                ),
                title: Text(user.email), // Or user.fullName
                onTap: () => _startChatWithUser(user),
              );
            },
          );
        },
      ),
    );
  }
}