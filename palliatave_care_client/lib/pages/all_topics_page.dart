import 'package:flutter/material.dart';
import 'package:palliatave_care_client/l10n.dart'; 
import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/models/api_response.dart'; // Assuming you move ApiResponse there
import 'package:palliatave_care_client/widgets/info_dialog.dart';
import 'package:palliatave_care_client/util/http_status.dart'; // Import HttpStatus
import '../models/topic.dart';
import '../pages/add_topics_page.dart';
import '../pages/topic_detail_page.dart';
import '../widgets/topic_card.dart';

class AllTopicsPage extends StatefulWidget {
  final String userRole;

  const AllTopicsPage({super.key, required this.userRole});

  @override
  State<AllTopicsPage> createState() => _AllTopicsPageState();
}

class _AllTopicsPageState extends State<AllTopicsPage> {
  final ApiService _apiService = ApiService();
  List<Topic> _allTopics = [];
  List<String> _userSubscribedTopicIds = [];
  bool _isLoading = false;
  static const String qaTopicId = '68d4f9689432a68dd3b44d95'; // The fixed ID for the Q&A topic

  @override
  void initState() {
    super.initState();
    _loadTopicsAndSubscriptions();
  }

  Future<void> _loadTopicsAndSubscriptions() async {
    setState(() {
      _isLoading = true;
    });

    final topicsResponse = await _apiService.getAllTopics();
    final subscribedTopicsResponse = await _apiService.getSubscribedTopicIds();

    if (!mounted) return;

    if (topicsResponse.status == HttpStatus.OK.name && topicsResponse.data != null) {
      _allTopics = topicsResponse.data!;
    } else {
      await _showInfoDialog(context, topicsResponse.message, title: tr(context, 'error_fetching_topics'), isError: true); // <-- Changed
    }

    if (subscribedTopicsResponse.status == HttpStatus.OK.name && subscribedTopicsResponse.data != null) {
      _userSubscribedTopicIds = subscribedTopicsResponse.data!;
    } else {
      await _showInfoDialog(context, subscribedTopicsResponse.message, title: tr(context, 'error_fetching_subscriptions'), isError: true); // <-- Changed
      _userSubscribedTopicIds = [];
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleSubscribe(String topicId) async {
    final ApiResponse<String> apiResponse = await _apiService.registerToTopic(topicId);
    if (!mounted) return;
    if (apiResponse.status == HttpStatus.OK.name) {
      await _showInfoDialog(context, apiResponse.message, title: tr(context, 'subscribed_successfully')); // <-- Changed
      _loadTopicsAndSubscriptions();
    } else {
      await _showInfoDialog(context, apiResponse.message, title: tr(context, 'subscription_failed'), isError: true); // <-- Changed
    }
  }

  Future<void> _handleUnsubscribe(String topicId) async {
    final ApiResponse<String> apiResponse = await _apiService.unregisterFromTopic(topicId);
    if (!mounted) return;
    if (apiResponse.status == HttpStatus.OK.name) {
      await _showInfoDialog(context, apiResponse.message, title: tr(context, 'unsubscribed_successfully')); // <-- Changed
      _loadTopicsAndSubscriptions();
    } else {
      await _showInfoDialog(context, apiResponse.message, title: tr(context, 'unsubscription_failed'), isError: true); // <-- Changed
    }
  }

  Future<void> _showInfoDialog(BuildContext context, String message, {String title = 'Information', bool isError = false}) async {
    final dialogTitle = title == 'Information' ? tr(context, 'dialog_info_title') : title;
    return await showDialog(
      context: context,
      builder: (ctx) => InfoDialog(title: dialogTitle, message: message, isError: isError),
    );
  }

  @override
  Widget build(BuildContext context) {
  List<Topic> displayedTopics = _allTopics;

  // If the user is a patient, filter out the QA topic.
  if (widget.userRole == 'PATIENT') {
    displayedTopics = _allTopics.where((topic) => topic.id != qaTopicId).toList();
  }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'all_topics_title')), // <-- Changed
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
                            tr(context, 'no_topics_available'), // <-- Changed
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3 / 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                          ),
                          itemCount: displayedTopics.length,
                          itemBuilder: (context, index) {
                            final topic = displayedTopics[index];
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
                                ).then((_) => _loadTopicsAndSubscriptions());
                              },
                            );
                          },
                        ),
                ),
                if (widget.userRole == 'DOCTOR')
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTopicPage()));
                          _loadTopicsAndSubscriptions();
                        },
                        icon: const Icon(Icons.add, size: 24),
                        label: Text(tr(context, 'add_new_topic_title')), // <-- Changed (reusing key)
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
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