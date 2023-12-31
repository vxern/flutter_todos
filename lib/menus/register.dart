import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sprint/sprint.dart';

import 'package:flutter_todos/repositories/authentication.dart';
import 'package:flutter_todos/repositories/repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final log = Sprint('Registration');

  final _formKey = GlobalKey<FormState>();

  late String username;
  String? nickname;
  late String password;

  Future<void> _register() async {
    final messenger = ScaffoldMessenger.of(context);
    final authentication = context.read<AuthenticationRepository>();

    messenger.showSnackBar(const SnackBar(content: Text('Registering...')));
    log.info('Registering account for $username...');

    try {
      await authentication.register(
        username: username,
        nickname: nickname,
        password: password,
      );
    } on AuthenticationException catch (exception) {
      messenger.showSnackBar(SnackBar(content: Text(exception.message)));
      log.warn('Failed to register: $exception');
      return;
    } on ResourceException catch (exception) {
      messenger.showSnackBar(SnackBar(content: Text(exception.message)));
      log.severe(exception);
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Registered successfully.')),
    );
    log.success('Account registered for $username.');

    await Future<void>.delayed(const Duration(seconds: 1));

    if (context.mounted) {
      context.goNamed('login');
    }
  }

  Future<void> _onFormSubmit() async {
    final state = _formKey.currentState;
    if (state == null) {
      return;
    }

    if (!state.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in the correct data before submitting.'),
        ),
      );
      return;
    }

    await _register();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Register')),
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
                    if (value == null || value.isEmpty) {
                      return 'Please input a username.';
                    }

                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(hintText: 'Nickname'),
                  onChanged: (value) => nickname = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please input a nickname.';
                    }

                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(hintText: 'Password'),
                  onChanged: (value) => password = value,
                  obscureText: true,
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
                        onPressed: _onFormSubmit,
                        child: const Text('Register'),
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
