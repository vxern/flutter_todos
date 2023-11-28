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

final class InitialisedState extends InitialisationState {
  const InitialisedState();
}

final class InitialisationFailedState extends InitialisationState {
  const InitialisationFailedState();
}

class InitialisationCubit extends Cubit<InitialisationState> {
  bool get isInitialised =>
      state is InitialisingState || state is InitialisedState;

  InitialisationCubit() : super(const UninitialisedState());

  void declareInitialising() => emit(const InitialisingState());

  void declareInitialised() => emit(const InitialisedState());

  void declareFailed() => emit(const InitialisationFailedState());
}
