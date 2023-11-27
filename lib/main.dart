import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_todos/repositories/app.dart';
import 'package:flutter_todos/repositories/app/directories.dart';
import 'package:flutter_todos/repositories/authentication.dart';
import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/repositories/todos.dart';
import 'package:flutter_todos/router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => AppRepository.getProvider(
        // Allows for getting the context that now includes [AppRepository].
        child: Builder(
          builder: (context) => BlocConsumer<DirectoryBloc, DirectoryState>(
            bloc: context.read<AppRepository>().directories,
            listener: (context, state) async {
              if (state is DirectoriesLoadingState) {
                await context.read<AppRepository>().load();
                return;
              }
            },
            builder: (context, state) {
              switch (state) {
                case DirectoriesInitialState():
                case DirectoriesLoadingState():
                  return const MaterialApp(
                    home: Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    ),
                  );
                case DirectoriesLoadFailureState():
                  return const MaterialApp(
                    home: Scaffold(
                      body: Center(
                        child: Text('Failed to load directories.'),
                      ),
                    ),
                  );
                case DirectoriesLoadedState():
                  return MultiRepositoryProvider(
                    providers: [
                      DatabaseRepository.getProvider(
                        directory: state.directories.documents,
                      ),
                    ],
                    child: Builder(
                      builder: (context) => MultiRepositoryProvider(
                        providers: [
                          AuthenticationRepository.getProvider(
                            database: context.read<DatabaseRepository>(),
                          ),
                          TodoRepository.getProvider(
                            database: context.read<DatabaseRepository>(),
                          ),
                        ],
                        child: MaterialApp.router(
                          title: 'Sample Flutter Project',
                          routerConfig: router,
                          theme: ThemeData(
                            colorScheme: ColorScheme.fromSeed(
                              seedColor: Colors.deepPurple,
                            ),
                            useMaterial3: true,
                          ),
                        ),
                      ),
                    ),
                  );
              }
            },
          ),
        ),
      );
}
