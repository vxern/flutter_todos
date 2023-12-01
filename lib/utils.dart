import 'package:sprint/sprint.dart';

import 'package:flutter_todos/cubits.dart';

mixin Loggable {
  abstract final Sprint log;
}

mixin Initialisable {
  final initialisationCubit = InitialisationCubit();

  Future<void> initialise();

  Future<void> uninitialise() async =>
      initialisationCubit.declareUninitialised();
}

mixin Loadable<T> {
  Future<T> load();
}

mixin Disposable {
  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  Future<void> dispose() async => _isDisposed = true;

  /// ! Throws a [StateError] if disposed.
  void verifyNotDisposed({required String message}) {
    if (_isDisposed) {
      throw StateError(message);
    }
  }
}
