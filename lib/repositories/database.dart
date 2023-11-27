import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realm/realm.dart' as realm;
import 'package:sprint/sprint.dart';
import 'package:universal_io/io.dart';

import 'package:flutter_todos/constants.dart' as constants;
import 'package:flutter_todos/structs/account.dart';

final _schemas = List<realm.SchemaObject>.unmodifiable([
  Account.schema,
  Profile.schema,
  Todos.schema,
  Todo.schema,
  TodoRow.schema,
]);

class DatabaseRepository {
  final Sprint log;

  final realm.Realm database;

  DatabaseRepository._({required this.log, required this.database});

  factory DatabaseRepository.create({required Directory directory}) {
    final log = Sprint('Database');

    final path = '${directory.path}/${constants.databaseFile}';

    log
      ..info('Opening database...')
      ..debug('Database location: $path');

    final configuration = realm.Configuration.local(
      _schemas,
      path: path,
      // TODO(vxern): ONLY IN DEBUG.
      shouldDeleteIfMigrationNeeded: true,
    );
    final database = realm.Realm(configuration);

    log.success('Database opened.');

    return DatabaseRepository._(log: log, database: database);
  }

  static RepositoryProvider<DatabaseRepository> getProvider({
    required Directory directory,
    required Widget child,
  }) =>
      RepositoryProvider.value(
        value: DatabaseRepository.create(directory: directory),
        child: child,
      );

  Future<void> dispose() async {
    database.close();
  }
}
