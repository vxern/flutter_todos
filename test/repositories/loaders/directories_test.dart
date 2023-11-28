import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todos/repositories/application.dart';
import 'package:flutter_todos/repositories/loaders/directories.dart';

import 'package:flutter_todos/repositories/loaders/directories_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

final directory = Directory('/');

Future<Directory> stubDirectoryRetrievalSuccess() async => directory;

Future<Directory> stubDirectoryRetrievalFailure() async {
  throw MissingPlatformDirectoryException('');
}

void main() {
  group('DirectoryLoader', () {
    group('load()', () {
      late DirectoriesLoader loader;

      tearDown(() async => loader.dispose());

      test('loads the directories.', () async {
        loader = DirectoriesLoader(
          bloc: DirectoriesBloc(),
          getApplicationDocumentsDirectory: stubDirectoryRetrievalSuccess,
        );

        expect(loader.load(), completion(Directories(documents: directory)));
      });

      test(
        'throws a [StateError] when [DirectoriesLoader] is disposed.',
        () async {
          loader = DirectoriesLoader(
            bloc: DirectoriesBloc(),
            getApplicationDocumentsDirectory: stubDirectoryRetrievalSuccess,
          );

          await expectLater(loader.dispose(), completes);
          await expectLater(loader.load, throwsA(isA<StateError>()));
        },
      );

      test(
        'throws a [DirectoriesLoadException] on failure to load.',
        () {
          loader = DirectoriesLoader(
            bloc: DirectoriesBloc(),
            getApplicationDocumentsDirectory: stubDirectoryRetrievalFailure,
          );

          expect(
            loader.load,
            throwsA(isA<DirectoriesLoadException>()),
          );
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

        loader = DirectoriesLoader(
          bloc: bloc,
          getApplicationDocumentsDirectory: stubDirectoryRetrievalFailure,
        );

        await expectLater(
          loader.load,
          throwsA(isA<DirectoriesLoadException>()),
        );

        loader = DirectoriesLoader(
          bloc: bloc,
          getApplicationDocumentsDirectory: stubDirectoryRetrievalSuccess,
        );

        await expectLater(loader.load(), completes);
      });
    });

    group('dispose()', () {
      late DirectoriesLoader loader;

      setUp(
        () => loader = DirectoriesLoader(
          bloc: DirectoriesBloc(),
          getApplicationDocumentsDirectory: stubDirectoryRetrievalSuccess,
        ),
      );

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
