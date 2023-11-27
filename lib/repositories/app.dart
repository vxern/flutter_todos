import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_todos/repositories/app/directories.dart';
import 'package:sprint/sprint.dart';

class AppRepositoryBase {
  final Sprint log;

  final DirectoryBloc directories;

  AppRepositoryBase({required this.directories})
      : log = Sprint('Bootstrapping');
}

class AppRepository extends AppRepositoryBase with DirectoryLoading {
  AppRepository._({required super.directories});

  factory AppRepository.create() {
    final directories = DirectoryBloc();

    return AppRepository._(directories: directories);
  }

  Future<void> load() async {
    await Future.wait([
      loadDirectories(),
    ]);
  }

  static RepositoryProvider<AppRepository> getProvider({
    required Widget child,
  }) =>
      RepositoryProvider.value(
        value: AppRepository.create()
          ..directories.add(const DirectoriesLoading()),
        child: child,
      );

  Future<void> dispose() async {
    await directories.close();
  }
}
