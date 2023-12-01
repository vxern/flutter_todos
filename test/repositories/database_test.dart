import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realm/realm.dart';
import 'package:universal_io/io.dart';

import 'package:flutter_todos/cubits.dart';
import 'package:flutter_todos/repositories/database.dart';
import '../matchers.dart';

class MockRealm extends Mock implements Realm {}

class TestDatabaseRepository extends DatabaseRepository {
  TestDatabaseRepository({required super.directory});

  @override
  Realm openRealm({required String path}) => MockRealm();
}

class FaultyTestDatabaseRepository extends DatabaseRepository {
  final Never Function() thrower;

  FaultyTestDatabaseRepository({
    required super.directory,
    required this.thrower,
  });

  @override
  Realm openRealm({required String path}) {
    thrower();
  }
}

class VariablyFaultyTestDatabaseRepository extends DatabaseRepository {
  final Realm Function() openRealm_;

  VariablyFaultyTestDatabaseRepository({
    required super.directory,
    required Realm Function() openRealm,
  }) : openRealm_ = openRealm;

  @override
  Realm openRealm({required String path}) => openRealm_();
}

void stub(Realm realm) {
  when(realm.close).thenAnswer((_) {});
}

final directory = Directory('');

void main() {
  group('DatabaseRepository', () {
    group('realm', () {
      late DatabaseRepository database;

      setUp(() {
        database = TestDatabaseRepository(directory: directory);
      });
      tearDown(() async {
        await database.dispose();
      });

      test(
        'returns [Realm] if [DatabaseRepository] is initialised.',
        () async {
          await expectLater(database.initialise(), completes);

          expect(() => database.realm, returnsNormally);
        },
      );

      test(
        'throws [StateError] if [DatabaseRepository] is not initialised.',
        () {
          expect(() => database.realm, throwsStateError);
        },
      );
    });

    group('initialise()', () {
      late DatabaseRepository database;

      tearDown(() async {
        // TODO(vxern): This is a hack, but it's okay.
        if (database.initialisationCubit.isInitialised) {
          stub(database.realm);
        }

        await database.dispose();
      });

      test('initialises the repository.', () async {
        database = TestDatabaseRepository(directory: directory);

        expect(database.initialise(), completes);
      });

      test('throws a [StateError] when already initialised.', () async {
        database = TestDatabaseRepository(directory: directory);

        await expectLater(database.initialise(), completes);
        await expectLater(database.initialise, throwsStateError);
      });

      test(
        'throws a [StateError] when [DatabaseRepository] is disposed.',
        () async {
          database = TestDatabaseRepository(directory: directory);

          await expectLater(database.initialise(), completes);

          stub(database.realm);

          await expectLater(database.dispose(), completes);
          await expectLater(database.initialise, throwsStateError);
        },
      );

      group(
        'throws an [InitialisationException] on failure to initialise',
        () {
          test('due to a [FileSystemException].', () async {
            database = FaultyTestDatabaseRepository(
              directory: directory,
              thrower: () {
                throw const FileSystemException();
              },
            );

            expect(database.initialise, throwsInitialisationException);
          });

          test('due to a [RealmException].', () async {
            database = FaultyTestDatabaseRepository(
              directory: directory,
              thrower: () {
                throw RealmException('');
              },
            );

            expect(database.initialise, throwsInitialisationException);
          });
        },
      );

      test(
        'does not throw when attempting to initialise again after failure.',
        () async {
          late Realm Function() openRealm;

          database = VariablyFaultyTestDatabaseRepository(
            directory: directory,
            openRealm: () => openRealm(),
          );

          openRealm = () {
            throw const FileSystemException();
          };

          await expectLater(database.initialise, throwsInitialisationException);

          openRealm = MockRealm.new;

          await expectLater(database.initialise(), completes);
        },
      );

      test('updates the initialisation state.', () async {
        late Realm Function() openRealm;

        database = VariablyFaultyTestDatabaseRepository(
          directory: directory,
          openRealm: () => openRealm(),
        );

        unawaited(
          expectLater(
            database.initialisationCubit.stream,
            emitsInOrder([
              isA<InitialisingState>(),
              isA<InitialisationFailedState>(),
              isA<InitialisingState>(),
              isA<InitialisedState>(),
            ]),
          ),
        );

        openRealm = () {
          throw const FileSystemException();
        };

        await expectLater(database.initialise, throwsInitialisationException);

        openRealm = MockRealm.new;

        expect(database.initialise(), completes);
      });
    });

    group('dispose()', () {
      late DatabaseRepository database;

      setUp(
        () async {
          database = TestDatabaseRepository(directory: directory);

          await database.initialise();

          stub(database.realm);
        },
      );

      test('disposes of the repository.', () async {
        await expectLater(database.dispose(), completes);

        expect(database.isDisposed, isTrue);
        expect(database.initialisationCubit, isClosed);
      });

      test(
        'is idempotent.',
        () async {
          await expectLater(database.dispose(), completes);
          await expectLater(database.dispose(), completes);
        },
      );
    });
  });
}
