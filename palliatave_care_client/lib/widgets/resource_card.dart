import 'package:flutter/material.dart';
import 'package:palliatave_care_client/models/resource.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceCard extends StatelessWidget {
  final Resource resource;

  const ResourceCard({super.key, required this.resource});

  // 1) Smarter image detection: type or URL extension
  bool _looksLikeImage(Resource r) {
    final t = r.type.trim().toUpperCase();       // no ?? ''
    final url = r.contentUrl.toLowerCase();      // no ?? ''
    final isTypeImage = t == 'IMAGE' ||
        t == 'IMG' ||
        t == 'PHOTO' ||
        t == 'PICTURE' ||
        t == 'INFOGRAPHIC';
    final isExtImage =
        RegExp(r'\.(png|jpe?g|gif|webp|bmp|heic)(\?.*)?$').hasMatch(url);
    return isTypeImage || isExtImage;
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


  Future<void> _handleResourceTap(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text('Could not open resource. URL: $url'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = resource.contentUrl;
    final String displayName = (resource.fileName != null &&
            resource.fileName!.isNotEmpty)
        ? resource.fileName!
        : url.split('/').last.split('?').first;

    Widget contentWidget;
    String actionText = 'View';
    IconData actionIcon = Icons.visibility;

    if (_looksLikeImage(resource) && url.isNotEmpty) {
      // Render real image
      contentWidget = ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10.0),
          topRight: Radius.circular(10.0),
        ),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.cover,
          // (Optional) add a tiny fade while loading
          // loadingBuilder: (ctx, child, prog) => prog == null ? child : Container(color: Colors.grey[200]),
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          ),
        ),
      );
      actionText = 'Download';
      actionIcon = Icons.download;
    } else if ((resource.type).toUpperCase() == 'VIDEO' &&
        url.isNotEmpty) {
      contentWidget = Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
        ),
      );
      actionText = 'Watch';
      actionIcon = Icons.play_arrow;
    } else {
      contentWidget = Container(
        color: Colors.blueGrey[50],
        child: Center(
          child: Icon(_getResourceIcon(resource.type),
              size: 50, color: Colors.blueGrey[400]),
        ),
      );
      actionText = 'Download';
      actionIcon = Icons.download;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _handleResourceTap(context, url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: contentWidget),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style:
                        const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(actionIcon, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        actionText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
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
