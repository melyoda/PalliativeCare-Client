// lib/models/comment_dto.dart

class CommentDTO {
  final String text;

  CommentDTO({required this.text});

  // This method is essential for sending data to the server
  Map<String, dynamic> toJson() {
    return {
      'text': text,
    };
  }
}