// lib/models/post.dart
import 'package:flutter/material.dart';
import 'package:palliatave_care_client/models/resource.dart';

// This is the frontend model for the backend's `Posts` entity.
// Use this for lists!
class Post {
  final String id;
  final String title;
  final String content;
  final String topicId;       // This is just an ID
  final String createdBy;     // This is just an ID
  final DateTime creationDate;
  final List<Resource> resources;
  final List<Comment> comments; // The nested comments

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.topicId,
    required this.createdBy,
    required this.creationDate,
    required this.resources,
    required this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final List<dynamic> resourcesJsonList = json['resources'] ?? [];
    final List<Resource> resources = resourcesJsonList.map((j) => Resource.fromJson(j)).toList();

    final List<dynamic> commentsJsonList = json['comments'] ?? [];
    final List<Comment> comments = commentsJsonList.map((j) => Comment.fromJson(j)).toList();

    return Post(
      id: json['id'] as String? ?? UniqueKey().toString(),
      title: json['title'] as String? ?? 'No Title',
      content: json['content'] as String? ?? '',
      topicId: json['topicId'] as String? ?? 'unknown_topic',
      createdBy: json['createdBy'] as String? ?? 'unknown_user',
      creationDate: DateTime.tryParse(json['creationDate'] as String? ?? '') ?? DateTime.now(),
      resources: resources,
      comments: comments,
    );
  }
}

// This is the frontend model for the nested `Comment` class in the `Posts` entity.
class Comment {
  final String commentId;
  final String userId;
  final String userDisplayName;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.commentId,
    required this.userId,
    required this.userDisplayName,
    required this.text,
    required this.timestamp,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['commentId'] as String? ?? UniqueKey().toString(),
      userId: json['userId'] as String? ?? 'unknown_user',
      userDisplayName: json['userDisplayName'] as String? ?? 'Anonymous',
      text: json['text'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}