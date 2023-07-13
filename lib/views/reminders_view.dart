// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mobx_tut/dialog/delete_reminder_dialog.dart';
import 'package:mobx_tut/dialog/text_filed_dialog.dart';
import 'package:mobx_tut/state/app_state.dart';
import 'package:mobx_tut/views/main_popup_menu_button.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class RemindersView extends StatelessWidget {
  const RemindersView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reminder"),
        actions: [
          IconButton(
            onPressed: () async {
              final reminderText = await showTextFieldDialog(
                context: context,
                title: 'What do you want me to remind you about?',
                hintText: 'Enter your reminder text here',
                optionsBuilder: () => {
                  TextFieldDialogButtonType.cancel: 'Cancel',
                  TextFieldDialogButtonType.confirm: 'Confirm',
                },
              );
              if (reminderText == null) return;
              context.read<AppState>().createReminder(reminderText);
            },
            icon: const Icon(
              Icons.add,
            ),
          ),
          const MainPopupMenuButton()
        ],
      ),
      body: const ReminderListView(),
    );
  }
}

class ReminderListView extends StatelessWidget {
  const ReminderListView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Observer(
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: appState.sortedReminders.length,
          itemBuilder: (context, index) {
            final reminder = appState.sortedReminders[index];
            return Observer(builder: (context) {
              return CheckboxListTile(
                value: reminder.isDone,
                onChanged: (isDone) {
                  context.read<AppState>().modifyReminder(
                        reminderId: reminder.id,
                        isDone: isDone ?? false,
                      );
                  reminder.isDone = isDone ?? false;
                },
                title: Row(
                  children: [
                    Expanded(
                      child: Text(reminder.text),
                    ),
                    IconButton(
                        onPressed: () async {
                          final shouldDeleteReminder =
                              await showDeleteReminderDialog(context);
                          if (shouldDeleteReminder) {
                            context.read<AppState>().delete(reminder);
                          }
                        },
                        icon: const Icon(Icons.delete))
                  ],
                ),
              );
            });
          },
        );
      },
    );
  }
}
