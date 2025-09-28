import 'package:flutter/material.dart';
import 'package:palliatave_care_client/l10n.dart';
import 'package:palliatave_care_client/models/api_response.dart';
import 'package:palliatave_care_client/pages/topic_detail_page.dart';
import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/util/http_status.dart';
import 'package:palliatave_care_client/widgets/info_dialog.dart';

// A central place for handling complex navigation tasks.
class AppNavigator {
  static const String _qaTopicId = '68d4f9689432a68dd3b44d95';

  // We make the method 'static' so you can call it directly like AppNavigator.navigateToQATopic()
  // without needing to create an instance of the class.
  static Future<void> navigateToQATopic(BuildContext context, String userRole) async {
    final apiService = ApiService(); // Create an instance to use

    // Show a temporary "loading" message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'finding_qa_topic'))));

    final ApiResponse response = await apiService.getAllTopics();
    
    // Check if the widget is still mounted before proceeding
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (response.status == HttpStatus.OK.name && response.data != null) {
      try {
        // Find the topic that has the matching ID
        final qaTopic = response.data!.firstWhere((topic) => topic.id == _qaTopicId);
        
        // Navigate to the standard TopicDetailPage with the found topic
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopicDetailPage(
              topic: qaTopic,
              userRole: userRole,
            ),
          ),
        );
      } catch (e) {
        // This error happens if no topic with that ID was found in the list
        _showInfoDialog(context, tr(context, 'qa_topic_not_found_error'), title: tr(context, 'error_title'), isError: true);
      }
    } else {
      // Handle the case where the API call to get topics failed
      _showInfoDialog(context, response.message, title: tr(context, 'error_fetching_topics'), isError: true);
    }
  }

  // This is a helper method used by the function above
  static Future<void> _showInfoDialog(BuildContext context, String message, {String title = 'Information', bool isError = false}) async {
    final dialogTitle = title == 'Information' ? tr(context, 'dialog_info_title') : title;
    return await showDialog(
      context: context,
      builder: (ctx) => InfoDialog(title: dialogTitle, message: message, isError: isError),
    );
  }
}