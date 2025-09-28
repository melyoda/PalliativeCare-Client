import 'package:flutter/material.dart';
import 'package:palliatave_care_client/models/resource.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:palliatave_care_client/pages/video_player_page.dart';

class ResourceCard extends StatelessWidget {
  final Resource resource;

  const ResourceCard({super.key, required this.resource});

  // 1) Smarter image detection: type or URL extension
  // bool _looksLikeImage(Resource r) {
  //   final t = r.type.trim().toUpperCase();       // no ?? ''
  //   final url = r.contentUrl.toLowerCase();      // no ?? ''
  //   final isTypeImage = t == 'IMAGE' ||
  //       t == 'IMG' ||
  //       t == 'PHOTO' ||
  //       t == 'PICTURE' ||
  //       t == 'INFOGRAPHIC';
  //   final isExtImage =
  //       RegExp(r'\.(png|jpe?g|gif|webp|bmp|heic)(\?.*)?$').hasMatch(url);
  //   return isTypeImage || isExtImage;
  // }

  // Helper function to check if a URL is for an image
  bool _isImage(String url) {
    final fileExtension = url.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileExtension);
  }

  // Helper function to check if a URL is for a video
  bool _isVideo(String url) {
    final fileExtension = url.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(fileExtension);
  }


 IconData _getResourceIcon(String type) {
  final t = type.toUpperCase();
  switch (t) {
    case 'IMAGE':
    case 'IMG':
    case 'PHOTO':
    case 'PICTURE':
    case 'INFOGRAPHIC':
      return Icons.image;
    case 'VIDEO':
      return Icons.videocam;
    case 'PDF':
    case 'DOCUMENT':
    case 'TEXT':
      return Icons.insert_drive_file;
    default:
      return Icons.attachment;
  }
}


 // This is the updated tap handler
  Future<void> _handleResourceTap(BuildContext context, Resource resource) async {
    final url = resource.contentUrl;
    final uri = Uri.parse(url);

    // ✅ NEW LOGIC: Check if it's a video first
    if (_isVideo(url)) {
      // If it's a video, open our in-app video player page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerPage(videoUrl: url),
        ),
      );
    } else {
      // For anything else, use the original logic to open it externally
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text('Could not open resource. URL: $url'),
            actions: [ TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')) ],
          ),
        );
      }
    }
  }

 @override
Widget build(BuildContext context) {
  final url = resource.contentUrl;
  final String displayName = (resource.fileName != null && resource.fileName!.isNotEmpty)
      ? resource.fileName!
      : url.split('/').last.split('?').first;

  Widget contentWidget;
  String actionText = 'View'; // You can translate these later
  IconData actionIcon = Icons.visibility_outlined;

  if (_isImage(url)) {
    contentWidget = ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0)),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      ),
    );
    actionText = 'View Image';
    actionIcon = Icons.image_outlined;
  } else if (_isVideo(url)) { // ✅ UPDATED CHECK
    contentWidget = Container(
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.play_circle_fill_outlined, size: 50, color: Colors.white70),
      ),
    );
    actionText = 'Watch Video';
    actionIcon = Icons.play_arrow_outlined;
  } else {
    contentWidget = Container(
      color: Colors.blueGrey[50],
      child: Center(
        child: Icon(_getResourceIcon(resource.type), size: 50, color: Colors.blueGrey[400]),
      ),
    );
    actionText = 'Open File';
    actionIcon = Icons.launch_outlined;
  }

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      // ✅ UPDATED ONTAP CALL
      onTap: () => _handleResourceTap(context, resource),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: contentWidget),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row( // Simplified the bottom part for clarity
              children: [
                Icon(actionIcon, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    displayName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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