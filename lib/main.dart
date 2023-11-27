import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_todos/repositories/app.dart';
import 'package:flutter_todos/repositories/app/directories.dart';
import 'package:flutter_todos/repositories/authentication.dart';
import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/repositories/todos.dart';
import 'package:flutter_todos/router.dart';

void main() => runApp(
      FlutterTodos.bootstrap(
        base: (context, state) => MaterialApp.router(
          title: 'Flutter Todos',
          routerConfig: router,
          theme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
            ),
          ),
        ),
      ),
    );

class FlutterTodos extends StatelessWidget {
  final BlocWidgetBuilder<DirectoriesLoadedState> base;

  const FlutterTodos._({required this.base});

  factory FlutterTodos.bootstrap({
    required BlocWidgetBuilder<DirectoriesLoadedState> base,
  }) =>
      FlutterTodos._(base: base);

  @override
  Widget build(BuildContext context) => AppRepository.getProvider(
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
                  return DatabaseRepository.getProvider(
                    directory: state.directories.documents,
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
                        child: base(context, state),
                      ),
                    ),
                  );
              }
            },
          ),
        ),
      );
}
