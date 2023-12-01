import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:universal_io/io.dart';

import 'package:flutter_todos/cubits.dart';
import 'package:flutter_todos/repositories/application.dart';
import 'package:flutter_todos/repositories/loaders/directories.dart';
import '../matchers.dart';

class MockDirectoryLoader extends Mock implements DirectoriesLoader {}

final directories = Directories(documents: Directory('/'));
final directoriesLoader = DirectoriesLoader();

void stub(DirectoriesLoader directoriesLoader) {
  final initialisationCubit = InitialisationCubit<Directories>();
  when(() => directoriesLoader.initialisationCubit)
      .thenReturn(initialisationCubit);
  when(directoriesLoader.dispose).thenAnswer((_) async {});
}

void stubLoaderWithSuccess(DirectoriesLoader directoriesLoader) {
  when(directoriesLoader.load).thenAnswer((_) => Future.value(directories));
}

void stubLoaderWithFailure(DirectoriesLoader directoriesLoader) {
  when(directoriesLoader.load).thenThrow(const DirectoriesLoadException());
}

void main() {
  group('ApplicationRepository', () {
    group('initialise()', () {
      late ApplicationRepository application;

      setUp(
        () {
          final directoriesLoader = MockDirectoryLoader();
          application =
              ApplicationRepository(directoriesLoader: directoriesLoader);
          stub(directoriesLoader);
        },
      );
      tearDown(() async => application.dispose());

      test('initialises the repository.', () async {
        stubLoaderWithSuccess(application.directories);

        expect(application.initialise(), completes);
      });

      test('throws a [StateError] when already initialised.', () async {
        stubLoaderWithSuccess(application.directories);

        await expectLater(application.initialise(), completes);
        await expectLater(application.initialise, throwsStateError);
      });

      test(
        'throws a [StateError] when [ApplicationRepository] is disposed.',
        () async {
          stubLoaderWithSuccess(application.directories);

          await expectLater(application.dispose(), completes);
          await expectLater(application.initialise, throwsStateError);
        },
      );

      test(
        'throws an [InitialisationException] on failure to initialise.',
        () async {
          stubLoaderWithFailure(application.directories);

          expect(application.initialise, throwsInitialisationException);
        },
      );

      test(
        'does not throw when attempting to initialise again after failure.',
        () async {
          stubLoaderWithFailure(application.directories);

          await expectLater(
            application.initialise,
            throwsInitialisationException,
          );

          stubLoaderWithSuccess(application.directories);

          await expectLater(application.initialise(), completes);
        },
      );

      test('updates the initialisation state.', () async {
        unawaited(
          expectLater(
            application.initialisationCubit.stream,
            emitsInOrder([
              isA<InitialisingState>(),
              isA<InitialisationFailedState>(),
              isA<InitialisingState>(),
              isA<InitialisedState>(),
            ]),
          ),
        );

        stubLoaderWithFailure(application.directories);

        await expectLater(
          application.initialise,
          throwsInitialisationException,
        );

        stubLoaderWithSuccess(application.directories);

        await expectLater(application.initialise(), completes);
      });
    });

    group('dispose()', () {
      late ApplicationRepository application;

      setUp(
        () => application =
            ApplicationRepository(directoriesLoader: directoriesLoader),
      );

      test('disposes of the repository.', () async {
        await expectLater(application.dispose(), completes);

        expect(application.isDisposed, isTrue);
        expect(application.initialisationCubit, isClosed);
        expect(application.directories.isDisposed, isTrue);
      });

      test(
        'is idempotent.',
        () async {
          await expectLater(application.dispose(), completes);
          await expectLater(application.dispose(), completes);
        },
      );
    });
  });
}
