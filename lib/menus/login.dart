import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sprint/sprint.dart';

import 'package:flutter_todos/repositories/authentication.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final log = Sprint('Registration');

  final _formKey = GlobalKey<FormState>();

  late String username;
  late String password;

  Future<void> login() async {
    final authentication = context.read<AuthenticationRepository>();

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Logging in...')));

    log.info('Logging into $username...');

    try {
      await authentication.login(username: username, password: password);
    } on AlreadyLoggedInException catch (exception) {
      await authentication.logout();

      log.severe(exception);

      context.goNamed('home');

      return;
    } on AuthenticationException catch (exception) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(exception.message)));

      log.warn('Failed to log in: $exception');

      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Logged in successfully.')));

    log.success('Logged into $username.');

    await Future.delayed(const Duration(seconds: 1));

    context.goNamed('todos');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: Padding(
          padding: const EdgeInsets.all(50),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(hintText: 'Username'),
                  onChanged: (value) => username = value,
                  validator: (value) {
                    if (value == null) {
                      return 'Please input a username.';
                    }

                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(hintText: 'Password'),
                  obscureText: true,
                  onChanged: (value) => password = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please input a password.';
                    }

                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill in the correct data before submitting.',
                                ),
                              ),
                            );
                            return;
                          }

                          login();
                        },
                        child: const Text('Login'),
                      ),
                      Container(width: 10),
                      ElevatedButton(
                        onPressed: () => context.goNamed('home'),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
