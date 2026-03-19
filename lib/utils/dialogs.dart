import 'package:flutter/material.dart';

Future<bool?> showDeleteConfirmation(BuildContext context, String itemName) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete $itemName?'),
      content: const Text('Are you sure you want to delete this? This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
