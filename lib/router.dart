import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_todos/menus/home.dart';
import 'package:flutter_todos/menus/login.dart';
import 'package:flutter_todos/menus/register.dart';
import 'package:flutter_todos/menus/todo.dart';
import 'package:flutter_todos/menus/todos.dart';
import 'package:flutter_todos/repositories/authentication.dart';
import 'package:flutter_todos/repositories/todos.dart';
import 'package:flutter_todos/widgets/foundation/initialisation_arbiter.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _authenticationNavigatorKey = GlobalKey<NavigatorState>();
final _todosNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      name: 'home',
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    ShellRoute(
      navigatorKey: _todosNavigatorKey,
      builder: arbiterGuard(
        (context, child) => InitialisationArbiter(
          name: #todos,
          initialisers: [context.read<TodoRepository>().initialisationCubit],
          initialise: () async {
            final todos = context.read<TodoRepository>();
            if (todos.initialisationCubit.isInitialised) {
              return;
            }
            await todos.initialise();
          },
          whenInitialising: (context) => const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          ),
          whenFailed: (context, initialiser) => const MaterialApp(
            home: Scaffold(body: Center(child: Text('Failed to load todos.'))),
          ),
          whenDone: (context) => child,
        ),
      ),
      routes: [
        GoRoute(
          name: 'todos',
          path: '/todos',
          builder: (context, state) {
            final authentication = context.read<AuthenticationRepository>();

            final todoList = authentication.account.todos;
            if (todoList == null) {
              throw StateError(
                'Attempted to access todos when no todos exist.',
              );
            }

            return TodosPage(todos: todoList);
          },
          redirect: redirectIfUnauthenticated,
        ),
        GoRoute(
          path: '/todo/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;

            final authentication = context.read<AuthenticationRepository>();
            final todos = context.read<TodoRepository>();

            final todoList = authentication.account.todos;
            if (todoList == null) {
              throw StateError(
                'Attempted to access todo with ID $id when no todos exist.',
              );
            }

            final todo = todos.find(id: id);

            return TodoPage(todo: todo);
          },
          redirect: (context, state) async {
            final redirect = await redirectIfUnauthenticated(context, state);
            if (redirect != null) {
              return redirect;
            }

            if (!state.pathParameters.containsKey('id')) {
              throw StateError(
                'Attempted to navigate to todo page without ID.',
              );
            }

            return null;
          },
        ),
      ],
    ),
    ShellRoute(
      navigatorKey: _authenticationNavigatorKey,
      builder: (context, state, child) => child,
      routes: [
        GoRoute(
          name: 'login',
          path: '/login',
          builder: (context, state) => const LoginPage(),
          redirect: redirectIfAuthenticated,
        ),
        GoRoute(path: '/authenticate', redirect: (context, state) => '/login'),
        GoRoute(path: '/auth', redirect: (context, state) => '/login'),
        GoRoute(
          name: 'register',
          path: '/register',
          builder: (context, state) => const RegisterPage(),
          redirect: redirectIfAuthenticated,
        ),
      ],
    ),
  ],
);

Future<String?> redirectIfUnauthenticated(
  BuildContext context,
  GoRouterState state,
) async {
  final authentication = context.read<AuthenticationRepository>();
  if (authentication.isNotAuthenticated) {
    return '/login';
  }

  return null;
}

Future<String?> redirectIfAuthenticated(
  BuildContext context,
  GoRouterState state,
) async {
  final authentication = context.read<AuthenticationRepository>();
  if (authentication.isAuthenticated) {
    return '/todos';
  }

  return null;
}

typedef ArbiterGetter = InitialisationArbiter Function(
  BuildContext context,
  Widget child,
);

ShellRouteBuilder arbiterGuard(ArbiterGetter getArbiter) =>
    (context, state, child) {
      final arbiter = getArbiter(context, child);

      if (arbiter.isInitialised) {
        return child;
      }

      return arbiter;
    };
