import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realm/realm.dart';
import 'package:universal_io/io.dart';

import 'package:flutter_todos/cubits.dart';
import 'package:flutter_todos/repositories/authentication.dart';
import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/repositories/todos.dart';
import 'package:flutter_todos/structs/account.dart';
import '../matchers.dart';

class MockRealm extends Mock implements Realm {}

class MockAccount extends Mock implements Account {}

class MockTodos extends Mock implements Todos {}

class MockTodo extends Mock implements Todo {}

class TestAuthenticationRepository extends AuthenticationRepository {
  TestAuthenticationRepository({required super.database});

  @override
  Future<String> deriveHash({required String password}) async => password;
}

class TestDatabaseRepository extends DatabaseRepository {
  TestDatabaseRepository({required super.directory});

  @override
  Realm openRealm({required String path}) => MockRealm();
}

void stubRealm(Realm realm) {
  when(realm.close).thenAnswer((_) {});
}

void stubAccount(Account account) {
  final todos = MockTodos();
  stubTodos(todos);

  when(() => account.username).thenReturn(username);
  when(() => account.passwordHash).thenReturn(password);
  when(() => account.todos).thenReturn(todos);
}

void stubTodos(Todos todos) {
  final todo = MockTodo();
  stubTodo(todo);

  when(() => todos.entries).thenReturn(RealmList([todo]));
}

void stubTodo(Todo todo) {
  final row = TodoRow('');

  when(() => todo.id).thenReturn(Uuid.nil);
  when(() => todo.rows).thenReturn(RealmList([row]));
}

void stubFinder<T extends RealmObject>(
  Realm realm,
  T? Function() valueBuilder,
) {
  when(() => realm.find<T>(any())).thenReturn(valueBuilder());
}

void stubAdder<T extends RealmObject>(Realm realm, T object) {
  when(() => realm.add<T>(object)).thenReturn(object);
}

void stubBulkDeleter<T extends RealmObject>(
  Realm realm,
  Iterable<T> objects,
  void Function() responseBuilder,
) {
  when(() => realm.deleteMany<T>(objects)).thenAnswer((_) => responseBuilder());
}

void stubDeleter<T extends RealmObjectBase>(
  Realm realm,
  T object,
  void Function() responseBuilder,
) {
  when(() => realm.delete<T>(object)).thenReturn(responseBuilder());
}

void stubWriter<T>(Realm realm, T Function() valueBuilder) {
  when(() => realm.writeAsync<void>(any(), any())).thenAnswer(
    (invocation) async => valueBuilder(),
  );
  when(() => realm.writeAsync<T>(any(), any())).thenAnswer(
    (invocation) async => valueBuilder(),
  );
}

final directory = Directory('');
const username = 'username';
const password = 'password';

void main() {
  group('TodoRepository', () {
    late DatabaseRepository database;
    late AuthenticationRepository authentication;
    late TodoRepository todos;

    setUp(() async {
      database = TestDatabaseRepository(directory: directory);

      await database.initialise();

      stubRealm(database.realm);

      authentication = TestAuthenticationRepository(database: database);

      final account = MockAccount();
      stubAccount(account);
      stubFinder<Account>(database.realm, () => account);

      await authentication.login(username: username, password: password);

      todos = TodoRepository(
        authentication: authentication,
        database: database,
      );
    });
    tearDown(
      () async => Future.wait(
        [database.dispose(), authentication.dispose(), todos.dispose()],
      ),
    );

    group('todos', () {
      test(
        'returns [Todos] if [TodoRepository] is initialised.',
        () async {
          await todos.initialise();

          expect(() => todos.todos, returnsNormally);
        },
      );

      test(
        'throws [StateError] if [TodoRepository] is not initialised.',
        () {
          expect(() => todos.todos, throwsStateError);
        },
      );
    });

    group('initialise()', () {
      test('initialises the repository.', () async {
        expect(todos.initialise(), completes);
      });

      test('throws a [StateError] when already initialised.', () async {
        await expectLater(todos.initialise(), completes);
        await expectLater(todos.initialise, throwsStateError);
      });

      test(
        'throws a [StateError] when [TodoRepository] is disposed.',
        () async {
          await expectLater(todos.initialise(), completes);
          await expectLater(todos.initialise, throwsStateError);
        },
      );

      test('updates the initialisation state.', () async {
        unawaited(
          expectLater(
            todos.initialisationCubit.stream,
            emitsInOrder([
              isA<InitialisingState>(),
              isA<InitialisationFailedState>(),
              isA<InitialisingState>(),
              isA<InitialisedState>(),
            ]),
          ),
        );

        await authentication.logout();

        await expectLater(todos.initialise(), throwsInitialisationException);

        await authentication.login(username: username, password: password);

        await expectLater(todos.initialise(), completes);
      });
    });

    group('find()', () {
      setUp(() async {
        await todos.initialise();
        stubTodos(todos.todos);
      });

      test('gets a todo by ID.', () async {
        expect(
          todos.find(id: Uuid.nil.toString()),
          equals(todos.todos.entries.first),
        );
      });

      test("throws a [ResourceException] when the todo doesn't exist.", () {
        expect(() => todos.find(id: '-1'), throwsResourceException);
      });
    });

    group('addTodo()', () {
      setUp(() async {
        await todos.initialise();
        stubTodos(todos.todos);
      });

      test('adds a todo.', () async {
        final todo = MockTodo();
        stubAdder<Todo>(database.realm, todo);
        stubWriter<Todo>(database.realm, () => todo);

        // TODO(vxern): Verify the returned value is the original todo.

        expect(todos.addTodo(), completes);
      });

      test(
        'throws a [ResourceException] when failed to add the todo.',
        () {
          final todo = MockTodo();
          stubAdder<Todo>(database.realm, todo);
          stubWriter<Todo>(database.realm, () {
            throw RealmException('');
          });

          expect(todos.addTodo(), throwsResourceException);
        },
      );
    });

    group('removeTodo()', () {
      late Todo todo;

      setUp(() async {
        await todos.initialise();
        stubTodos(todos.todos);
        todo = todos.todos.entries.first;
      });

      test('removes a todo.', () {
        stubBulkDeleter<TodoRow>(database.realm, todo.rows, () {});
        stubDeleter<Todo>(database.realm, todo, () => todo);
        stubWriter<Todo>(database.realm, () => todo);

        expect(todos.removeTodo(todo: todo), completes);
      });

      test(
        'throws a [ResourceException] when failed to remove todo rows.',
        () {
          stubBulkDeleter<TodoRow>(database.realm, todo.rows, () => todo.rows);
          stubWriter<RealmList<TodoRow>>(database.realm, () {
            throw RealmException('');
          });

          expect(() => todos.removeTodo(todo: todo), throwsResourceException);
        },
      );

      test(
        'throws a [ResourceException] when failed to remove the todo.',
        () {
          stubBulkDeleter<TodoRow>(database.realm, todo.rows, () {});
          stubDeleter<Todo>(database.realm, todo, () {});
          stubWriter<RealmList<Todo>>(database.realm, () {
            throw RealmException('');
          });

          expect(todos.removeTodo(todo: todo), throwsResourceException);
        },
      );
    });

    group('addRow()', () {
      late Todo todo;

      setUp(() async {
        await todos.initialise();
        stubTodos(todos.todos);
        todo = todos.todos.entries.first;
      });

      test('adds a todo row.', () {
        final row = TodoRow('');
        stubAdder<TodoRow>(database.realm, row);
        stubWriter<TodoRow>(database.realm, () => row);

        // TODO(vxern): Verify the returned value is the original row.

        expect(todos.addRow(todo: todo), completes);
      });

      test(
        'throws a [ResourceException] when failed to add the todo row.',
        () {
          final row = TodoRow('');
          stubAdder<TodoRow>(database.realm, row);
          stubWriter<TodoRow>(database.realm, () {
            throw RealmException('');
          });

          expect(todos.addRow(todo: todo), throwsResourceException);
        },
      );
    });

    group('removeRow()', () {
      late TodoRow row;

      setUp(() async {
        await todos.initialise();
        stubTodos(todos.todos);
        row = todos.todos.entries.first.rows.first;
      });

      test('removes a todo row.', () {
        stubDeleter<TodoRow>(database.realm, row, () => row);
        stubWriter<TodoRow>(database.realm, () => row);

        expect(todos.removeRow(row: row), completes);
      });

      test(
        'throws a [ResourceException] when failed to remove the todo row.',
        () {
          stubDeleter<TodoRow>(database.realm, row, () {});
          stubWriter<TodoRow>(database.realm, () {
            throw RealmException('');
          });

          expect(() => todos.removeRow(row: row), throwsResourceException);
        },
      );
    });

    group('dispose()', () {
      test('disposes of the repository.', () async {
        await expectLater(todos.dispose(), completes);

        expect(todos.isDisposed, isTrue);
        expect(() => todos.todos, throwsStateError);
        expect(todos.initialisationCubit, isClosed);
      });

      test(
        'is idempotent.',
        () async {
          await expectLater(todos.dispose(), completes);
          await expectLater(todos.dispose(), completes);
        },
      );
    });
  });
}
