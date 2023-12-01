import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sprint/sprint.dart';

import 'package:flutter_todos/utils.dart';

abstract class ApplicationLoader<T, B extends Bloc>
    with Loadable<T>, Loggable, Disposable {
  @override
  final Sprint log;

  final B bloc;

  ApplicationLoader({required this.bloc}) : log = Sprint('${T}Loader');

  @override
  Future<void> dispose() async {
    await super.dispose();
    await bloc.close();
  }
}
