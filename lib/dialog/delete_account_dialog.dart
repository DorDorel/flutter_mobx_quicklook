import 'package:flutter/material.dart';
import 'package:mobx_tut/dialog/app_dialog.dart';

Future<bool> showDeleteAccountDialog(BuildContext context) {
  return appDialog<bool>(
    context: context,
    title: 'Delete account',
    content:
        'Are you sure you want to delete your account? You cannot undo this operation!',
    optionsBuilder: () => {
      'Cancel': false,
      'Delete account': true,
    },
  ).then(
    (value) => value ?? false,
  );
}