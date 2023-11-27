import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import 'package:flutter_todos/repositories/app.dart';

class Directories {
  final Directory documents;

  const Directories({required this.documents});
}

sealed class DirectoryEvent {
  const DirectoryEvent();
}

final class DirectoriesLoading extends DirectoryEvent {
  const DirectoriesLoading();
}

final class DirectoriesLoaded extends DirectoryEvent {
  final Directories directories;

  const DirectoriesLoaded({required this.directories});
}

final class DirectoriesLoadFailure extends DirectoryEvent {
  const DirectoriesLoadFailure();
}

sealed class DirectoryState {
  const DirectoryState();
}

final class DirectoriesInitialState extends DirectoryState {
  const DirectoriesInitialState();
}

final class DirectoriesLoadingState extends DirectoryState {
  const DirectoriesLoadingState();
}

final class DirectoriesLoadedState extends DirectoryState {
  final Directories directories;

  const DirectoriesLoadedState({required this.directories});
}

final class DirectoriesLoadFailureState extends DirectoryState {
  const DirectoriesLoadFailureState();
}

class DirectoryBloc extends Bloc<DirectoryEvent, DirectoryState> {
  DirectoryBloc() : super(const DirectoriesInitialState()) {
    on<DirectoriesLoading>(
      (event, emit) => emit(const DirectoriesLoadingState()),
    );
    on<DirectoriesLoaded>(
      (event, emit) =>
          emit(DirectoriesLoadedState(directories: event.directories)),
    );
    on<DirectoriesLoadFailure>(
      (event, emit) => emit(const DirectoriesLoadFailureState()),
    );
  }
}

mixin DirectoryLoading on AppRepositoryBase {
  Future<void> loadDirectories() async {
    log.info('Loading directories...');

    final Directory documents;
    try {
      documents = await getApplicationDocumentsDirectory();
    } on MissingPlatformDirectoryException {
      directories.add(const DirectoriesLoadFailure());

      log.severe('Unable to get documents directory. Missing permissions?');

      return;
    }

    directories
        .add(DirectoriesLoaded(directories: Directories(documents: documents)));

    log.success('Directories loaded.');
  }
}
