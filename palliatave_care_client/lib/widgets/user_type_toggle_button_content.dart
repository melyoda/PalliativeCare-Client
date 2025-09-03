
// Helper Widget for User Type Toggle Buttons - typically in `lib/widgets/user_type_toggle_button_content.dart`
import 'package:flutter/material.dart';

class UserTypeToggleButtonContent extends StatelessWidget { // Changed from _UserTypeToggleButtonContent
  final IconData icon;
  final String label;

  const UserTypeToggleButtonContent({ // Changed from _UserTypeToggleButtonContent
    super.key, // Added super.key for const constructor
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}