import 'package:flutter/material.dart';
import 'package:mobx_tut/dialog/app_dialog.dart';

Future<bool> showLogOutDialog(BuildContext context) {
  return appDialog<bool>(
    context: context,
    title: 'Log out',
    content: 'Are you sure you want to log out?',
    optionsBuilder: () => {
      'Cancel': false,
      'Log out': true,
    },
  ).then(
    (value) => value ?? false,
  );
}