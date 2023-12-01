import 'package:realm/realm.dart';

import 'package:flutter_todos/cubits.dart';
import 'package:flutter_todos/repositories/authentication.dart';
import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/repositories/repository.dart';
import 'package:flutter_todos/structs/account.dart';

class TodoRepository extends Repository {
  final AuthenticationRepository _authentication;
  final DatabaseRepository _database;

  Todos? _todos;

  /// ! Throws a [StateError] if [TodoRepository] has not been initialised.
  Todos get todos {
    if (_todos == null) {
      throw StateError('Attempted to access todos before initialisation.');
    }

    return _todos!;
  }

  TodoRepository({
    required AuthenticationRepository authentication,
    required DatabaseRepository database,
  })  : _authentication = authentication,
        _database = database,
        super(name: 'TodoRepository');

  /// ! Throws:
  /// - ! [InitialisationException] upon failing to initialise.
  /// - ! (propagated) [StateError] if the repository is disposed.
  /// - ! (propagated) [StateError] if the repository has already been
  ///   ! initialised.
  @override
  Future<void> initialise() async {
    await super.initialise();

    initialisationCubit.declareInitialising();

    try {
      _todos = _authentication.account.todos;
    } on StateError catch (exception) {
      log.severe(exception);
      initialisationCubit.declareFailed();
      throw const InitialisationException();
    }

    initialisationCubit.declareInitialised();
  }

  // TODO(vxern): Add ID validation?

  /// ! Throws [ResourceException] if a to-do with the given ID does not exist.
  Todo find({required String id}) {
    final Todo todo;
    try {
      todo = todos.entries.firstWhere((todo) => todo.id.toString() == id);
    } on StateError {
      throw ResourceException(
        message:
            'Could not find todo with the ID $id. Has it been deleted already?',
      );
    }

    return todo;
  }

  /// ! Throws [ResourceException] if failed to add todo.
  Future<Todo> addTodo() async {
    final todo = Todo(Uuid.v4(), 'Draft', DateTime.now());

    try {
      await _database.realm.writeAsync(() => todos.entries.add(todo));
    } on RealmException catch (exception) {
      log.severe(exception);
      throw const ResourceException(message: 'Failed to add todo.');
    }

    return todo;
  }

  /// ! Throws [ResourceException] if failed to remove todo.
  Future<void> removeTodo({required Todo todo}) async {
    try {
      await _database.realm.writeAsync(
        () => _database.realm.deleteMany(todo.rows),
      );
    } on RealmException catch (exception) {
      log.severe(exception);
      throw const ResourceException(message: 'Failed to remove todo rows.');
    }

    try {
      await _database.realm.writeAsync(() => _database.realm.delete(todo));
    } on RealmException catch (exception) {
      log.severe(exception);
      throw const ResourceException(message: 'Failed to remove todo.');
    }
  }

  /// ! Throws [ResourceException] if failed to add todo row.
  Future<TodoRow> addRow({required Todo todo}) async {
    final row = TodoRow('');

    try {
      await _database.realm.writeAsync(() => todo.rows.add(row));
    } on RealmException catch (exception) {
      log.severe(exception);
      throw const ResourceException(message: 'Failed to add todo row.');
    }

    return row;
  }

  /// ! Throws [ResourceException] if failed to remove todo row.
  Future<void> removeRow({required TodoRow row}) async {
    try {
      await _database.realm.writeAsync(() => _database.realm.delete(row));
    } on RealmException catch (exception) {
      log.severe(exception);
      throw const ResourceException(message: 'Failed to remove todo row.');
    }
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    _todos = null;
  }
}
