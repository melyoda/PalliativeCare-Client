// Error dialog widget - often in a `widgets/info_dialog.dart` file
import 'package:flutter/material.dart';

class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isError;
  const InfoDialog({super.key, required this.title, required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, style: TextStyle(color: isError ? Colors.red : Colors.green)),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}