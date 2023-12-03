import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_todos/widgets/editable_list_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:realm/realm.dart';

import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/repositories/todos.dart';
import 'package:flutter_todos/structs/account.dart';

class TodosState {
  final List<Todo> entries;

  const TodosState({required this.entries});
}

class TodosCubit extends Cubit<TodosState> {
  late final StreamSubscription _changes;

  TodosCubit({required RealmList<Todo> entries})
      : super(TodosState(entries: entries)) {
    _changes = entries.changes
        .listen((change) => emit(TodosState(entries: change.list)));
  }

  @override
  Future<void> close() async => Future.wait([super.close(), _changes.cancel()]);
}

class TodosPage extends StatelessWidget {
  final TodosCubit cubit;

  TodosPage({required Todos todos, super.key})
      : cubit = TodosCubit(entries: todos.entries);

  Transaction? databaseTransaction;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Todos')),
        body: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<TodosCubit, TodosState>(
                  bloc: cubit,
                  builder: (context, state) {
                    if (state.entries.isEmpty) {
                      return const Text(
                        "No to-do lists yet.\nPress 'Create' to create one.",
                        textAlign: TextAlign.center,
                      );
                    }

                    return ListView.separated(
                      itemCount: state.entries.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final Todo todo;
                        try {
                          todo = state.entries[index];
                        } on StateError {
                          throw StateError(
                            'Attempted to access todo using an invalid index. '
                            'Todo count: ${state.entries.length}, index: '
                            '$index',
                          );
                        }

                        final database = context.read<DatabaseRepository>();

                        return EditableListTile(
                          icon: Icons.delete_outline,
                          initialContents: todo.title,
                          onRemove: () async {
                            final todos = context.read<TodoRepository>();

                            unawaited(todos.removeTodo(todo: todo));
                          },
                          onContentsChanged: (value) {
                            databaseTransaction ??= database.realm.beginWrite();

                            todo.title = value;
                          },
                          onContentsSubmitted: (value) {
                            if (databaseTransaction == null) {
                              return;
                            }

                            databaseTransaction!.commit();
                            databaseTransaction = null;
                          },
                          onTap: () => context.go('/todo/${todo.id}'),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final todos = context.read<TodoRepository>();

                        unawaited(
                          todos
                              .addTodo()
                              .then((todo) => context.go('/todo/${todo.id}')),
                        );
                      },
                      child: const Text('Create'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => context.goNamed('home'),
                      child: const Text('Home'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
