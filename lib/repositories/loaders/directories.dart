import 'package:equatable/equatable.dart';
import 'package:flutter_todos/exceptions.dart';
import 'package:flutter_todos/repositories/loaders/directories_bloc.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:universal_io/io.dart';

import 'package:flutter_todos/repositories/application.dart';

class Directories extends Equatable {
  final Directory documents;

  const Directories({required this.documents});

  @override
  List<Object> get props => [documents.path];
}

typedef DirectoryFetcher = Future<Directory> Function();

class DirectoriesLoader
    extends ApplicationResourceLoader<Directories, DirectoriesBloc> {
  // * Visible for testing.
  final DirectoryFetcher getApplicationDocumentsDirectory;

  DirectoriesLoader({
    required super.bloc,
    DirectoryFetcher? getApplicationDocumentsDirectory,
  }) : getApplicationDocumentsDirectory = getApplicationDocumentsDirectory ??
            pathProvider.getApplicationDocumentsDirectory;

  /// ! Throws a [DirectoriesLoadException] upon failing to load directories.
  @override
  Future<Directories> load() async {
    if (isDisposed) {
      throw StateError(
        'Attempted to initialise DirectoriesLoader when disposed.',
      );
    }

    log.info('Loading directories...');

    bloc.declareLoading();

    final Directory documents;
    try {
      documents = await getApplicationDocumentsDirectory();
    } on pathProvider.MissingPlatformDirectoryException {
      bloc.declareFailed();

      log.severe('Unable to get documents directory. Missing permissions?');

      throw const DirectoriesLoadException();
    }

    bloc.declareLoaded(directories: Directories(documents: documents));

    log.success('Directories loaded.');

    return Directories(documents: documents);
  }
}
