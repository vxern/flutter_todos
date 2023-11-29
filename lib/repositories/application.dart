import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_todos/cubits.dart';
import 'package:flutter_todos/repositories/loaders/directories_bloc.dart';
import 'package:flutter_todos/utils.dart';
import 'package:sprint/sprint.dart';

import 'package:flutter_todos/repositories/loaders/directories.dart';

// ignore: one_member_abstracts
abstract class ApplicationResourceLoader<T, B extends Bloc>
    with Loadable<T>, Loggable, Disposable {
  @override
  final Sprint log;

  final B bloc;

  ApplicationResourceLoader({required this.bloc}) : log = Sprint('${T}Loader');

  @override
  Future<void> dispose() async {
    await super.dispose();
    await bloc.close();
  }
}

class _LoadException implements Exception {
  const _LoadException();
}

class DirectoriesLoadException extends _LoadException {
  const DirectoriesLoadException();
}

class ApplicationRepository with Initialisable, Disposable {
  // * Visible for testing.
  final initialisationCubit = InitialisationCubit();

  final DirectoriesLoader directories;

  ApplicationRepository({
    // * Visible for testing.
    DirectoriesLoader? directoriesLoader,
  }) : directories =
            directoriesLoader ?? DirectoriesLoader(bloc: DirectoriesBloc());

  /// ! Throws:
  /// - ! [InitialisationException] upon failing to initialise.
  /// - ! (propagated) [StateError] if the repository is disposed.
  /// - ! [StateError] if the repository has already been initialised.
  @override
  Future<void> initialise() async {
    verifyNotDisposed(
      message: 'Attempted to initialise application repository while disposed.',
    );

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

  @override
  Future<void> dispose() async {
    await super.dispose();
    await Future.wait([
      initialisationCubit.close(),
      directories.dispose(),
    ]);
  }
}
