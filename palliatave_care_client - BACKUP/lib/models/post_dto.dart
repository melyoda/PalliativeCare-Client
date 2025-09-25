// lib/models/post_dto.dart
import 'dart:io';

class PostDTO {
  final String title;
  final String content;
  final List<File> resources;

  PostDTO({
    required this.title,
    required this.content,
    this.resources = const [], // Default to an empty list
  });
}