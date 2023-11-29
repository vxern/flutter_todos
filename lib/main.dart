import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_todos/repositories/application.dart';
import 'package:flutter_todos/repositories/authentication.dart';
import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/repositories/loaders/directories_bloc.dart';
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
  Widget build(BuildContext context) => RepositoryProvider.value(
        value: ApplicationRepository()
          ..directories.bloc.add(const DirectoriesLoading()),
        child: Builder(
          builder: (context) => BlocConsumer<DirectoriesBloc, DirectoriesState>(
            bloc: context.read<ApplicationRepository>().directories.bloc,
            listener: (context, state) async {
              if (state is DirectoriesLoadingState) {
                await context.read<ApplicationRepository>().initialise();
                return;
              }
            },
            builder: (context, state) {
              switch (state) {
                case DirectoriesNotLoadedState():
                case DirectoriesLoadingState():
                  return const MaterialApp(
                    home: Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    ),
                  );
                case DirectoriesLoadingFailedState():
                  return const MaterialApp(
                    home: Scaffold(
                      body: Center(
                        child: Text('Failed to load directories.'),
                      ),
                    ),
                  );
                case DirectoriesLoadedState():
                  return RepositoryProvider.value(
                    value: DatabaseRepository(
                      directory: state.directories.documents,
                    ),
                    child: Builder(
                      builder: (context) => MultiRepositoryProvider(
                        providers: [
                          RepositoryProvider.value(
                            value: AuthenticationRepository(
                              database: context.read<DatabaseRepository>(),
                            ),
                          ),
                          RepositoryProvider.value(
                            value: TodoRepository(
                              database: context.read<DatabaseRepository>(),
                            ),
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
