import 'package:flutter/material.dart';
import '../models/topic.dart';
// TopicCard Widget - For displaying individual topics in a grid
// TopicCard Widget - For displaying individual topics in a grid
class TopicCard extends StatelessWidget {
  final Topic topic;
  final bool isSubscribed;
  final VoidCallback onSubscribe;
  final VoidCallback onUnsubscribe;
  final VoidCallback onTap; // New onTap callback

  const TopicCard({
    super.key,
    required this.topic,
    required this.isSubscribed,
    required this.onSubscribe,
    required this.onUnsubscribe,
    required this.onTap, // Required
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias, // Ensures content is clipped to rounded corners
      child: InkWell(
        onTap: onTap, // Use the onTap callback
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (topic.logoUrl != null && topic.logoUrl!.isNotEmpty)
              Image.network(
                topic.logoUrl!,
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 80,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                ),
              )
            else
              Container(
                height: 80,
                width: double.infinity,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: Icon(Icons.category, size: 40, color: Colors.grey[400]),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topic.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: isSubscribed
                        ? ElevatedButton.icon(
                            onPressed: onUnsubscribe,
                            icon: const Icon(Icons.favorite_border, size: 18), // Heart outline for unsubscribe
                            label: const Text('Unsubscribe'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              textStyle: const TextStyle(fontSize: 14),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: onSubscribe,
                            icon: const Icon(Icons.favorite, size: 18), // Filled heart for subscribe
                            label: const Text('Subscribe'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // Green for subscribe
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              textStyle: const TextStyle(fontSize: 14),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
