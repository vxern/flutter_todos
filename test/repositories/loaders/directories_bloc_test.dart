import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todos/repositories/loaders/directories.dart';
import 'package:flutter_todos/repositories/loaders/directories_bloc.dart';
import 'package:universal_io/io.dart';

class MockDirectoriesBloc extends MockBloc<DirectoriesEvent, DirectoriesState>
    implements DirectoriesBloc {}

final directories = Directories(documents: Directory('/'));

void main() {
  test(
    'DirectoriesBloc state stream functions correctly.',
    () {
      final bloc = MockDirectoriesBloc();

      whenListen(
        bloc,
        Stream.fromIterable(
          [
            const DirectoriesLoadingState(),
            const DirectoriesLoadingFailedState(),
            const DirectoriesLoadingState(),
            DirectoriesLoadedState(directories: directories),
          ],
        ),
      );

      expect(
        bloc.stream,
        emitsInOrder([
          const DirectoriesLoadingState(),
          const DirectoriesLoadingFailedState(),
          const DirectoriesLoadingState(),
          DirectoriesLoadedState(directories: directories),
        ]),
      );
    },
  );

  group(
    'DirectoriesBloc',
    () {
      blocTest(
        'has DirectoriesInitialState as the default state.',
        build: DirectoriesBloc.new,
        verify: (bloc) => expect(bloc.state, isA<DirectoriesNotLoadedState>()),
      );

      blocTest(
        'emits [] when nothing is added.',
        build: DirectoriesBloc.new,
        expect: () => [],
      );

      blocTest(
        'emits [DirectoriesLoadingState] when [declareLoading()] is called.',
        build: DirectoriesBloc.new,
        act: (bloc) => bloc.declareLoading(),
        expect: () => [const DirectoriesLoadingState()],
      );

      blocTest(
        'emits [DirectoriesLoadedState] when [declareLoaded()] is called.',
        build: DirectoriesBloc.new,
        act: (bloc) => bloc.declareLoaded(directories: directories),
        expect: () => [DirectoriesLoadedState(directories: directories)],
      );

      blocTest(
        'emits [DirectoriesLoadFailureState] when [declareFailed()] is called.',
        build: DirectoriesBloc.new,
        act: (bloc) => bloc.declareFailed(),
        expect: () => [const DirectoriesLoadingFailedState()],
      );
    },
  );
}
