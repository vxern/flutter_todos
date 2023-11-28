import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todos/cubits.dart';

class MockInitialisationCubit extends MockCubit<InitialisationState>
    implements InitialisationCubit {}

void main() {
  test(
    'InitialisationCubit state stream functions correctly.',
    () {
      final cubit = MockInitialisationCubit();

      whenListen(
        cubit,
        Stream.fromIterable(
          [
            const InitialisingState(),
            const InitialisationFailedState(),
            const InitialisingState(),
            const InitialisedState(),
          ],
        ),
      );

      unawaited(
        expectLater(
          cubit.stream,
          emitsInOrder([
            const InitialisingState(),
            const InitialisationFailedState(),
            const InitialisingState(),
            const InitialisedState(),
          ]),
        ),
      );
    },
  );

  group('InitialisationCubit', () {
    blocTest(
      'has UninitialisedState as the default state.',
      build: InitialisationCubit.new,
      verify: (cubit) => expect(cubit.state, isA<UninitialisedState>()),
    );

    blocTest(
      'emits [] when nothing is added.',
      build: InitialisationCubit.new,
      expect: () => [],
    );

    blocTest(
      'emits [InitialisingState] when [declareInitialising()] is called.',
      build: InitialisationCubit.new,
      act: (cubit) => cubit.declareInitialising(),
      expect: () => [const InitialisingState()],
    );

    blocTest(
      'emits [InitialisedState] when [declareInitialised()] is called.',
      build: InitialisationCubit.new,
      act: (cubit) => cubit.declareInitialised(),
      expect: () => [const InitialisedState()],
    );

    blocTest(
      'emits [InitialisationFailedState] when [declareFailed()] is called.',
      build: InitialisationCubit.new,
      act: (cubit) => cubit.declareFailed(),
      expect: () => [const InitialisationFailedState()],
    );
  });
}
