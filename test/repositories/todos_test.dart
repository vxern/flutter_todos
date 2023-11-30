import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todos/cubits.dart';
import 'package:flutter_todos/repositories/authentication.dart';
import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/repositories/todos.dart';
import 'package:flutter_todos/structs/account.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realm/realm.dart';
import 'package:universal_io/io.dart';

import '../matchers.dart';

class MockRealm extends Mock implements Realm {}

class MockAccount extends Mock implements Account {}

class MockTodos extends Mock implements Todos {}

class MockTodo extends Mock implements Todo {}

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
  when(() => realm.deleteMany<T>(objects)).thenReturn(responseBuilder());
}

void stubDeleter<T extends RealmObject>(
  Realm realm,
  T object,
  T Function() valueBuilder,
) {
  when(() => realm.delete<T>(object)).thenReturn(valueBuilder());
}

void stubWriter<T extends RealmObject>(Realm realm, T Function() valueBuilder) {
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
      database = DatabaseRepository(
        directory: directory,
        openRealmDebug: ({required path}) => MockRealm(),
      );

      await database.initialise();

      stubRealm(database.realm);

      authentication = AuthenticationRepository(
        database: database,
        deriveHashDebug: ({required password}) async => password,
      );

      final account = MockAccount();
      stubAccount(account);
      stubFinder<Account>(database.realm, () => account);

      await authentication.login(username: username, password: password);

      todos = TodoRepository(
        authentication: authentication,
        database: database,
      );
    });

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

        await expectLater(
          todos.initialise(),
          throwsA(isA<InitialisationException>()),
        );

        await authentication.login(username: username, password: password);

        await expectLater(todos.initialise(), completes);
      });
    });

    group('find()', () {
      setUp(() => todos.initialise());

      test('gets a todo by ID.', () async {
        expect(
          todos.find(id: Uuid.nil.toString()),
          equals(todos.todos.entries.first),
        );
      });

      test("throws a [ResourceException] when the todo doesn't exist.", () {
        expect(todos.find(id: '-1'), throwsStateError);
      });
    });

    group('addTodo()', () {
      setUp(() => todos.initialise());

      test('adds a todo.', () {
        final todo = MockTodo();
        stubTodo(todo);
        stubAdder<Todo>(database.realm, todo);
        stubWriter<Todo>(database.realm, () => todo);

        expect(todos.addTodo(), completion(todos.todos.entries[1]));
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
        todo = todos.todos.entries.first;
      });

      test('removes a todo.', () {
        stubBulkDeleter<TodoRow>(database.realm, todo.rows, () {});
        stubDeleter<Todo>(database.realm, todo, () => todo);

        expect(todos.removeTodo(todo: todo), completes);
      });

      test(
        'throws a [ResourceException] when failed to remove todo rows.',
        () {
          stubBulkDeleter<TodoRow>(database.realm, todo.rows, () {
            throw RealmException('');
          });

          expect(todos.removeTodo(todo: todo), throwsResourceException);
        },
      );

      test(
        'throws a [ResourceException] when failed to remove the todo.',
        () {
          stubBulkDeleter<TodoRow>(database.realm, todo.rows, () {});
          stubDeleter<Todo>(database.realm, todo, () {
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
        todo = todos.todos.entries.first;
      });

      test('adds a todo row.', () {
        expect(todos.addRow(todo: todo), completion(todo.rows[1]));
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
        row = todos.todos.entries.first.rows.first;
      });

      test('removes a todo row.', () {
        expect(todos.removeRow(row: row), completion(row));
      });

      test(
        'throws a [ResourceException] when failed to remove the todo row.',
        () {
          stubDeleter<TodoRow>(database.realm, row, () {
            throw RealmException('');
          });

          expect(todos.removeRow(row: row), throwsResourceException);
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
