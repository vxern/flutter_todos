import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_todos/cubits.dart';
import 'package:flutter_todos/utils.dart';
import 'package:realm/realm.dart';
import 'package:sprint/sprint.dart';
import 'package:universal_io/io.dart';

import 'package:flutter_todos/constants.dart' as constants;
import 'package:flutter_todos/structs/account.dart';

final _schemas = List<SchemaObject>.unmodifiable([
  Account.schema,
  Profile.schema,
  Todos.schema,
  Todo.schema,
  TodoRow.schema,
]);

typedef RealmOpener = Realm Function({required String path});

Realm _defaultRealmOpener({required String path}) => Realm(
      Configuration.local(
        _schemas,
        path: path,
        // TODO(vxern): ONLY IN DEBUG.
        shouldDeleteIfMigrationNeeded: true,
      ),
    );

class DatabaseRepository with Loggable, Initialisable, Disposable {
  @override
  bool isDisposed = false;

  @override
  final Sprint log;

  // * Visible for testing.
  final initialisationCubit = InitialisationCubit();

  final Directory directory;
  Realm? _realm;

  /// ! Throws a [StateError] if [DatabaseRepository] has not been initialised.
  Realm get realm => _realm!;

  // * Visible for testing.
  final RealmOpener openRealmDebug;

  DatabaseRepository({
    required this.directory,
    // * Visible for testing.
    RealmOpener? openRealmDebug,
  })  : log = Sprint('Database'),
        openRealmDebug = openRealmDebug ?? _defaultRealmOpener;

  /// ! Throws:
  /// - ! [InitialisationException] upon failing to initialise.
  /// - ! (propagated) [StateError] if the repository is disposed.
  /// - ! [StateError] if the repository has already been initialised.
  @override
  Future<void> initialise() async {
    verifyNotDisposed();

    if (initialisationCubit.isInitialised) {
      throw StateError(
        'Attempted to initialise DatabaseRepository when already initialised.',
      );
    }

    initialisationCubit.declareInitialising();
    log.info('Opening database...');

    final path = '${directory.path}/${constants.databaseFile}';
    log.debug('Database location: $path');

    if (_realm == null) {
      try {
        _realm = openRealmDebug(path: directory.path);
      } on FileSystemException catch (exception) {
        initialisationCubit.declareFailed();

        log
          ..severe('Unable to access Realm database file. Missing permissions?')
          ..severe(exception);

        throw const InitialisationException();
      } on RealmException catch (exception) {
        initialisationCubit.declareFailed();

        log
          ..fatal('Failed to open Realm database file.')
          ..fatal(exception);

        throw const InitialisationException();
      }
    }

    initialisationCubit.declareInitialised();
    log.success('Database opened.');
  }

  static RepositoryProvider<DatabaseRepository> getProvider({
    required Directory directory,
  }) =>
      RepositoryProvider.value(value: DatabaseRepository(directory: directory));

  @override
  Future<void> dispose() {
    isDisposed = true;

    _realm?.close();

    return initialisationCubit.close();
  }
}
