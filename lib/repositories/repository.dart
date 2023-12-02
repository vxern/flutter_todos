import 'package:sprint/sprint.dart';

import 'package:flutter_todos/utils.dart';

class Repository with Loggable, Initialisable, Disposable {
  @override
  late final Sprint log;

  final String name;

  final bool allowMultipleInitialise;

  Repository({
    required this.name,
    this.allowMultipleInitialise = false,
  }) : log = Sprint(name);

  /// - ! (propagated) [StateError] if the repository is disposed.
  /// - ! [StateError] if the repository has already been initialised.
  @override
  Future<void> initialise() async {
    verifyNotDisposed(
      message: 'Attempted to initialise $name while disposed.',
    );

    if (initialisationCubit.isInitialised && !allowMultipleInitialise) {
      throw StateError(
        'Attempted to initialise $name when already initialised.',
      );
    }
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    await initialisationCubit.close();
  }
}

class ResourceException implements Exception {
  final String message;

  const ResourceException({required this.message});
}
