import 'package:flutter/material.dart';

import '../models/resource.dart';

// Topic Model - Represents the Topic entity from your backend
// lib/models/topic.dart
class Topic {
  final String id;
  final String title;
  final String description;
  final String? logoUrl; // Nullable
  final List<Resource> resources; // Added resources list
  final String createdBy; // ID of the user who created it
  final DateTime creationDate;
  final DateTime? modifiedDate; // Nullable

  Topic({
    required this.id,
    required this.title,
    required this.description,
    this.logoUrl,
    required this.resources, // Added to constructor
    required this.createdBy,
    required this.creationDate,
    this.modifiedDate,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    final List<dynamic> resourcesJsonList = json['resources'] ?? [];
    final List<Resource> resources = resourcesJsonList.map((json) => Resource.fromJson(json)).toList();

    return Topic(
      id: json['id'] as String? ?? UniqueKey().toString(),
      title: json['title'] as String? ?? 'Untitled Topic',
      description: json['description'] as String? ?? 'No description available.',
      logoUrl: json['logoUrl'] as String?,
      resources: resources, // Parse resources
      createdBy: json['createdBy'] as String? ?? 'unknown',
      creationDate: DateTime.tryParse(json['creationDate'] as String? ?? '') ?? DateTime.now(),
      modifiedDate: DateTime.tryParse(json['modifiedDate'] as String? ?? ''),
    );
  }
}