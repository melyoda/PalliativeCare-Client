import 'package:flutter/material.dart';
import 'package:palliatave_care_client/models/author.dart';

class Comment {
  final String id;
  final String userId; // The ID of the user who commented
  final String text;
  final DateTime timestamp;
  final DateTime? lastEdited;
  final Author author; // Nested AuthorDTO for the comment author

  Comment({
    required this.id,
    required this.userId,
    required this.text,
    required this.timestamp,
    this.lastEdited,
    required this.author,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['commentId'] as String? ?? UniqueKey().toString(),
      userId: json['author']['authorId'] as String? ?? 'unknown', // Assuming author.authorId is the userId
      text: json['text'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      lastEdited: DateTime.tryParse(json['lastEdited'] as String? ?? ''),
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
    );
  }
}