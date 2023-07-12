import 'package:flutter/material.dart';
import 'package:mobx_tut/auth/auth_error.dart';
import 'package:mobx_tut/dialog/app_dialog.dart';

Future<void> showAuthError({
  required AuthError authError,
  required BuildContext context,
}) {
  return appDialog<void>(
    context: context,
    title: authError.dialogTitle,
    content: authError.dialogText,
    optionsBuilder: () => {
      'OK': true,
    },
  );
}
