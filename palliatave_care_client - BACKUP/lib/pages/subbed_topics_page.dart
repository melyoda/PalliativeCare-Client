import 'package:flutter/material.dart';

import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/models/api_response.dart'; // Assuming you move ApiResponse there
import 'package:palliatave_care_client/widgets/info_dialog.dart';
import 'package:palliatave_care_client/util/http_status.dart'; // Import HttpStatus
import 'package:palliatave_care_client/models/topic.dart';
import '../widgets/topic_card.dart';
import '../pages/topic_detail_page.dart';

// SubscribedTopicsPage - Displays topics the current user is subscribed to
class SubscribedTopicsPage extends StatefulWidget {

  final String userRole;

  const SubscribedTopicsPage({super.key, required this.userRole});

  @override
  State<SubscribedTopicsPage> createState() => _SubscribedTopicsPageState();
}

class _SubscribedTopicsPageState extends State<SubscribedTopicsPage> {
  final ApiService _apiService = ApiService();
  List<Topic> _subscribedTopics = [];
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _fetchSubscribedTopics();
  }

  Future<void> _fetchSubscribedTopics() async {
    setState(() {
      _isLoading = true;
    });

    // Call the API service to get subscribed topics
    final ApiResponse<List<Topic>> apiResponse = await _apiService.getSubscribedTopics();

    if (apiResponse.status == HttpStatus.OK.name && apiResponse.data != null) {
      setState(() {
        _subscribedTopics = apiResponse.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      await _showInfoDialog(context, apiResponse.message, title: "Error Fetching Subscribed Topics", isError: true);
      _subscribedTopics = []; // Ensure it's an empty list to prevent further errors
    }
  }

  Future<void> _handleUnsubscribe(String topicId) async {
    final ApiResponse<String> apiResponse = await _apiService.unregisterFromTopic(topicId);
    if (apiResponse.status == HttpStatus.OK.name) {
      await _showInfoDialog(context, apiResponse.message, title: "Unsubscribed Successfully!");
      _fetchSubscribedTopics(); // Refresh data
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
        title: const Text('My Subscribed Topics'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subscribedTopics.isEmpty
              ? Center(
                  child: Text(
                    'You are not subscribed to any topics yet.\nExplore "All Topics" to find some!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _subscribedTopics.length,
                  itemBuilder: (context, index) {
                    final topic = _subscribedTopics[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TopicCard(
                        topic: topic,
                        isSubscribed: true, // Always true on this page
                        onSubscribe: () {}, // No subscribe action on this page
                        onUnsubscribe: () => _handleUnsubscribe(topic.id),
                        onTap: () {Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TopicDetailPage(topic: topic, userRole: widget.userRole),
                                  ),
                                ).then((_) => _fetchSubscribedTopics()); // Refresh on return
                              },
                      ),
                    );
                  },
                ),
    );
  }
}