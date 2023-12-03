import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realm/realm.dart';
import 'package:universal_io/io.dart';

import 'package:flutter_todos/cubits.dart';
import 'package:flutter_todos/repositories/authentication.dart';
import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/structs/account.dart';
import '../matchers.dart';

// ignore: avoid_implementing_value_types
class MockRealm extends Mock implements Realm {}

class MockAccount extends Mock implements Account {}

class TestAuthenticationRepository extends AuthenticationRepository {
  TestAuthenticationRepository({required super.database});

  @override
  Future<String> deriveHash({required String password}) async => password;
}

class FaultyTestAuthenticationRepository extends AuthenticationRepository {
  final Never Function() thrower;

  FaultyTestAuthenticationRepository({
    required super.database,
    required this.thrower,
  });

  @override
  Future<String> deriveHash({required String password}) async {
    thrower();
  }
}

class TestDatabaseRepository extends DatabaseRepository {
  TestDatabaseRepository({required super.directory}) : super.internal();

  @override
  Realm openRealm({required String path}) => MockRealm();
}

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
  // ignore: discarded_futures
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
      database = TestDatabaseRepository(directory: directory);

      await database.initialise();

      stubRealm(database.realm);
    });
    tearDown(
      () async => Future.wait([database.dispose(), authentication.dispose()]),
    );

    group('account', () {
      setUp(() {
        authentication = TestAuthenticationRepository(database: database);
      });

      test(
        'returns [Account] if authenticated.',
        () async {
          final account = MockAccount();
          stubAccount(account);
          stubFinder<Account>(database.realm, () => account);

          await expectLater(
            authentication.login(username: username, password: password),
            completes,
          );

          expect(() => authentication.account, returnsNormally);
        },
      );

      test(
        'throws [StateError] if not authenticated.',
        () {
          expect(() => authentication.account, throwsStateError);
        },
      );
    });

    group('isAuthenticated', () {
      setUp(() {
        authentication = TestAuthenticationRepository(database: database);
      });

      test('returns [true] if authenticated.', () async {
        final account = MockAccount();
        stubAccount(account);
        stubFinder<Account>(database.realm, () => account);

        await expectLater(
          authentication.login(username: username, password: password),
          completes,
        );

        expect(authentication.isAuthenticated, isTrue);
      });

      test('returns [false] if not authenticated.', () {
        expect(authentication.isAuthenticated, isFalse);
      });
    });

    group('isNotAuthenticated', () {
      setUp(() {
        authentication = TestAuthenticationRepository(database: database);
      });

      test('returns [true] if not authenticated.', () {
        expect(authentication.isNotAuthenticated, isTrue);
      });

      test('returns [false] if authenticated.', () async {
        final account = MockAccount();
        stubAccount(account);
        stubFinder<Account>(database.realm, () => account);

        await expectLater(
          authentication.login(username: username, password: password),
          completes,
        );

        expect(authentication.isNotAuthenticated, isFalse);
      });
    });

    group('login()', () {
      test('logs the user in.', () async {
        authentication = TestAuthenticationRepository(database: database);

        final account = MockAccount();
        stubAccount(account);
        stubFinder<Account>(database.realm, () => account);

        await expectLater(
          authentication.login(username: username, password: password),
          completes,
        );
      });

      test(
        'throws an [AlreadyLoggedInException] when already logged in.',
        () async {
          authentication = TestAuthenticationRepository(database: database);

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
          authentication = TestAuthenticationRepository(database: database);

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
          authentication = TestAuthenticationRepository(database: database);

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
        'throws a [ResourceException] upon failure to hash the password.',
        () async {
          authentication = FaultyTestAuthenticationRepository(
            database: database,
            thrower: () {
              throw StateError('');
            },
          );

          final account = MockAccount();
          stubAccount(account);
          stubFinder<Account>(database.realm, () => account);

          await expectLater(
            authentication.login(username: username, password: password),
            throwsResourceException,
          );
        },
      );

      test(
        'throws a [StateError] when [AuthenticationRepository] is disposed.',
        () async {
          authentication = TestAuthenticationRepository(database: database);

          await expectLater(authentication.dispose(), completes);

          expect(
            authentication.login(username: username, password: password),
            throwsStateError,
          );
        },
      );

      test('updates the initialisation state.', () async {
        authentication = TestAuthenticationRepository(database: database);

        unawaited(
          expectLater(
            authentication.initialisationCubit.stream,
            emitsInOrder([
              isA<InitialisingState>(),
              isA<InitialisationFailedState>(),
              isA<InitialisingState>(),
              isA<InitialisedState>(),
            ]),
          ),
        );

        stubFinder<Account>(database.realm, () => null);

        await expectLater(
          () async => authentication.login(
            username: username,
            password: password,
          ),
          throwsA(isA<AccountNotExistsException>()),
        );

        final account = MockAccount();
        stubAccount(account);
        stubFinder<Account>(database.realm, () => account);

        await expectLater(
          authentication.login(
            username: username,
            password: password,
          ),
          completes,
        );
      });
    });

    group('register()', () {
      test('registers the user.', () async {
        authentication = TestAuthenticationRepository(database: database);

        final account = MockAccount();
        stubAccount(account);
        stubFinder<Account>(database.realm, () => null);
        stubAdder<Account>(database.realm, account);
        stubWriter<Account>(database.realm, () => account);

        await expectLater(
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
        () async {
          authentication = TestAuthenticationRepository(database: database);

          final account = MockAccount();
          stubAccount(account);
          stubFinder<Account>(database.realm, () => account);
          stubAdder<Account>(database.realm, account);
          stubWriter<Account>(database.realm, () => account);

          await expectLater(
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
        () async {
          authentication = TestAuthenticationRepository(database: database);

          final account = MockAccount();
          stubAccount(account);
          stubFinder<Account>(database.realm, () => null);
          stubAdder<Account>(database.realm, account);
          stubWriter<Account>(database.realm, () {
            throw RealmException('');
          });

          await expectLater(
            authentication.register(
              username: username,
              nickname: null,
              password: password,
            ),
            throwsResourceException,
          );
        },
      );

      test(
        'throws a [ResourceException] upon failure to hash the password.',
        () async {
          authentication = FaultyTestAuthenticationRepository(
            database: database,
            thrower: () {
              throw StateError('');
            },
          );

          stubFinder<Account>(database.realm, () => null);

          await expectLater(
            authentication.register(
              username: username,
              nickname: null,
              password: password,
            ),
            throwsResourceException,
          );
        },
      );

      test(
        'throws a [StateError] when [AuthenticationRepository] is disposed.',
        () async {
          authentication = FaultyTestAuthenticationRepository(
            database: database,
            thrower: () {
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
            throwsStateError,
          );
        },
      );
    });

    group('logout()', () {
      test('logs the user out.', () async {
        authentication = TestAuthenticationRepository(database: database);

        final account = MockAccount();
        stubAccount(account);
        stubFinder<Account>(database.realm, () => account);

        await expectLater(
          authentication.login(username: username, password: password),
          completes,
        );
        await expectLater(authentication.logout(), completes);

        expect(() => authentication.account, throwsStateError);
        expect(
          authentication.initialisationCubit.state,
          isA<UninitialisedState>(),
        );
      });

      test('is idempotent.', () async {
        authentication = TestAuthenticationRepository(database: database);

        await expectLater(authentication.logout(), completes);
        await expectLater(authentication.logout(), completes);
      });
    });

    group('dispose()', () {
      test('disposes of the repository.', () async {
        authentication = TestAuthenticationRepository(database: database);

        final account = MockAccount();
        stubAccount(account);
        stubFinder<Account>(database.realm, () => account);

        await expectLater(
          authentication.login(username: username, password: password),
          completes,
        );
        await expectLater(authentication.dispose(), completes);

        expect(authentication.isDisposed, isTrue);
        expect(() => authentication.account, throwsStateError);
        expect(authentication.initialisationCubit, isClosed);
      });

      test(
        'is idempotent.',
        () async {
          authentication = TestAuthenticationRepository(database: database);

          await expectLater(authentication.dispose(), completes);
          await expectLater(authentication.dispose(), completes);
        },
      );
    });
  });
}
