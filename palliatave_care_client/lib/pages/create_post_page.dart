import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palliatave_care_client/l10n.dart';

import 'package:palliatave_care_client/models/api_response.dart';
import 'package:palliatave_care_client/models/post.dart';            // The Post model your API returns
import 'package:palliatave_care_client/models/post_dto.dart';       // The DTO you showed
import 'package:palliatave_care_client/services/api_service.dart';
import 'package:palliatave_care_client/util/http_status.dart';
import 'package:palliatave_care_client/widgets/info_dialog.dart';

class CreatePostPage extends StatefulWidget {
  final String topicId;   // which topic are we posting into?
  final String topicName; // optional: just for the header
  final bool isQA;

  const CreatePostPage({
    super.key,
    required this.topicId,
    required this.topicName,
    this.isQA = false, 
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  final _picker = ImagePicker();
  final _api = ApiService();

  final List<File> _pickedResources = [];
  bool _submitting = false;

  Future<void> _pickResource() async {
    // Allows user to pick either image or video (single pick each time)
    final XFile? file = await _picker.pickMedia();
    if (file != null) {
      setState(() {
        _pickedResources.add(File(file.path));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final dto = PostDTO(
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      resources: _pickedResources,
    );

      ApiResponse<Post> resp;

      if (widget.isQA) {
        // If it's a Q&A post, call the patient-specific function
        resp = await _api.createPatientQuestion(dto);
      } else {
        // Otherwise, call the original doctor-specific function
        resp = await _api.createDoctorPost(widget.topicId, dto);
      }
    // final ApiResponse<Post> resp =
    //     await _api.createDoctorPost(widget.topicId, dto);

    setState(() => _submitting = false);

    if (!mounted) return;

    if (resp.status == HttpStatus.OK.name || resp.status == HttpStatus.CREATED.name) {
      await _showInfoDialog(context, resp.message.isNotEmpty ? resp.message : tr(context, 'post_created_successfully'));
      // Pop with `true` so TopicDetailPage knows to refresh
      Navigator.of(context).pop(true);
    } else if (resp.status == HttpStatus.UNAUTHORIZED.name) {
      await _showInfoDialog(context, 'Please log in to create a post.', title: tr(context, 'unauthorized_title'), isError: true);
    } else {
      await _showInfoDialog(context, resp.message, title: tr(context, 'create_post_failed_title'), isError: true);
    }
  }

  Future<void> _showInfoDialog(BuildContext context, String message,
      {String title = 'Information', bool isError = false}) async {
         final dialogTitle = title == 'Information' ? tr(context, 'dialog_info_title') : title;
    return await showDialog(
      context: context,
      builder: (ctx) => InfoDialog(title: dialogTitle, message: message, isError: isError),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title:  Text('${tr(context, 'create_post_in_topic_title')}${widget.topicName}'),
        backgroundColor: primary,
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
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: tr(context, 'post_title_label'),
                  hintText: tr(context, 'post_title_hint'),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return tr(context, 'post_title_validator');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _contentCtrl,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: tr(context, 'post_content_label'),
                  hintText:  tr(context, 'post_content_hint'),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return tr(context, 'post_content_validator');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

               Text(
                tr(context, 'attachments_label'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              // Chips list for picked files
              if (_pickedResources.isEmpty)
                Text(tr(context, 'no_files_selected'), style: TextStyle(color: Colors.grey[600]))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _pickedResources.map((f) {
                    final name = f.path.split('/').last;
                    return Chip(
                      label: Text(name, overflow: TextOverflow.ellipsis),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () {
                        setState(() => _pickedResources.remove(f));
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 10),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickResource,
                    icon: const Icon(Icons.attach_file),
                    label: Text(tr(context, 'add_attachment_button')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_submitting ? tr(context, 'creating_post_button') :  tr(context, 'create_post_button')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
