class Author {
  final String id;
  final String firstName;
  final String lastName;
  final String role;
  // final String? profilePictureUrl; // Uncomment if your AuthorDTO includes this

  Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    // this.profilePictureUrl,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['authorId'] as String? ?? 'unknown', // Mapped from authorId
      firstName: json['authorFirstName'] as String? ?? 'Unknown',
      lastName: json['authorLastName'] as String? ?? 'User',
      role: json['authorRole'] as String? ?? 'N/A',
      // profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }
}