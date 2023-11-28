import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_todos/cubits.dart';
import 'package:flutter_todos/exceptions.dart';
import 'package:flutter_todos/repositories/loaders/directories_bloc.dart';
import 'package:flutter_todos/utils.dart';
import 'package:sprint/sprint.dart';

import 'package:flutter_todos/repositories/loaders/directories.dart';

// ignore: one_member_abstracts
abstract class ApplicationResourceLoader<T, B extends Bloc>
    with Loadable<T>, Disposable {
  @override
  bool isDisposed = false;

  final Sprint log;

  final B bloc;

  ApplicationResourceLoader({required this.bloc}) : log = Sprint('${T}Loader');

  @override
  Future<void> dispose() async {
    isDisposed = true;
    await bloc.close();
  }
}

class ApplicationRepository with Initialisable {
  // * Visible for testing.
  final initialisationCubit = InitialisationCubit();

  // * Visible for testing.
  bool isDisposed = false;

  final DirectoriesLoader directoriesLoader;

  InitialisationState get initialisationState => initialisationCubit.state;

  ApplicationRepository({DirectoriesLoader? directoriesLoader})
      : directoriesLoader =
            directoriesLoader ?? DirectoriesLoader(bloc: DirectoriesBloc());

  // ! Throws an [InitialisationException] upon failing to initialise.
  @override
  Future<void> initialise() async {
    if (isDisposed) {
      throw StateError(
        'Attempted to initialise ApplicationRepository when disposed.',
      );
    }

    if (initialisationCubit.state is InitialisingState ||
        initialisationCubit.state is InitialisedState) {
      throw StateError(
        'Attempted to initialise ApplicationRepository when already '
        'initialised.',
      );
    }

    initialisationCubit.declareInitialising();

    try {
      await Future.wait([directoriesLoader.load()]);
    } on DirectoriesLoadException {
      initialisationCubit.declareFailed();

      throw const InitialisationException();
    }

    initialisationCubit.declareInitialised();
  }

  static RepositoryProvider<ApplicationRepository> getProvider({
    required Widget child,
  }) =>
      RepositoryProvider.value(
        value: ApplicationRepository()
          ..directoriesLoader.bloc.add(const DirectoriesLoading()),
        child: child,
      );

  Future<void> dispose() {
    isDisposed = true;

    return Future.wait([
      initialisationCubit.close(),
      directoriesLoader.dispose(),
    ]);
  }
}
