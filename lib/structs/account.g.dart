// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

class TodoRow extends _TodoRow with RealmEntity, RealmObjectBase, RealmObject {
  TodoRow(
    String contents,
  ) {
    RealmObjectBase.set(this, 'contents', contents);
  }

  TodoRow._();

  @override
  String get contents =>
      RealmObjectBase.get<String>(this, 'contents') as String;
  @override
  set contents(String value) => RealmObjectBase.set(this, 'contents', value);

  @override
  Stream<RealmObjectChanges<TodoRow>> get changes =>
      RealmObjectBase.getChanges<TodoRow>(this);

  @override
  TodoRow freeze() => RealmObjectBase.freezeObject<TodoRow>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(TodoRow._);
    return const SchemaObject(ObjectType.realmObject, TodoRow, 'TodoRow', [
      SchemaProperty('contents', RealmPropertyType.string),
    ]);
  }
}

class Todo extends _Todo with RealmEntity, RealmObjectBase, RealmObject {
  Todo(
    Uuid id,
    String title,
    DateTime lastUpdated, {
    Iterable<TodoRow> rows = const [],
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'title', title);
    RealmObjectBase.set(this, 'lastUpdated', lastUpdated);
    RealmObjectBase.set<RealmList<TodoRow>>(
        this, 'rows', RealmList<TodoRow>(rows));
  }

  Todo._();

  @override
  Uuid get id => RealmObjectBase.get<Uuid>(this, 'id') as Uuid;
  @override
  set id(Uuid value) => throw RealmUnsupportedSetError();

  @override
  String get title => RealmObjectBase.get<String>(this, 'title') as String;
  @override
  set title(String value) => RealmObjectBase.set(this, 'title', value);

  @override
  RealmList<TodoRow> get rows =>
      RealmObjectBase.get<TodoRow>(this, 'rows') as RealmList<TodoRow>;
  @override
  set rows(covariant RealmList<TodoRow> value) =>
      throw RealmUnsupportedSetError();

  @override
  DateTime get lastUpdated =>
      RealmObjectBase.get<DateTime>(this, 'lastUpdated') as DateTime;
  @override
  set lastUpdated(DateTime value) => throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<Todo>> get changes =>
      RealmObjectBase.getChanges<Todo>(this);

  @override
  Todo freeze() => RealmObjectBase.freezeObject<Todo>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(Todo._);
    return const SchemaObject(ObjectType.realmObject, Todo, 'Todo', [
      SchemaProperty('id', RealmPropertyType.uuid, primaryKey: true),
      SchemaProperty('title', RealmPropertyType.string),
      SchemaProperty('rows', RealmPropertyType.object,
          linkTarget: 'TodoRow', collectionType: RealmCollectionType.list),
      SchemaProperty('lastUpdated', RealmPropertyType.timestamp),
    ]);
  }
}

class Todos extends _Todos with RealmEntity, RealmObjectBase, RealmObject {
  Todos({
    Iterable<Todo> entries = const [],
  }) {
    RealmObjectBase.set<RealmList<Todo>>(
        this, 'entries', RealmList<Todo>(entries));
  }

  Todos._();

  @override
  RealmList<Todo> get entries =>
      RealmObjectBase.get<Todo>(this, 'entries') as RealmList<Todo>;
  @override
  set entries(covariant RealmList<Todo> value) =>
      throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<Todos>> get changes =>
      RealmObjectBase.getChanges<Todos>(this);

  @override
  Todos freeze() => RealmObjectBase.freezeObject<Todos>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(Todos._);
    return const SchemaObject(ObjectType.realmObject, Todos, 'Todos', [
      SchemaProperty('entries', RealmPropertyType.object,
          linkTarget: 'Todo', collectionType: RealmCollectionType.list),
    ]);
  }
}

class Profile extends _Profile with RealmEntity, RealmObjectBase, RealmObject {
  Profile({
    String? nickname,
  }) {
    RealmObjectBase.set(this, 'nickname', nickname);
  }

  Profile._();

  @override
  String? get nickname =>
      RealmObjectBase.get<String>(this, 'nickname') as String?;
  @override
  set nickname(String? value) => RealmObjectBase.set(this, 'nickname', value);

  @override
  Stream<RealmObjectChanges<Profile>> get changes =>
      RealmObjectBase.getChanges<Profile>(this);

  @override
  Profile freeze() => RealmObjectBase.freezeObject<Profile>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(Profile._);
    return const SchemaObject(ObjectType.realmObject, Profile, 'Profile', [
      SchemaProperty('nickname', RealmPropertyType.string, optional: true),
    ]);
  }
}

class Account extends _Account with RealmEntity, RealmObjectBase, RealmObject {
  Account(
    String username,
    String passwordHash, {
    Profile? profile,
    Todos? todos,
  }) {
    RealmObjectBase.set(this, 'username', username);
    RealmObjectBase.set(this, 'passwordHash', passwordHash);
    RealmObjectBase.set(this, 'profile', profile);
    RealmObjectBase.set(this, 'todos', todos);
  }

  Account._();

  @override
  String get username =>
      RealmObjectBase.get<String>(this, 'username') as String;
  @override
  set username(String value) => throw RealmUnsupportedSetError();

  @override
  String get passwordHash =>
      RealmObjectBase.get<String>(this, 'passwordHash') as String;
  @override
  set passwordHash(String value) => throw RealmUnsupportedSetError();

  @override
  Profile? get profile =>
      RealmObjectBase.get<Profile>(this, 'profile') as Profile?;
  @override
  set profile(covariant Profile? value) => throw RealmUnsupportedSetError();

  @override
  Todos? get todos => RealmObjectBase.get<Todos>(this, 'todos') as Todos?;
  @override
  set todos(covariant Todos? value) => throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<Account>> get changes =>
      RealmObjectBase.getChanges<Account>(this);

  @override
  Account freeze() => RealmObjectBase.freezeObject<Account>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(Account._);
    return const SchemaObject(ObjectType.realmObject, Account, 'Account', [
      SchemaProperty('username', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('passwordHash', RealmPropertyType.string),
      SchemaProperty('profile', RealmPropertyType.object,
          optional: true, linkTarget: 'Profile'),
      SchemaProperty('todos', RealmPropertyType.object,
          optional: true, linkTarget: 'Todos'),
    ]);
  }
}
