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
