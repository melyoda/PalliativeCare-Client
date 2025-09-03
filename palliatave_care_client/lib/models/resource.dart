class Resource {
  final String contentUrl; // Changed from 'url' to 'contentUrl' to match backend
  final String type; // e.g., "IMAGE", "VIDEO", "PDF", "INFOGRAPHIC", "TEXT"
  final String? fileName; // Optional file name (can be derived or provided)

  Resource({required this.contentUrl, required this.type, this.fileName});

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      contentUrl: json['contentUrl'] as String? ?? '', // Mapped from 'contentUrl'
      type: json['type'] as String? ?? 'UNKNOWN',
      fileName: json['fileName'] as String?, // Assuming backend might provide this
    );
  }
}