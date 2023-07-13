import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:mobx_tut/dialog/auth_error_dialog.dart';
import 'package:mobx_tut/loading/loading_screen.dart';
import 'package:mobx_tut/provider/auth_provider.dart';
import 'package:mobx_tut/provider/reminders_provider.dart';
import 'package:mobx_tut/state/app_state.dart';
import 'package:mobx_tut/views/login_view.dart';
import 'package:mobx_tut/views/register_view.dart';
import 'package:mobx_tut/views/reminders_view.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    Provider(
      create: (_) => AppState(
        authProvider: FirebaseAuthProvider(),
        reminderProvider: FirestoreRemindersProvider(),
      )..initialize(),
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      title: "MobxTut",
      home: ReactionBuilder(
        builder: (context) {
          return autorun(
            (_) {
              final isLoading = context.read<AppState>().isLoading;
              if (isLoading) {
                LoadingScreen.instance()
                    .show(context: context, text: "Loading...");
              } else {
                LoadingScreen.instance().hide();
              }

              final authError = context.read<AppState>().authError;
              if (authError != null) {
                showAuthError(
                  authError: authError,
                  context: context,
                );
              }
            },
          );
        },
        child: Observer(
          name: "CurrentScreen",
          builder: (context) {
            switch (context.read<AppState>().currentScreen) {
              case AppScreen.login:
                return const LoginView();
              case AppScreen.register:
                return const RegisterView();
              case AppScreen.reminders:
                return const RemindersView();
            }
          },
        ),
      ),
    );
  }
}
