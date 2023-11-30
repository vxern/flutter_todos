import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todos/repositories/repository.dart';

import '../matchers.dart';

class TestRepository extends Repository {
  TestRepository() : super(name: 'TestRepository');
}

class MultipleInitialiseTestRepository extends Repository {
  MultipleInitialiseTestRepository()
      : super(
          name: 'TestRepository',
          allowMultipleInitialise: true,
        );
}

void main() {
  group('Repository', () {
    group('initialise()', () {
      test('initialises the repository.', () async {
        final test = TestRepository();

        expect(test.initialise(), completes);
      });

      test('throws a [StateError] when the repository is disposed.', () async {
        final test = TestRepository();

        await expectLater(test.dispose(), completes);
        await expectLater(test.initialise(), throwsStateError);
      });

      test('throws a [StateError] when already initialised.', () async {
        final test = TestRepository();

        test.initialisationCubit.declareInitialised();
        await expectLater(test.initialise(), throwsStateError);
      });

      test(
        'does not throw a [StateError] with [allowMultipleInitialise] when'
        'already initialised.',
        () async {
          final test = MultipleInitialiseTestRepository();

          await expectLater(test.initialise(), completes);
          await expectLater(test.initialise(), completes);
        },
      );
    });

    group('dispose()', () {
      test('disposes of the repository.', () async {
        final test = TestRepository();

        await expectLater(test.dispose(), completes);

        expect(test.isDisposed, isTrue);
        expect(test.initialisationCubit, isClosed);
      });

      test(
        'is idempotent.',
        () async {
          final test = TestRepository();

          await expectLater(test.dispose(), completes);
          await expectLater(test.dispose(), completes);
        },
      );
    });
  });
}
