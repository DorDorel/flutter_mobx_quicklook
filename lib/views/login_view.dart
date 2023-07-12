import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobx_tut/extensions/if_debuging.dart';
import 'package:mobx_tut/state/app_state.dart';
import 'package:provider/provider.dart';

class LoginView extends HookWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailController =
        useTextEditingController(text: 'dorluzgarten@motorolla.com'.ifDebugging);
    final passwordController =
        useTextEditingController(text: "foobarbaz".ifDebugging);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Email',
              ),
              keyboardType: TextInputType.emailAddress,
              keyboardAppearance: Brightness.dark,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                hintText: 'password',
              ),
              obscureText: true,
              keyboardAppearance: Brightness.dark,
            ),
            TextButton(
              onPressed: () {
                final email = emailController.text;
                final password = emailController.text;
                context.read<AppState>().login(
                      email: email,
                      password: password,
                    );
              },
              child: const Text('Log In'),
            ),
            TextButton(
              onPressed: () {
                context.read<AppState>().goTo(AppScreen.register);
              },
              child: const Text('Not Registered yet? register here'),
            ),
          ],
        ),
      ),
    );
  }
}
