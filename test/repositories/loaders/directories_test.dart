import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import 'package:flutter_todos/cubits.dart';
import 'package:flutter_todos/repositories/application.dart';
import 'package:flutter_todos/repositories/loaders/directories.dart';

class TestDirectoriesLoader extends DirectoriesLoader {
  @override
  Future<Directory> getDocumentsDirectory() async => directory;
}

class FaultyTestDirectoriesLoader extends DirectoriesLoader {
  @override
  Future<Directory> getDocumentsDirectory() async {
    throw MissingPlatformDirectoryException('');
  }
}

final directory = Directory('/');

void main() {
  group('DirectoryLoader', () {
    group('load()', () {
      late DirectoriesLoader loader;

      tearDown(() async => loader.dispose());

      test('loads the directories.', () async {
        loader = TestDirectoriesLoader();

        expect(loader.load(), completes);
      });

      test(
        'throws a [StateError] when [DirectoriesLoader] is disposed.',
        () async {
          loader = TestDirectoriesLoader();

          await expectLater(loader.dispose(), completes);
          await expectLater(loader.load, throwsStateError);
        },
      );

      test(
        'throws a [DirectoriesLoadException] on failure to load.',
        () {
          loader = FaultyTestDirectoriesLoader();

          expect(loader.load, throwsA(isA<DirectoriesLoadException>()));
        },
      );

      test('updates the bloc state when loading successfully.', () async {
        final loader = TestDirectoriesLoader();

        unawaited(
          expectLater(
            loader.initialisationCubit.stream,
            emitsInOrder([
              isA<InitialisingState>(),
              isA<InitialisedState<Directories>>(),
            ]),
          ),
        );

        await expectLater(loader.load(), completes);
      });

      test('updates the bloc state when failing to load.', () async {
        final loader = FaultyTestDirectoriesLoader();

        unawaited(
          expectLater(
            loader.initialisationCubit.stream,
            emitsInOrder([
              isA<InitialisingState>(),
              isA<InitialisationFailedState>(),
            ]),
          ),
        );

        await expectLater(
          loader.load,
          throwsA(isA<DirectoriesLoadException>()),
        );
      });
    });

    group('dispose()', () {
      late DirectoriesLoader loader;

      setUp(() => loader = TestDirectoriesLoader());

      test('disposes of the repository.', () async {
        await expectLater(loader.dispose(), completes);

        expect(loader.isDisposed, isTrue);
        expect(loader.initialisationCubit.isClosed, isTrue);
      });

      test(
        'is idempotent.',
        () async {
          await expectLater(loader.dispose(), completes);
          await expectLater(loader.dispose(), completes);
        },
      );
    });
  });
}
