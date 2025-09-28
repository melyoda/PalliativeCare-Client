import 'package:flutter/material.dart';


// A flexible PostCard that only cares about the data it needs to display.
class PostCard extends StatelessWidget {
  final String authorName;
  final String authorRole;
  final String timeAgo;
  final String topicName;
  final String title;
  final String content;
  final int commentCount;
  // final int likeCount;
  // final bool isLiked;
  final int readTimeMinutes;
  final String? imageUrl;
  final VoidCallback? onTap; // Optional: for making the whole card tappable

  const PostCard({
    super.key,
    required this.authorName,
    required this.authorRole,
    required this.timeAgo,
    required this.topicName,
    required this.title,
    required this.content,
    required this.commentCount,
    // this.likeCount = 0, // Default values for fields not in the simple Post model
    // this.isLiked = false,
    this.readTimeMinutes = 0,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
      // print('PostCard is trying to load image URL: $imageUrl');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0), // Added horizontal margin
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell( // Wrap with InkWell to make it tappable
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info and Topic
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Text(
                      authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName, // Use the direct property
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '$authorRole • $timeAgo', // Use direct properties
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      topicName, // Use the direct property
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Post Title
              Text(
                title, // Use the direct property
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),

              // Post Content
              Text(
                content, // Use the direct property
                style: const TextStyle(fontSize: 14, color: Colors.black54),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Post Image
              if (imageUrl != null && imageUrl!.isNotEmpty)
                ClipRRect(
                  // ... (Image display code is the same, just uses `imageUrl!`)
                ),
              if (imageUrl != null && imageUrl!.isNotEmpty) const SizedBox(height: 16),

              // Engagement Row
              Row(
                children: [
                  Icon(Icons.comment_outlined, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('$commentCount', style: TextStyle(color: Colors.grey[600])),
                  const Spacer(),
                  // Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                  // const SizedBox(width: 4),
                  // Text('$readTimeMinutes min read', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}