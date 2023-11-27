import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
        ),
        body: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () => context.goNamed('login'),
                child: const Text('Login'),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => context.goNamed('register'),
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      );
}
