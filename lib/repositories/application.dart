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

class ApplicationRepository with Initialisable, Disposable {
  @override
  bool isDisposed = false;

  // * Visible for testing.
  final initialisationCubit = InitialisationCubit();

  final DirectoriesLoader directories;

  InitialisationState get initialisationState => initialisationCubit.state;

  ApplicationRepository({
    // * Visible for testing.
    DirectoriesLoader? directoriesLoader,
  }) : directories =
            directoriesLoader ?? DirectoriesLoader(bloc: DirectoriesBloc());

  // ! Throws an [InitialisationException] upon failing to initialise.
  @override
  Future<void> initialise() async {
    if (isDisposed) {
      throw StateError(
        'Attempted to initialise ApplicationRepository when disposed.',
      );
    }

    if (initialisationCubit.isInitialised) {
      throw StateError(
        'Attempted to initialise ApplicationRepository when already '
        'initialised.',
      );
    }

    initialisationCubit.declareInitialising();

    try {
      await Future.wait([directories.load()]);
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
          ..directories.bloc.add(const DirectoriesLoading()),
        child: child,
      );

  @override
  Future<void> dispose() {
    isDisposed = true;

    return Future.wait([
      initialisationCubit.close(),
      directories.dispose(),
    ]);
  }
}
