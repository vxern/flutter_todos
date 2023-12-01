import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todos/repositories/application.dart';
import 'package:flutter_todos/repositories/loaders/directories.dart';

import 'package:flutter_todos/repositories/loaders/directories_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

class TestDirectoriesLoader extends DirectoriesLoader {
  TestDirectoriesLoader({required super.bloc});

  @override
  Future<Directory> getDocumentsDirectory() async => directory;
}

class FaultyTestDirectoriesLoader extends DirectoriesLoader {
  FaultyTestDirectoriesLoader({required super.bloc});

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
        loader = TestDirectoriesLoader(bloc: DirectoriesBloc());

        expect(loader.load(), completion(Directories(documents: directory)));
      });

      test(
        'throws a [StateError] when [DirectoriesLoader] is disposed.',
        () async {
          loader = DirectoriesLoader(bloc: DirectoriesBloc());

          await expectLater(loader.dispose(), completes);
          await expectLater(loader.load, throwsStateError);
        },
      );

      test(
        'throws a [DirectoriesLoadException] on failure to load.',
        () {
          loader = FaultyTestDirectoriesLoader(bloc: DirectoriesBloc());

          expect(loader.load, throwsA(isA<DirectoriesLoadException>()));
        },
      );

      test('updates the bloc state.', () async {
        final bloc = DirectoriesBloc();

        unawaited(
          expectLater(
            bloc.stream,
            emitsInOrder([
              isA<DirectoriesLoadingState>(),
              isA<DirectoriesLoadingFailedState>(),
              isA<DirectoriesLoadingState>(),
              isA<DirectoriesLoadedState>(),
            ]),
          ),
        );

        loader = FaultyTestDirectoriesLoader(bloc: bloc);

        await expectLater(
          loader.load,
          throwsA(isA<DirectoriesLoadException>()),
        );

        loader = TestDirectoriesLoader(bloc: bloc);

        await expectLater(loader.load(), completes);
      });
    });

    group('dispose()', () {
      late DirectoriesLoader loader;

      setUp(() => loader = TestDirectoriesLoader(bloc: DirectoriesBloc()));

      test('disposes of the repository.', () async {
        await expectLater(loader.dispose(), completes);

        expect(loader.isDisposed, isTrue);
        expect(loader.bloc.isClosed, isTrue);
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
