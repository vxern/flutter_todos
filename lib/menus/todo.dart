import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realm/realm.dart';

import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/repositories/todos.dart';
import 'package:flutter_todos/structs/account.dart';
import 'package:flutter_todos/widgets/editable_list_tile.dart';

class TodoState {
  final List<TodoRow> rows;

  const TodoState({required this.rows});
}

class TodoCubit extends Cubit<TodoState> {
  late final StreamSubscription _changes;

  TodoCubit({required RealmList<TodoRow> rows}) : super(TodoState(rows: rows)) {
    _changes = rows.changes.listen(
      (change) => emit(TodoState(rows: change.list)),
    );
  }

  @override
  Future<void> close() async => Future.wait([super.close(), _changes.cancel()]);
}

class TodoPage extends StatefulWidget {
  final Todo _todo;
  final TodoCubit cubit;

  TodoPage({required Todo todo, super.key})
      : _todo = todo,
        cubit = TodoCubit(rows: todo.rows);

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  Transaction? _transaction;

  Future<void> _addTodoRow() async {
    final todos = context.read<TodoRepository>();

    await todos.addRow(todo: widget._todo);
  }

  Future<void> _removeTodoRow(TodoRow row) async {
    final todos = context.read<TodoRepository>();

    await todos.removeRow(row: row);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget._todo.title)),
        body: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<TodoCubit, TodoState>(
                  bloc: widget.cubit,
                  builder: (context, state) {
                    if (state.rows.isEmpty) {
                      return const Text(
                        "No to-do's yet.\nPress 'Create' to create one.",
                        textAlign: TextAlign.center,
                      );
                    }

                    return ListView.separated(
                      itemCount: state.rows.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final row = state.rows[index];

                        return EditableListTile(
                          icon: Icons.delete_outline,
                          initialContents: row.contents,
                          onRemove: () async => _removeTodoRow(row),
                          onContentsChanged: (value) async {
                            final database = context.read<DatabaseRepository>();

                            _transaction ??=
                                await database.realm.beginWriteAsync();
                            row.contents = value;
                          },
                          onContentsSubmitted: (event) async {
                            await _transaction?.commitAsync();
                            _transaction = null;
                          },
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
                      onPressed: _addTodoRow,
                      child: const Text('Add Item'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => context.goNamed('todos'),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Future<void> dispose() async {
    super.dispose();
    await _transaction?.commitAsync();
  }
}
