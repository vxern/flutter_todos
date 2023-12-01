import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_todos/cubits.dart';

import 'package:flutter_todos/repositories/repository.dart';

typedef WidgetBuilderWithInitialiser = Widget Function(
  BuildContext context,
  InitialisationCubit initialiser,
);

class InitialisationArbiter extends StatelessWidget {
  static final Map<Symbol, InitialisationArbiter> _instances = {};

  final _arbitrageCubit = InitialisationCubit<()>();

  final List<InitialisationCubit> initialisers;
  final VoidCallback initialise;

  final WidgetBuilder whenInitialising;
  final WidgetBuilderWithInitialiser whenFailed;
  final WidgetBuilder whenDone;

  final List<StreamSubscription<InitialisationState>> _subscriptions = [];

  late final InitialisationCubit failedInitialiser;

  factory InitialisationArbiter({
    required Symbol name,
    required List<InitialisationCubit> initialisers,
    required VoidCallback initialise,
    required WidgetBuilder whenInitialising,
    required WidgetBuilderWithInitialiser whenFailed,
    required WidgetBuilder whenDone,
  }) {
    if (_instances.containsKey(name)) {
      return _instances[name]!;
    }

    final instance = InitialisationArbiter._(
      initialisers: initialisers,
      initialise: initialise,
      whenInitialising: whenInitialising,
      whenFailed: whenFailed,
      whenDone: whenDone,
    );

    _instances[name] = instance;

    return instance;
  }

  InitialisationArbiter._({
    required this.initialisers,
    required this.initialise,
    required this.whenInitialising,
    required this.whenFailed,
    required this.whenDone,
  }) : assert(
          initialisers.isNotEmpty,
          'There must be at least one initialiser.',
        ) {
    final subscriptions = <StreamSubscription<InitialisationState>>[];
    for (final initialiser in initialisers) {
      late final StreamSubscription<InitialisationState> subscription;
      subscription = initialiser.stream.listen(
        (state) async =>
            _onInitialisationStateChanged(initialiser, subscription, state),
      );
      subscriptions.add(subscription);
    }

    initialise();
  }

  factory InitialisationArbiter.repository({
    required Symbol name,
    required List<Repository> repositories,
    required WidgetBuilder whenInitialising,
    required WidgetBuilderWithInitialiser whenFailed,
    required WidgetBuilder whenDone,
  }) =>
      InitialisationArbiter(
        name: name,
        initialisers: repositories
            .map((repository) => repository.initialisationCubit)
            .toList(),
        initialise: () async {
          for (final repository in repositories) {
            if (repository.initialisationCubit.isInitialised) {
              continue;
            }

            await repository.initialise();
          }
        },
        whenInitialising: whenInitialising,
        whenFailed: whenFailed,
        whenDone: whenDone,
      );

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<InitialisationCubit, InitialisationState>(
        bloc: _arbitrageCubit,
        builder: (context, state) {
          switch (state) {
            case UninitialisedState() || InitialisingState():
              return whenInitialising(context);
            case InitialisedState():
              return whenDone(context);
            case InitialisationFailedState():
              return whenFailed(context, failedInitialiser);
          }
        },
      );

  Future<void> _onInitialisationStateChanged(
    InitialisationCubit initialiser,
    StreamSubscription<InitialisationState> subscription,
    InitialisationState state,
  ) async {
    switch (state) {
      case UninitialisedState() || InitialisingState():
        return;
      case InitialisedState():
        unawaited(_onInitialised(subscription));
      case InitialisationFailedState():
        unawaited(_onInitialisationFailure(initialiser));
    }
  }

  Future<void> _onInitialised(
    StreamSubscription<InitialisationState> subscription,
  ) async {
    _subscriptions.remove(subscription);
    await subscription.cancel();

    await _tryFinalise();
  }

  Future<void> _onInitialisationFailure(InitialisationCubit initialiser) async {
    _arbitrageCubit.declareFailed();

    final futures = <Future<void>>[];
    for (final subscription in _subscriptions) {
      _subscriptions.remove(subscription);
      futures.add(subscription.cancel());
    }
    await Future.wait(futures);

    failedInitialiser = initialiser;
  }

  Future<void> _tryFinalise() async {
    if (_subscriptions.isNotEmpty) {
      return;
    }

    _arbitrageCubit.declareInitialised(value: const ());
  }
}
