// In lib/pages/edit_topic_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palliatave_care_client/l10n.dart';
import 'package:palliatave_care_client/models/api_response.dart';
import 'package:palliatave_care_client/models/topic.dart';
import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/util/http_status.dart';
import 'package:palliatave_care_client/widgets/info_dialog.dart';

class EditTopicPage extends StatefulWidget {
  final Topic topic; // Takes a Topic object to edit

  const EditTopicPage({super.key, required this.topic});

  @override
  State<EditTopicPage> createState() => _EditTopicPageState();
}

class _EditTopicPageState extends State<EditTopicPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _pickedLogo;
  bool _isUpdatingTopic = false;

  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Pre-fill the form fields with the existing topic data
    _titleController.text = widget.topic.title;
    _descriptionController.text = widget.topic.description;
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedLogo = File(image.path);
      });
    }
  }

  Future<void> _updateTopic() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUpdatingTopic = true);

      final ApiResponse<String> apiResponse = await _apiService.updateTopic(
        topicId: widget.topic.id, // Use the existing topic's ID
        title: _titleController.text,
        description: _descriptionController.text,
        logo: _pickedLogo,
      );

      setState(() => _isUpdatingTopic = false);

      if (!mounted) return;

      if (apiResponse.status == HttpStatus.OK.name) {
        // Pop with `true` to signal that the previous page should refresh
        Navigator.pop(context, true);
      } else {
        _showInfoDialog(context, apiResponse.message, title: tr(context, 'update_failed_title'), isError: true);
      }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'edit_topic_title')),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
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
                decoration: InputDecoration(
                  labelText: tr(context, 'topic_title_label'),
                  hintText: tr(context, 'topic_title_hint'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr(context, 'topic_title_validator');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: tr(context, 'topic_description_label'),
                  hintText: tr(context, 'topic_description_hint'),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr(context, 'topic_description_validator');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(tr(context, 'update_logo_optional'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              // Display the newly picked logo, or the existing network logo as a fallback
              SizedBox(
                height: 100,
                width: 100,
                child: _pickedLogo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_pickedLogo!, fit: BoxFit.cover),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.topic.logoUrl ?? 'https://via.placeholder.com/150', // A placeholder
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.broken_image, color: Colors.grey[400]),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickLogo,
                icon: const Icon(Icons.image),
                label: Text(tr(context, 'pick_logo_button')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUpdatingTopic ? null : _updateTopic,
                  icon: _isUpdatingTopic 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Icon(Icons.save),
                  label: Text(_isUpdatingTopic ? tr(context, 'updating_topic_button') : tr(context, 'update_topic_button')),
                   style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}