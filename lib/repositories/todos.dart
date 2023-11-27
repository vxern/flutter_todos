import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realm/realm.dart';

import 'package:flutter_todos/repositories/authentication.dart';
import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/structs/account.dart';

class TodoRepository {
  final DatabaseRepository _database;

  TodoRepository._({required DatabaseRepository database})
      : _database = database;

  factory TodoRepository.create({required DatabaseRepository database}) =>
      TodoRepository._(database: database);

  static RepositoryProvider<TodoRepository> getProvider({
    required DatabaseRepository database,
  }) =>
      RepositoryProvider(
        create: (context) => TodoRepository.create(database: database),
      );

  Todo getById({required Todos todos, required String id}) {
    final Todo todo;
    try {
      todo = todos.entries.firstWhere((todo) => todo.id.toString() == id);
    } on StateError {
      throw StateError(
        'Could not find todo with the ID $id. Has it been deleted already?',
      );
    }

    return todo;
  }

  Future<Todo> addTodo({
    required AuthenticationRepository authentication,
  }) async {
    if (authentication.isNotAuthenticated) {
      throw StateError('Attempted to create todo while unauthenticated.');
    }

    final database = _database.database;

    final todo = Todo(Uuid.v4(), 'Draft', DateTime.now());

    try {
      await database.writeAsync(
        () {
          if (authentication.account!.todos == null) {
            authentication.account!.todos = Todos();
          }

          authentication.account!.todos!.entries.add(todo);
        },
      );
    } on RealmException catch (exception) {
      throw StateError('Encountered unexpected realm exception: $exception');
    }

    return todo;
  }

  Future<void> removeTodo({
    required AuthenticationRepository authentication,
    required Todo todo,
  }) async {
    if (authentication.isNotAuthenticated) {
      throw StateError('Attempted to remove todo while unauthenticated.');
    }

    final database = _database.database;

    try {
      await database.writeAsync(() => database.deleteMany(todo.rows));
      await database.writeAsync(() => database.delete(todo));
    } on RealmException catch (exception) {
      throw StateError('Encountered unexpected realm exception: $exception');
    }
  }

  Future<TodoRow> addRow({
    required AuthenticationRepository authentication,
    required Todo todo,
  }) async {
    if (authentication.isNotAuthenticated) {
      throw StateError('Attempted to add todo row while unauthenticated.');
    }

    final database = _database.database;

    final row = TodoRow('');

    try {
      await database.writeAsync(() => todo.rows.add(row));
    } on RealmException catch (exception) {
      throw StateError('Encountered unexpected realm exception: $exception');
    }

    return row;
  }

  Future<void> removeRow({
    required AuthenticationRepository authentication,
    required TodoRow row,
  }) async {
    if (authentication.isNotAuthenticated) {
      throw StateError('Attempted to remove todo row while unauthenticated.');
    }

    final database = _database.database;

    try {
      await database.writeAsync(
        () => database.delete<TodoRow>(row),
      );
    } on RealmException catch (exception) {
      throw StateError('Encountered unexpected realm exception: $exception');
    }
  }

  Future<void> dispose() async {}
}
