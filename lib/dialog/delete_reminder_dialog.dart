import 'package:flutter/material.dart' show BuildContext;
import 'package:mobx_tut/dialog/app_dialog.dart';

Future<bool> showDeleteReminderDialog(BuildContext context) {
  return appDialog<bool>(
    context: context,
    title: 'Delete reminder',
    content:
        'Are you sure you want to delete this reminder? You cannot undo this action!',
    optionsBuilder: () => {
      'Cancel': false,
      'Delete': true,
    },
  ).then(
    (value) => value ?? false,
  );
}