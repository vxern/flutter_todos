import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_todos/repositories/application.dart';
import 'package:flutter_todos/repositories/authentication.dart';
import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/repositories/todos.dart';
import 'package:flutter_todos/router.dart';
import 'package:flutter_todos/widgets/foundation/initialisation_arbiter.dart';

void main() => runApp(
      bootstrap(
        base: (context) => MaterialApp.router(
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

Widget bootstrap({required WidgetBuilder base}) => RepositoryProvider.value(
      value: ApplicationRepository.internal(),
      child: Builder(
        builder: (context) => InitialisationArbiter(
          name: #application,
          initialisers: context.read<ApplicationRepository>().loaders,
          initialise: () async {
            final application = context.read<ApplicationRepository>();
            if (application.initialisationCubit.isInitialised) {
              return;
            }

            await application.initialise();
          },
          whenInitialising: (context) => const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          ),
          whenFailed: (context, loader) => MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Failed to load ${loader.runtimeType}.'),
              ),
            ),
          ),
          whenDone: (context) => MultiRepositoryProvider(
            // These providers are in the order they should be getting
            // initialised in because each of them relies on the
            // previous one being present.
            providers: [
              RepositoryProvider.value(
                value: DatabaseRepository.singleton(
                  directory: context
                      .read<ApplicationRepository>()
                      .directories
                      .value
                      .documents,
                ),
              ),
              RepositoryProvider(
                lazy: false,
                create: (context) => AuthenticationRepository(
                  database: context.read<DatabaseRepository>(),
                ),
              ),
              RepositoryProvider(
                create: (context) => TodoRepository(
                  authentication: context.read<AuthenticationRepository>(),
                  database: context.read<DatabaseRepository>(),
                ),
              ),
            ],
            child: Builder(
              builder: (context) => InitialisationArbiter.repository(
                name: #core,
                repositories: [
                  context.read<DatabaseRepository>(),
                  context.read<AuthenticationRepository>(),
                ],
                whenInitialising: (context) => const MaterialApp(
                  home: Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                ),
                whenFailed: (context, initialiser) => MaterialApp(
                  home: Scaffold(
                    body: Center(
                      child: Text(
                        'Failed to initialise ${initialiser.runtimeType}.',
                      ),
                    ),
                  ),
                ),
                whenDone: base,
              ),
            ),
          ),
        ),
      ),
    );
