import 'package:flutter_test/flutter_test.dart';

class HasState<T> extends Matcher {
  const HasState();

  @override
  Description describe(Description description) =>
      description.add("Has the state '$T'.");

  @override
  bool matches(dynamic item, _) => item.state is T;
}

HasState<T> hasState<T>() => HasState<T>();

class IsClosed extends Matcher {
  const IsClosed();

  @override
  Description describe(Description description) =>
      description.add('Is closed.');

  @override
  bool matches(dynamic item, _) => item.isClosed == true;
}

const isClosed = IsClosed();
