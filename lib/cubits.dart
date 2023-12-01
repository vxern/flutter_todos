import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class InitialisationState {
  const InitialisationState();
}

final class UninitialisedState extends InitialisationState {
  const UninitialisedState();
}

final class InitialisingState extends InitialisationState {
  const InitialisingState();
}

final class InitialisedState<T> extends InitialisationState {
  final T value;

  const InitialisedState({required this.value});
}

final class InitialisationFailedState extends InitialisationState {
  const InitialisationFailedState();
}

class InitialisationCubit<T> extends Cubit<InitialisationState> {
  bool get isInitialised =>
      state is InitialisingState || state is InitialisedState;

  InitialisationCubit() : super(const UninitialisedState());

  void declareUninitialised() => emit(const UninitialisedState());

  void declareInitialising() => emit(const InitialisingState());

  void declareInitialised({required T value}) =>
      emit(InitialisedState<T>(value: value));

  void declareFailed() => emit(const InitialisationFailedState());
}

class InitialisationException implements Exception {
  const InitialisationException();
}
