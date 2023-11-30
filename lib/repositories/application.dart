import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_todos/cubits.dart';
import 'package:flutter_todos/repositories/loaders/directories_bloc.dart';
import 'package:flutter_todos/repositories/repository.dart';
import 'package:flutter_todos/utils.dart';
import 'package:sprint/sprint.dart';

import 'package:flutter_todos/repositories/loaders/directories.dart';

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

class ApplicationRepository extends Repository {
  final DirectoriesLoader directories;

  ApplicationRepository({
    // * Visible for testing.
    DirectoriesLoader? directoriesLoader,
  })  : directories =
            directoriesLoader ?? DirectoriesLoader(bloc: DirectoriesBloc()),
        super(name: 'ApplicationRepository');

  /// ! Throws:
  /// - ! [InitialisationException] upon failing to initialise.
  /// - ! (propagated) [StateError] if the repository is disposed.
  /// - ! (propagated) [StateError] if the repository has already been
  ///   ! initialised.
  @override
  Future<void> initialise() async {
    await super.initialise();

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
    await directories.dispose();
  }
}

class _LoadException implements Exception {
  const _LoadException();
}

class DirectoriesLoadException extends _LoadException {
  const DirectoriesLoadException();
}
