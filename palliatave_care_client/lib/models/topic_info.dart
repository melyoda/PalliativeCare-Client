class TopicInfo {
  final String id;
  final String title;
  final String? description;
  final String? logoUrl;

  TopicInfo({
    required this.id,
    required this.title,
    this.description,
    this.logoUrl,
  });

  factory TopicInfo.fromJson(Map<String, dynamic> json) {
    return TopicInfo(
      id: json['topicId'] as String? ?? 'unknown_topic', // Mapped from topicId
      title: json['topicName'] as String? ?? 'Uncategorized',
      description: json['topicDescription'] as String?,
      logoUrl: json['topicLogoUrl'] as String?,
    );
  }
}