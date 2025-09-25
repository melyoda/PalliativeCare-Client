import 'package:flutter/material.dart';
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
    final XFile? file = await _picker.pickMedia(); // Allows picking image/video
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
        await _showInfoDialog(context, apiResponse.message, title: "Topic Created Successfully!");
        Navigator.pop(context); // Go back to All Topics page
      } else {
        await _showInfoDialog(context, apiResponse.message, title: "Topic Creation Failed", isError: true);
      }
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
        title: const Text('Add New Topic'),
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
                decoration: const InputDecoration(labelText: 'Topic Title *', hintText: 'e.g., Pain Management Techniques'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a topic title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Topic Description *', hintText: 'Provide a brief description of the topic'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a topic description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Topic Logo (Optional):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
                label: const Text('Pick Logo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              const Text('Additional Resources (Optional - Images/Videos):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _pickedResources.map((file) => Chip(
                  label: Text(file.path.split('/').last),
                  onDeleted: () {
                    setState(() {
                      _pickedResources.remove(file);
                    });
                  },
                )).toList(),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _addResource,
                icon: const Icon(Icons.attach_file),
                label: const Text('Add Resource'),
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
                  icon: _isCreatingTopic ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                  label: Text(_isCreatingTopic ? 'Creating Topic...' : 'Create Topic'),
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
