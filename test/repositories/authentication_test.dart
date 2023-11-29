import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todos/cubits.dart';
import 'package:flutter_todos/repositories/authentication.dart';
import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/structs/account.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realm/realm.dart';
import 'package:universal_io/io.dart';

import '../matchers.dart';

class MockRealm extends Mock implements Realm {}

class MockAccount extends Mock implements Account {}

void stubRealm(Realm realm) {
  when(realm.close).thenAnswer((_) {});
}

void stubAccount(Account account) {
  when(() => account.username).thenReturn(username);
  when(() => account.passwordHash).thenReturn(password);
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

void stubWriter<T extends RealmObject>(Realm realm, T Function() valueBuilder) {
  when(() => realm.writeAsync<T>(any(), any())).thenAnswer(
    (invocation) async => valueBuilder(),
  );
}

final directory = Directory('');
const username = 'username';
const password = 'password';

void main() {
  group('AuthenticationRepository', () {
    late DatabaseRepository database;
    late AuthenticationRepository authentication;

    setUp(() async {
      database = DatabaseRepository(
        directory: directory,
        openRealmDebug: ({required path}) => MockRealm(),
      );

      await database.initialise();

      stubRealm(database.realm);
    });
    tearDown(
      () async => Future.wait([database.dispose(), authentication.dispose()]),
    );

    group('login()', () {
      test('logs the user in.', () {
        authentication = AuthenticationRepository(
          database: database,
          deriveHashDebug: ({required password}) async => password,
        );

        final account = MockAccount();
        stubAccount(account);
        stubFinder<Account>(database.realm, () => account);

        expect(
          authentication.login(username: username, password: password),
          completes,
        );
      });

      test(
        'throws an [AlreadyLoggedInException] when already logged in.',
        () async {
          authentication = AuthenticationRepository(
            database: database,
            deriveHashDebug: ({required password}) async => password,
          );

          final account = MockAccount();
          stubAccount(account);
          stubFinder<Account>(database.realm, () => account);

          await expectLater(
            authentication.login(username: username, password: password),
            completes,
          );
          await expectLater(
            () async => authentication.login(
              username: username,
              password: password,
            ),
            throwsA(isA<AlreadyLoggedInException>()),
          );
        },
      );

      test(
        'throws an [AccountNotExistsException] if no account exists with the '
        'given username.',
        () {
          authentication = AuthenticationRepository(
            database: database,
            deriveHashDebug: ({required password}) async => password,
          );

          stubFinder<Account>(database.realm, () => null);

          expect(
            () async => authentication.login(
              username: username,
              password: password,
            ),
            throwsA(isA<AccountNotExistsException>()),
          );
        },
      );

      test(
        'throws a [WrongPasswordException] if the passwords do not match.',
        () {
          authentication = AuthenticationRepository(
            database: database,
            deriveHashDebug: ({required password}) async => password,
          );

          final account = MockAccount();
          stubAccount(account);
          stubFinder<Account>(database.realm, () => account);

          expect(
            () async => authentication.login(
              username: username,
              password: 'invalid_password',
            ),
            throwsA(isA<WrongPasswordException>()),
          );
        },
      );

      test(
        'throws a [StateError] when [AuthenticationRepository] is disposed.',
        () async {
          authentication = AuthenticationRepository(
            database: database,
            deriveHashDebug: ({required password}) async {
              throw StateError('');
            },
          );

          await expectLater(authentication.dispose(), completes);

          expect(
            authentication.login(username: username, password: password),
            throwsA(isA<StateError>()),
          );
        },
      );

      test('throws a [StateError] upon failure to hash the password.', () {
        authentication = AuthenticationRepository(
          database: database,
          deriveHashDebug: ({required password}) async {
            throw StateError('');
          },
        );

        final account = MockAccount();
        stubAccount(account);
        stubFinder<Account>(database.realm, () => account);

        expect(
          authentication.login(username: username, password: password),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('register()', () {
      test('registers the user.', () {
        authentication = AuthenticationRepository(
          database: database,
          deriveHashDebug: ({required password}) async => password,
        );

        final account = MockAccount();
        throwOnMissingStub(account);
        stubAccount(account);
        stubFinder<Account>(database.realm, () => null);
        stubAdder<Account>(database.realm, account);
        stubWriter<Account>(database.realm, () => account);

        expect(
          authentication.register(
            username: username,
            nickname: null,
            password: password,
          ),
          completion(account),
        );
      });

      test(
        'throws an [AccountAlreadyExistsException] when there already is an '
        'account with a given username.',
        () {
          authentication = AuthenticationRepository(
            database: database,
            deriveHashDebug: ({required password}) async => password,
          );

          final account = MockAccount();
          stubAccount(account);
          throwOnMissingStub(database.realm as MockRealm);
          stubFinder<Account>(database.realm, () => account);
          stubAdder<Account>(database.realm, account);
          stubWriter<Account>(database.realm, () => account);

          expect(
            authentication.register(
              username: username,
              nickname: null,
              password: password,
            ),
            throwsA(isA<AccountAlreadyExistsException>()),
          );
        },
      );

      test(
        'throws a [FailedToRegisterException] when unable to write the changes '
        'to the database.',
        () {
          authentication = AuthenticationRepository(
            database: database,
            deriveHashDebug: ({required password}) async => password,
          );

          final account = MockAccount();
          stubAccount(account);
          throwOnMissingStub(database.realm as MockRealm);
          stubFinder<Account>(database.realm, () => null);
          stubAdder<Account>(database.realm, account);
          stubWriter<Account>(database.realm, () {
            throw RealmException('');
          });

          expect(
            authentication.register(
              username: username,
              nickname: null,
              password: password,
            ),
            throwsA(isA<FailedToRegisterException>()),
          );
        },
      );

      test(
        'throws a [StateError] when [AuthenticationRepository] is disposed.',
        () async {
          authentication = AuthenticationRepository(
            database: database,
            deriveHashDebug: ({required password}) async {
              throw StateError('');
            },
          );

          await expectLater(authentication.dispose(), completes);

          expect(
            authentication.register(
              username: username,
              nickname: null,
              password: password,
            ),
            throwsA(isA<StateError>()),
          );
        },
      );

      test('throws a [StateError] upon failure to hash the password.', () {
        authentication = AuthenticationRepository(
          database: database,
          deriveHashDebug: ({required password}) async {
            throw StateError('');
          },
        );

        stubFinder<Account>(database.realm, () => null);

        expect(
          authentication.register(
            username: username,
            nickname: null,
            password: password,
          ),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('dispose()', () {
      test('disposes of the repository.', () async {
        await expectLater(authentication.dispose(), completes);

        expect(authentication.isDisposed, isTrue);
        expect(authentication.initialisationCubit, isClosed);
      });

      test(
        'is idempotent.',
        () async {
          await expectLater(authentication.dispose(), completes);
          await expectLater(authentication.dispose(), completes);
        },
      );
    });
  });
}
