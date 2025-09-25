import 'package:flutter/material.dart';
import 'package:palliatave_care_client/l10n.dart';
import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/models/api_response.dart'; // Assuming you move ApiResponse there
import 'package:palliatave_care_client/widgets/info_dialog.dart';
import 'package:palliatave_care_client/util/http_status.dart'; // Import HttpStatus
import 'dart:io'; // For File
import 'package:image_picker/image_picker.dart'; // For ImagePicker, XFile, ImageSource

// AddTopicPage - For doctors to add new topics
class AddTopicPage extends StatefulWidget {
  const AddTopicPage({super.key});

  @override
  State<AddTopicPage> createState() => _AddTopicPageState();
}

class _AddTopicPageState extends State<AddTopicPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _pickedLogo;
  final List<File> _pickedResources = [];
  bool _isCreatingTopic = false;

  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedLogo = File(image.path);
      });
    }
  }

  Future<void> _addResource() async {
    final XFile? file = await _picker.pickMedia();
    if (file != null) {
      setState(() {
        _pickedResources.add(File(file.path));
      });
    }
  }

  Future<void> _createTopic() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCreatingTopic = true;
      });

      final ApiResponse<String> apiResponse = await _apiService.createTopic(
        title: _titleController.text,
        description: _descriptionController.text,
        logo: _pickedLogo,
        resources: _pickedResources,
      );

      setState(() {
        _isCreatingTopic = false;
      });

      if (apiResponse.status == HttpStatus.CREATED.name) {
        await _showInfoDialog(context, apiResponse.message, title: tr(context, 'topic_created_success')); // <-- Changed
        Navigator.pop(context);
      } else {
        await _showInfoDialog(context, apiResponse.message, title: tr(context, 'topic_creation_failed'), isError: true); // <-- Changed
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
        title: Text(tr(context, 'add_new_topic_title')), // <-- Changed
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
                  labelText: tr(context, 'topic_title_label'), // <-- Changed
                  hintText: tr(context, 'topic_title_hint'), // <-- Changed
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr(context, 'topic_title_validator'); // <-- Changed
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: tr(context, 'topic_description_label'), // <-- Changed
                  hintText: tr(context, 'topic_description_hint'), // <-- Changed
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr(context, 'topic_description_validator'); // <-- Changed
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                tr(context, 'topic_logo_label'), // <-- Changed
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              _pickedLogo != null
                  ? Image.file(_pickedLogo!, height: 100, width: 100, fit: BoxFit.cover)
                  : Container(
                      height: 100,
                      width: 100,
                      color: Colors.grey[200],
                      child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
                    ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickLogo,
                icon: const Icon(Icons.image),
                label: Text(tr(context, 'pick_logo_button')), // <-- Changed
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                tr(context, 'additional_resources_label'), // <-- Changed
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _pickedResources
                    .map((file) => Chip(
                          label: Text(file.path.split('/').last),
                          onDeleted: () {
                            setState(() {
                              _pickedResources.remove(file);
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _addResource,
                icon: const Icon(Icons.attach_file),
                label: Text(tr(context, 'add_resource_button')), // <-- Changed
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCreatingTopic ? null : _createTopic,
                  icon: _isCreatingTopic
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isCreatingTopic ? tr(context, 'creating_topic_button') : tr(context, 'create_topic_button')), // <-- Changed
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745), // Green for create
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