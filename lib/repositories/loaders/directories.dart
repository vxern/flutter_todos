import 'package:equatable/equatable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import 'package:flutter_todos/repositories/application.dart';
import 'package:flutter_todos/repositories/loaders/loader.dart';

class Directories extends Equatable {
  final Directory documents;

  const Directories({required this.documents});

  @override
  List<Object> get props => [documents.path];
}

class DirectoriesLoader extends ApplicationLoader<Directories> {
  /// ! Throws [MissingPlatformDirectoryException] if unable to get directory.
  Future<Directory> getDocumentsDirectory() async =>
      getApplicationDocumentsDirectory();

  /// ! Throws:
  /// - ! [DirectoriesLoadException] upon failing to load directories.
  /// - ! (propagated) [StateError] if the loader is disposed.
  @override
  Future<void> load() async {
    verifyNotDisposed(message: 'Attempted to load directories while disposed.');

    initialisationCubit.declareInitialising();
    log.info('Loading directories...');

    final Directory documents;
    try {
      documents = await getDocumentsDirectory();
    } on MissingPlatformDirectoryException catch (exception) {
      initialisationCubit.declareFailed();
      log
        ..severe('Unable to get documents directory. Missing permissions?')
        ..severe(exception);
      throw const DirectoriesLoadException();
    }

    initialisationCubit.declareInitialised(
      value: Directories(documents: documents),
    );
    log.success('Directories loaded.');
  }
}
