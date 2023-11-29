import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todos/cubits.dart';
import 'package:flutter_todos/repositories/database.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realm/realm.dart';
import 'package:universal_io/io.dart';

import '../matchers.dart';

class MockRealm extends Mock implements Realm {}

void stub(Realm realm) {
  when(realm.close).thenAnswer((_) {});
}

final directory = Directory('');

void main() {
  group('DatabaseRepository', () {
    group('realm', () {
      late DatabaseRepository database;

      setUp(() {
        database = DatabaseRepository(
          directory: directory,
          openRealmDebug: ({required path}) => MockRealm(),
        );
      });
      tearDown(() async {
        await database.dispose();
      });

      test(
        'returns [Realm] if [DatabaseRepository] is initialised.',
        () async {
          await database.initialise();

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
        database = DatabaseRepository(
          directory: directory,
          openRealmDebug: ({required path}) => MockRealm(),
        );

        expect(database.initialise(), completes);
      });

      test('throws a [StateError] when already initialised.', () async {
        database = DatabaseRepository(
          directory: directory,
          openRealmDebug: ({required path}) => MockRealm(),
        );

        await expectLater(database.initialise(), completes);
        await expectLater(database.initialise, throwsA(isA<StateError>()));
      });

      test(
        'throws a [StateError] when [DatabaseRepository] is disposed.',
        () async {
          database = DatabaseRepository(
            directory: directory,
            openRealmDebug: ({required path}) => MockRealm(),
          );

          await expectLater(database.initialise(), completes);

          stub(database.realm);

          await expectLater(database.dispose(), completes);
          await expectLater(database.initialise, throwsA(isA<StateError>()));
        },
      );

      group(
        'throws an [InitialisationException] on failure to initialise',
        () {
          test('due to a [FileSystemException].', () async {
            database = DatabaseRepository(
              directory: directory,
              openRealmDebug: ({required path}) {
                throw const FileSystemException();
              },
            );

            expect(
              database.initialise,
              throwsA(isA<InitialisationException>()),
            );
          });

          test('due to a [RealmException].', () async {
            database = DatabaseRepository(
              directory: directory,
              openRealmDebug: ({required path}) {
                throw RealmException('');
              },
            );

            expect(
              database.initialise,
              throwsA(isA<InitialisationException>()),
            );
          });
        },
      );

      test(
        'does not throw when attempting to initialise again after failure.',
        () async {
          late RealmOpener openRealm;

          database = DatabaseRepository(
            directory: directory,
            openRealmDebug: ({required path}) => openRealm(path: path),
          );

          openRealm = ({required path}) {
            throw const FileSystemException();
          };

          await expectLater(
            database.initialise,
            throwsA(isA<InitialisationException>()),
          );

          openRealm = ({required path}) => MockRealm();

          await expectLater(database.initialise(), completes);
        },
      );

      test('updates the initialisation state.', () async {
        late RealmOpener openRealm;

        database = DatabaseRepository(
          directory: directory,
          openRealmDebug: ({required path}) => openRealm(path: path),
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

        openRealm = ({required path}) {
          throw const FileSystemException();
        };

        await expectLater(
          database.initialise,
          throwsA(isA<InitialisationException>()),
        );

        openRealm = ({required path}) => MockRealm();

        expect(database.initialise(), completes);
      });
    });

    group('dispose()', () {
      late DatabaseRepository database;

      setUp(
        () async {
          database = DatabaseRepository(
            directory: directory,
            openRealmDebug: ({required path}) => MockRealm(),
          );

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
