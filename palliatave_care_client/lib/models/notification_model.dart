// In lib/models/notification_model.dart

// This enum must match the NotificationType enum in your backend
enum NotificationType {
  TOPIC_REGISTRATION,
  TOPIC_UNREGISTRATION,
  TOPIC_UPDATE,
  NEW_POST,
  NEW_COMMENT,
  HELP_RESPONSE,
  SYSTEM_ALERT,
  DOCTOR_MESSAGE,
  UNKNOWN, // A fallback for safety
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? relatedTopicId;
  final String? relatedPostId;
  bool read; // This needs to be changeable, so it's not final
  final DateTime createdAt;
  final DateTime? expiresAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedTopicId,
    this.relatedPostId,
    required this.read,
    required this.createdAt,
    this.expiresAt,
  });

  // Factory constructor to create a NotificationModel from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      message: json['message'],
      type: _notificationTypeFromString(json['type']),
      relatedTopicId: json['relatedTopicId'],
      relatedPostId: json['relatedPostId'],
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }
}

// Helper function to safely convert a string from the API to our enum
NotificationType _notificationTypeFromString(String? typeString) {
  if (typeString == null) {
    return NotificationType.UNKNOWN;
  }
  try {
    return NotificationType.values.firstWhere(
      (e) => e.toString() == 'NotificationType.$typeString',
    );
  } catch (e) {
    return NotificationType.UNKNOWN;
  }
}