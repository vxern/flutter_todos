import 'package:sprint/sprint.dart';

mixin Loggable {
  abstract final Sprint log;
}

mixin Initialisable {
  Future<void> initialise();
}

mixin Loadable<T> {
  Future<T> load();
}

mixin Disposable {
  abstract bool isDisposed;

  Future<void> dispose();
}
