import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_todos/repositories/loaders/directories.dart';

sealed class DirectoriesEvent {
  const DirectoriesEvent();
}

final class DirectoriesNotLoaded extends DirectoriesEvent {
  const DirectoriesNotLoaded();
}

final class DirectoriesLoading extends DirectoriesEvent {
  const DirectoriesLoading();
}

final class DirectoriesLoaded extends DirectoriesEvent with EquatableMixin {
  final Directories directories;

  const DirectoriesLoaded({required this.directories});

  @override
  List<Object> get props => [directories];
}

final class DirectoriesLoadingFailed extends DirectoriesEvent {
  const DirectoriesLoadingFailed();
}

sealed class DirectoriesState {
  const DirectoriesState();
}

final class DirectoriesNotLoadedState extends DirectoriesState {
  const DirectoriesNotLoadedState();
}

final class DirectoriesLoadingState extends DirectoriesState {
  const DirectoriesLoadingState();
}

final class DirectoriesLoadedState extends DirectoriesState
    with EquatableMixin {
  final Directories directories;

  const DirectoriesLoadedState({required this.directories});

  @override
  List<Object> get props => [directories];
}

final class DirectoriesLoadingFailedState extends DirectoriesState {
  const DirectoriesLoadingFailedState();
}

class DirectoriesBloc extends Bloc<DirectoriesEvent, DirectoriesState> {
  DirectoriesBloc() : super(const DirectoriesNotLoadedState()) {
    on<DirectoriesLoading>(
      (event, emit) => emit(const DirectoriesLoadingState()),
    );
    on<DirectoriesLoaded>(
      (event, emit) =>
          emit(DirectoriesLoadedState(directories: event.directories)),
    );
    on<DirectoriesLoadingFailed>(
      (event, emit) => emit(const DirectoriesLoadingFailedState()),
    );
  }

  void declareLoading() => add(const DirectoriesLoading());

  void declareLoaded({required Directories directories}) =>
      add(DirectoriesLoaded(directories: directories));

  void declareFailed() => add(const DirectoriesLoadingFailed());
}
