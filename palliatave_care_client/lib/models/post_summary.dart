import 'package:flutter/material.dart';
import 'package:palliatave_care_client/models/author.dart';
import 'package:palliatave_care_client/models/resource.dart';
import 'package:palliatave_care_client/models/topic_info.dart';

/// A "lightweight" version of a Post, used for displaying in lists.
/// Its fromJson factory is more defensive to prevent crashes when parsing
/// summary-level data from the API.
class PostSummary {
  final String id;
  final String title;
  final DateTime creationDate;
  final Author author;
  final TopicInfo topicInfo;
  final int commentsCount;
  final String? imageUrl; // The first image found in the resources

  PostSummary({
    required this.id,
    required this.title,
    required this.creationDate,
    required this.author,
    required this.topicInfo,
    required this.commentsCount,
    this.imageUrl,
  });

  /// A safe factory for parsing list items from the API.
  /// It checks for null nested objects and provides default placeholders to avoid crashes.
  factory PostSummary.fromJson(Map<String, dynamic> json) {
    // Safely parse nested Author, providing a default if it's null
    final Author author = json['author'] != null
        ? Author.fromJson(json['author'])
        : Author(id: '?', firstName: 'Unknown', lastName: 'Author', role: 'N/A');

    // Safely parse nested TopicInfo, providing a default if it's null
    final TopicInfo topicInfo = json['topic'] != null
        ? TopicInfo.fromJson(json['topic'])
        : TopicInfo(id: '?', title: 'Uncategorized');

    // Safely parse resources to find an image URL
    final List<dynamic> resourcesJsonList = json['resources'] ?? [];
    final List<Resource> resources = resourcesJsonList.map((j) => Resource.fromJson(j)).toList();

    return PostSummary(
      id: json['postId'] as String? ?? UniqueKey().toString(),
      title: json['title'] as String? ?? 'No Title',
      creationDate: DateTime.tryParse(json['creationDate'] as String? ?? '') ?? DateTime.now(),
      author: author,
      topicInfo: topicInfo,
      commentsCount: json['commentCount'] as int? ?? 0,
      imageUrl: _extractFirstImageUrl(resources),
    );
  }

  /// Helper function to find the first image URL from a list of resources.
  static String? _extractFirstImageUrl(List<Resource> resources) {
    try {
      // Find the first resource where the type is 'IMAGE' (case-insensitive)
      return resources.firstWhere((res) => res.type.toUpperCase() == 'IMAGE').contentUrl;
    } catch (e) {
      // Return null if no image is found
      return null;
    }
  }
}
