import 'package:flutter/material.dart';

import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/models/api_response.dart'; // Assuming you move ApiResponse there
import 'package:palliatave_care_client/widgets/info_dialog.dart';
import 'package:palliatave_care_client/util/http_status.dart'; // Import HttpStatus
import '../models/topic.dart';
import '../pages/add_topics_page.dart';
import '../pages/topic_detail_page.dart';
import '../widgets/topic_card.dart';

// AllTopicsPage - Displays all available topics
class AllTopicsPage extends StatefulWidget {
  final String userRole; // Pass the user's role to conditionally show the "Add Topic" button

  const AllTopicsPage({super.key, required this.userRole});

  @override
  State<AllTopicsPage> createState() => _AllTopicsPageState();
}

class _AllTopicsPageState extends State<AllTopicsPage> {
  final ApiService _apiService = ApiService();
  List<Topic> _allTopics = [];
  List<String> _userSubscribedTopicIds = []; // New list to hold subscribed topic IDs
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTopicsAndSubscriptions(); // Load both topics and user's subscriptions
  }

  Future<void> _loadTopicsAndSubscriptions() async {
    setState(() {
      _isLoading = true;
    });

    final topicsResponse = await _apiService.getAllTopics();
    final subscribedTopicsResponse = await _apiService.getSubscribedTopicIds();

    if (topicsResponse.status == HttpStatus.OK.name && topicsResponse.data != null) {
      _allTopics = topicsResponse.data!;
    } else {
      await _showInfoDialog(context, topicsResponse.message, title: "Error Fetching Topics", isError: true);
    }

    if (subscribedTopicsResponse.status == HttpStatus.OK.name && subscribedTopicsResponse.data != null) {
      _userSubscribedTopicIds = subscribedTopicsResponse.data!;
      print('AllTopicsPage: Subscribed Topic IDs loaded: $_userSubscribedTopicIds'); // DIAGNOSTIC PRINT
    } else {
      // This is the specific place the FormatException likely occurs.
      // The error dialog is shown, but the data remains empty, leading to "No topics available yet."
      await _showInfoDialog(context, subscribedTopicsResponse.message, title: "Error Fetching Subscriptions", isError: true);
      _userSubscribedTopicIds = []; // Ensure it's an empty list to prevent further errors
    }
    print('AllTopicsPage: User Role received: ${widget.userRole}'); // DIAGNOSTIC PRINT

    setState(() {
      _isLoading = false;
    });
  }


  Future<void> _handleSubscribe(String topicId) async {
    final ApiResponse<String> apiResponse = await _apiService.registerToTopic(topicId);
    if (apiResponse.status == HttpStatus.OK.name) {
      await _showInfoDialog(context, apiResponse.message, title: "Subscribed Successfully!");
      _loadTopicsAndSubscriptions(); // Refresh data
    } else {
      await _showInfoDialog(context, apiResponse.message, title: "Subscription Failed", isError: true);
    }
  }

  Future<void> _handleUnsubscribe(String topicId) async {
    final ApiResponse<String> apiResponse = await _apiService.unregisterFromTopic(topicId);
    if (apiResponse.status == HttpStatus.OK.name) {
      await _showInfoDialog(context, apiResponse.message, title: "Unsubscribed Successfully!");
      _loadTopicsAndSubscriptions(); // Refresh data
    } else {
      await _showInfoDialog(context, apiResponse.message, title: "Unsubscription Failed", isError: true);
    }
  }

  Future<void> _showInfoDialog(BuildContext context, String message, {String title = 'Information', bool isError = false}) async {
    return await showDialog(
      context: context,
      builder: (ctx) => InfoDialog(title: title, message: message, isError: isError),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Topics'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _allTopics.isEmpty
                      ? Center(
                          child: Text(
                            'No topics available yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        )
                      : GridView.builder( // Using GridView for a nicer layout
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // 2 cards per row
                            childAspectRatio: 3 / 2, // Adjust card aspect ratio
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                          ),
                          itemCount: _allTopics.length,
                          itemBuilder: (context, index) {
                            final topic = _allTopics[index];
                            final isSubscribed = _userSubscribedTopicIds.contains(topic.id);
                            return TopicCard(
                              topic: topic,
                              isSubscribed: isSubscribed,
                              onSubscribe: () => _handleSubscribe(topic.id),
                              onUnsubscribe: () => _handleUnsubscribe(topic.id),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TopicDetailPage(topic: topic, userRole: widget.userRole),
                                  ),
                                ).then((_) => _loadTopicsAndSubscriptions()); // Refresh on return
                              },
                            );
                          },
                        ),
                ),
                if (widget.userRole == 'DOCTOR') // Only show "Add Topic" button for doctors
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTopicPage()));
                          _loadTopicsAndSubscriptions(); // Refresh topics after returning from AddTopicPage
                        },
                        icon: const Icon(Icons.add, size: 24),
                        label: const Text('Add New Topic'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary, // Use accent color
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}