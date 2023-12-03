import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_todos/cubits.dart';
import 'package:sprint/sprint.dart';

import 'package:flutter_todos/utils.dart';

abstract class ApplicationLoader<T>
    with Initialisable<T>, Loggable, Disposable {
  @override
  final Sprint log;

  T get value {
    final state = initialisationCubit.state;
    if (state is! InitialisedState<T>) {
      throw StateError('Attempted to get loaded value before loading it.');
    }

    return state.value;
  }

  ApplicationLoader() : log = Sprint('${T}Loader');

  @override
  Future<void> initialise() async {
    throw UnsupportedError('Use [load()] instead.');
  }

  @override
  Future<void> uninitialise() async {
    throw UnsupportedError('Use [unload()] instead.');
  }

  Future<void> load();

  Future<void> unload() async {
    await super.uninitialise();
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    await super.close();
  }
}
