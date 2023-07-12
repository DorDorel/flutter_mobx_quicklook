// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mobx_tut/dialog/delete_account_dialog.dart';
import 'package:mobx_tut/dialog/logout_dialog.dart';
import 'package:mobx_tut/state/app_state.dart';
import 'package:provider/provider.dart';

enum MenuAction { logout, deleteAccount }

class MainPopupMenuButton extends StatelessWidget {
  const MainPopupMenuButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MenuAction>(
      onSelected: (value) async {
        switch (value) {
          case MenuAction.logout:
            final shouldLogout = await showLogOutDialog(context);
            if (shouldLogout) context.read<AppState>().logOut();
            break;
          case MenuAction.deleteAccount:
            final shouldDeleteAccount = await showDeleteAccountDialog(context);
            if (shouldDeleteAccount) context.read<AppState>().deleteAccount();
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem<MenuAction>(
            value: MenuAction.logout,
            child: Text("Log out"),
          ),
          const PopupMenuItem<MenuAction>(
            value: MenuAction.deleteAccount,
            child: Text("Delete Account"),
          ),
        ];
      },
    );
  }
}
