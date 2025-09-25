import 'package:flutter/material.dart';
import 'package:palliatave_care_client/models/author.dart';
import 'package:palliatave_care_client/models/resource.dart';
import 'package:palliatave_care_client/models/topic_info.dart';
import 'package:palliatave_care_client/models/comment.dart';
import 'package:intl/intl.dart';

// Main Post Model (representing EnrichedPostDTO)
class EnrichedPost {
  final String id;
  final String title;
  final String content;
  final DateTime creationDate;
  final DateTime? modificationDate;
  
  final Author author; // Directly use Author model
  final TopicInfo topicInfo; // Directly use TopicInfo model
  final List<Resource> resources;
  final List<Comment> comments;

  final int commentsCount;
  final bool isLiked; // Assuming the backend might add this later
  final int likeCount; // Assuming the backend might add this later

  // Display fields derived for convenience
  final String timeAgo;
  final String? imageUrl;
  final int readTimeMinutes;


  EnrichedPost({
    required this.id,
    required this.title,
    required this.content,
    required this.creationDate,
    this.modificationDate,
    required this.author,
    required this.topicInfo,
    required this.resources,
    required this.comments,
    required this.commentsCount,
    this.isLiked = false, // Default if not provided
    this.likeCount = 0,   // Default if not provided
  })  : timeAgo = _formatTimeAgo(creationDate),
        imageUrl = _extractImageUrl(resources),
        readTimeMinutes = (content.split(' ').length / 150).ceil(); // Estimate read time

  factory EnrichedPost.fromJson(Map<String, dynamic> json) {
    // Parse nested AuthorDTO
    final Author author = Author.fromJson(json['author'] as Map<String, dynamic>);

    // Parse nested TopicInfoDTO
    final TopicInfo topicInfo = TopicInfo.fromJson(json['topic'] as Map<String, dynamic>); // Mapped from 'topic'

    // Parse comments list
    final List<dynamic> commentsJsonList = json['comments'] ?? [];
    final List<Comment> comments = commentsJsonList.map((json) => Comment.fromJson(json)).toList();

    // Parse resources list
    final List<dynamic> resourcesJsonList = json['resources'] ?? [];
    final List<Resource> resources = resourcesJsonList.map((json) => Resource.fromJson(json)).toList();

    return EnrichedPost(
      id: json['postId'] as String? ?? UniqueKey().toString(), // Mapped from postId
      title: json['title'] as String? ?? 'No Title',
      content: json['content'] as String? ?? 'No content available.',
      creationDate: DateTime.tryParse(json['creationDate'] as String? ?? '') ?? DateTime.now(),
      modificationDate: DateTime.tryParse(json['modificationDate'] as String? ?? ''),
      author: author,
      topicInfo: topicInfo,
      resources: resources,
      comments: comments,
      commentsCount: json['commentCount'] as int? ?? 0, // Mapped from commentCount
      isLiked: json['isLiked'] as bool? ?? false,
      likeCount: json['likeCount'] as int? ?? 0,
    );
  }

  static String _formatTimeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 30) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'just now';
    }
  }

  static String? _extractImageUrl(List<Resource> resources) {
    try {
      return resources.firstWhere((res) => res.type.toUpperCase() == 'IMAGE' && res.contentUrl.isNotEmpty).contentUrl;
    } catch (e) {
      return null;
    }
  }
}