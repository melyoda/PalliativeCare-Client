import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palliatave_care_client/models/comment.dart' as model;

class CommentCard extends StatelessWidget {
  final model.Comment comment;

  const CommentCard({super.key, required this.comment});

  String _initials(String firstName, String lastName) {
    final f = (firstName.isNotEmpty ? firstName[0] : '').toUpperCase();
    final l = (lastName.isNotEmpty ? lastName[0] : '').toUpperCase();
    return (f + l).trim().isEmpty ? '?' : (f + l);
    }

  @override
  Widget build(BuildContext context) {
    final a = comment.author;
    final when = DateFormat.yMMMd().add_jm().format(comment.timestamp);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // avatar
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
              child: Text(
                _initials(a.firstName, a.lastName),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // name + role + time
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${a.firstName} ${a.lastName}',
                          style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${a.role})',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text(
                        when,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    comment.text,
                    style: const TextStyle(fontSize: 14, height: 1.4),
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
