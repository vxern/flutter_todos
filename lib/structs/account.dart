import 'package:realm/realm.dart' hide Credentials;

part 'account.g.dart';

@RealmModel()
class _TodoRow {
  late String contents;
}

@RealmModel()
class _Todo {
  @PrimaryKey()
  late final Uuid id;
  late String title;
  late final List<_TodoRow> rows;
  late final DateTime lastUpdated;
}

@RealmModel()
class _Todos {
  late final List<_Todo> entries;
}

@RealmModel()
class _Profile {
  late String? nickname;
}

@RealmModel()
class _Account {
  @PrimaryKey()
  late final String username;
  late final String passwordHash;
  late final _Profile? profile;
  late final _Todos? todos;
}
