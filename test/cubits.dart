import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_todos/cubits.dart';

class MockInitialisationCubit<T> extends MockCubit<InitialisationState>
    implements InitialisationCubit<T> {}

void main() {
  test(
    'InitialisationCubit state stream functions correctly.',
    () {
      final cubit = MockInitialisationCubit<()>();

      whenListen(
        cubit,
        Stream.fromIterable(
          [
            const InitialisingState(),
            const InitialisationFailedState(),
            const InitialisingState(),
            const InitialisedState(value: ()),
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
            const InitialisedState(value: ()),
          ]),
        ),
      );
    },
  );

  group('InitialisationCubit', () {
    blocTest<InitialisationCubit, InitialisationState>(
      'has UninitialisedState as the default state.',
      build: InitialisationCubit.new,
      verify: (cubit) => expect(cubit.state, isA<UninitialisedState>()),
    );

    blocTest<InitialisationCubit, InitialisationState>(
      'emits [] when nothing is added.',
      build: InitialisationCubit.new,
      expect: () => const <()>[],
    );

    // Since [UninitialisedState] is the default state and unchanged states are
    // not emitted, we need to change the state away from and then back towards
    // [UninitialisedState].
    blocTest<InitialisationCubit, InitialisationState>(
      'emits [InitialisedState(), UninitialisedState()] when '
      '[declareInitialised(), declareUninitialised()] are called.',
      build: InitialisationCubit.new,
      act: (cubit) => cubit
        ..declareInitialising()
        ..declareUninitialised(),
      expect: () => [const InitialisingState(), const UninitialisedState()],
    );

    blocTest<InitialisationCubit, InitialisationState>(
      'emits [InitialisingState] when [declareInitialising()] is called.',
      build: InitialisationCubit.new,
      act: (cubit) => cubit.declareInitialising(),
      expect: () => [const InitialisingState()],
    );

    blocTest<InitialisationCubit, InitialisationState>(
      'emits [InitialisedState] when [declareInitialised()] is called.',
      build: InitialisationCubit.new,
      act: (cubit) => cubit.declareInitialised(value: ()),
      expect: () => [const InitialisedState(value: ())],
    );

    blocTest<InitialisationCubit, InitialisationState>(
      'emits [InitialisationFailedState] when [declareFailed()] is called.',
      build: InitialisationCubit.new,
      act: (cubit) => cubit.declareFailed(),
      expect: () => [const InitialisationFailedState()],
    );
  });
}
