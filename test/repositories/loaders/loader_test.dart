import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_todos/repositories/loaders/loader.dart';
import '../../matchers.dart';

class TestApplicationLoader extends ApplicationLoader<()> {
  @override
  Future<void> load() async => initialisationCubit
    ..declareInitialising()
    ..declareInitialised(value: const ());
}

void main() {
  group('ApplicationLoader', () {
    late ApplicationLoader loader;

    setUp(() => loader = TestApplicationLoader());
    tearDown(() async => loader.dispose());

    group('value', () {
      test('returns [T] if loaded.', () async {
        await expectLater(loader.load(), completes);
        await expectLater(loader.value, equals(const ()));
      });

      test('throws [StateError] if not loaded.', () async {
        await expectLater(() => loader.value, throwsStateError);
      });
    });

    group('initialise()', () {
      test('throws an [UnsupportedError].', () {
        expect(loader.initialise, throwsUnsupportedError);
      });
    });

    group('uninitialise()', () {
      test('throws an [UnsupportedError].', () {
        expect(loader.uninitialise, throwsUnsupportedError);
      });
    });

    group('unload()', () {
      test(
        'changes the initialisation state to [UninitialisedState].',
        () async {
          await expectLater(loader.load(), completes);
          expect(loader.initialisationCubit.isInitialised, isTrue);

          await expectLater(loader.unload(), completes);
          expect(loader.initialisationCubit.isInitialised, isFalse);
        },
      );

      test('is idempotent.', () async {
        await expectLater(loader.unload(), completes);
        await expectLater(loader.unload(), completes);
      });
    });

    group('dispose()', () {
      test('disposes of the loader.', () async {
        await expectLater(loader.dispose(), completes);

        expect(loader.initialisationCubit, isClosed);
        expect(loader.isDisposed, isTrue);
      });

      test('is idempotent.', () async {
        await expectLater(loader.dispose(), completes);
        await expectLater(loader.dispose(), completes);
      });
    });
  });
}
