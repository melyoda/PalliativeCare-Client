// In lib/pages/send_notification_page.dart

import 'package:flutter/material.dart';
import 'package:palliatave_care_client/l10n.dart';
import 'package:palliatave_care_client/models/api_response.dart';
import 'package:palliatave_care_client/models/topic.dart';
import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/util/http_status.dart';
import 'package:palliatave_care_client/widgets/info_dialog.dart';

enum NotificationTarget { allUsers, topicSubscribers }

class SendNotificationPage extends StatefulWidget {
  const SendNotificationPage({super.key});

  @override
  State<SendNotificationPage> createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _apiService = ApiService();

  NotificationTarget _selectedTarget = NotificationTarget.allUsers;
  List<Topic> _allTopics = [];
  String? _selectedTopicId;
  bool _isLoadingTopics = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    final response = await _apiService.getAllTopics();
    if (mounted && response.status == 'OK' && response.data != null) {
      setState(() {
        _allTopics = response.data!;
        _isLoadingTopics = false;
      });
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTarget == NotificationTarget.topicSubscribers && _selectedTopicId == null) {
      _showInfoDialog(context, tr(context, 'please_select_topic'), title: tr(context, 'error_title'), isError: true);
      return;
    }

    setState(() => _isSending = true);

    ApiResponse<String> response;
    final title = _titleController.text;
    final message = _messageController.text;

    if (_selectedTarget == NotificationTarget.allUsers) {
      response = await _apiService.sendBroadcastNotification(title: title, message: message);
    } else {
      response = await _apiService.sendTopicNotification(topicId: _selectedTopicId!, title: title, message: message);
    }

    setState(() => _isSending = false);

    if (!mounted) return;

    if (response.status == 'OK') {
      await _showInfoDialog(context, response.message, title: tr(context, 'notification_sent_successfully'));
      Navigator.pop(context);
    } else {
      await _showInfoDialog(context, response.message, title: tr(context, 'notification_failed'), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'send_notification')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: tr(context, 'notification_title')),
                validator: (v) => v == null || v.isEmpty ? tr(context, 'enter_title_validator') : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(labelText: tr(context, 'notification_message')),
                maxLines: 5,
                validator: (v) => v == null || v.isEmpty ? tr(context, 'enter_message_validator') : null,
              ),
              const SizedBox(height: 30),
              Text(tr(context, 'send_to'), style: Theme.of(context).textTheme.titleMedium),
              RadioListTile<NotificationTarget>(
                title: Text(tr(context, 'all_users')),
                value: NotificationTarget.allUsers,
                groupValue: _selectedTarget,
                onChanged: (value) => setState(() => _selectedTarget = value!),
              ),
              RadioListTile<NotificationTarget>(
                title: Text(tr(context, 'topic_subscribers')),
                value: NotificationTarget.topicSubscribers,
                groupValue: _selectedTarget,
                onChanged: (value) => setState(() => _selectedTarget = value!),
              ),
              if (_selectedTarget == NotificationTarget.topicSubscribers) ...[
                const SizedBox(height: 10),
                _isLoadingTopics
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedTopicId,
                        hint: Text(tr(context, 'select_topic')),
                        items: _allTopics.map((topic) {
                          return DropdownMenuItem(value: topic.id, child: Text(topic.title));
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedTopicId = value),
                        validator: (v) => v == null ? tr(context, 'please_select_topic') : null,
                      ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendNotification,
                  icon: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                  label: Text(_isSending ? tr(context, 'sending_notification') : tr(context, 'send_button')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _showInfoDialog(BuildContext context, String message, {String title = 'Information', bool isError = false}) async {
    final dialogTitle = title == 'Information' ? tr(context, 'dialog_info_title') : title;
    return await showDialog(
      context: context,
      builder: (ctx) => InfoDialog(title: dialogTitle, message: message, isError: isError),
    );
  }
}