import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:realm/realm.dart';
import 'package:universal_io/io.dart';

import 'package:flutter_todos/constants.dart' as constants;
import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/repositories/repository.dart';
import 'package:flutter_todos/structs/account.dart';

class AuthenticationRepository extends Repository with _Hashing {
  // This is just a reference, not a managed resource, therefore do not dispose.
  final DatabaseRepository _database;

  Account? _account;

  /// ! Throws a [StateError] if [AuthenticationRepository] has not been
  /// ! initialised.
  Account get account {
    if (_account == null) {
      throw StateError('Attempted to access account before initialisation.');
    }

    return _account!;
  }

  bool get isAuthenticated => _account != null;

  bool get isNotAuthenticated => _account == null;

  AuthenticationRepository({required DatabaseRepository database})
      : _database = database,
        super(name: 'AuthenticationRepository', allowMultipleInitialise: true);

  /// ! Throws [StateError] when failed to hash password.
  // * Visible for testing.
  @override
  Future<String> deriveHash({required String password}) async {
    final String hash;
    try {
      hash = await super.deriveHash(password: password);
      // ignore: avoid_catches_without_on_clauses
    } catch (problem) {
      switch (problem) {
        case UnsupportedError _ || FormatException _:
          throw StateError('Failed to hash password.');
      }

      rethrow;
    }

    return hash;
  }

  /// ! Throws:
  /// - ! [AlreadyLoggedInException] if has already logged in previously.
  /// - ! [AccountNotExistsException] if no account exists with the given
  ///   ! username.
  /// - ! [WrongPasswordException] if the passwords do not match.
  /// - ! [ResourceException] upon failure to hash the password.
  /// - ! (propagated) [StateError] if the repository is disposed.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    verifyNotDisposed(message: 'Attempted to log in when disposed.');

    if (isAuthenticated) {
      throw const AlreadyLoggedInException();
    }

    initialisationCubit.declareInitialising();

    final account = _database.realm.find<Account>(username);
    if (account == null) {
      initialisationCubit.declareUninitialised();
      throw const AccountNotExistsException();
    }

    final String hash;
    try {
      hash = await deriveHash(password: password);
    } on StateError catch (error) {
      const message = 'Failed to hash password during login.';
      log
        ..severe(message)
        ..severe(error);
      initialisationCubit.declareFailed();
      throw const ResourceException(message: message);
    }

    if (hash != account.passwordHash) {
      initialisationCubit.declareUninitialised();
      throw const WrongPasswordException();
    }

    _account = account;
    initialisationCubit.declareInitialised(value: ());
  }

  /// ! Throws:
  /// - ! [AccountAlreadyExistsException] if an account with that username
  ///   ! already exists.
  /// - ! [ResourceException] upon failure to create the account.
  /// - ! [ResourceException] upon failure to hash the password.
  /// - ! (propagated) [StateError] if the repository is disposed.
  Future<Account> register({
    required String username,
    required String? nickname,
    required String password,
  }) async {
    verifyNotDisposed(message: 'Attempted to register when disposed.');

    if (_database.realm.find<Account>(username) != null) {
      throw const AccountAlreadyExistsException();
    }

    final String hash;
    try {
      hash = await deriveHash(password: password);
    } on StateError catch (error) {
      const message = 'Failed to hash password during registration.';
      log
        ..fatal(message)
        ..fatal(error);
      throw const ResourceException(message: message);
    }

    final Account account;
    try {
      account = await _database.realm.writeAsync(
        () => _database.realm.add(
          Account(
            username,
            hash,
            profile: Profile(nickname: nickname),
            todos: Todos(),
          ),
        ),
      );
    } on RealmException catch (exception) {
      log.severe(exception);
      throw const ResourceException(message: 'Failed to save account.');
    }

    return account;
  }

  Future<void> logout() async {
    await uninitialise();
    _account = null;
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    _account = null;
  }
}

mixin _Hashing {
  static final _argon2 = Argon2id(
    parallelism: Platform.numberOfProcessors * 2,
    memory: constants.hashingMemory,
    iterations: Platform.numberOfProcessors,
    hashLength: constants.hashingHashLength,
  );

  /// ! Throws:
  /// - ! [UnsupportedError] on not being able to read the key bytes.
  /// - ! [FormatException] on not being able to decode bytes into a string.
  Future<String> deriveHash({required String password}) async {
    final key = await _argon2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: utf8.encode(constants.hashingSaltPhrase),
    );

    final List<int> bytes;
    try {
      bytes = await key.extractBytes();
    } on UnsupportedError {
      rethrow;
    }

    final String hash;
    try {
      hash = utf8.decode(bytes, allowMalformed: true);
    } on FormatException {
      rethrow;
    }

    return hash;
  }
}

sealed class AuthenticationException implements Exception {
  final String message;

  const AuthenticationException({required this.message});

  @override
  String toString() => message;
}

class AlreadyLoggedInException extends AuthenticationException {
  const AlreadyLoggedInException() : super(message: 'Already authenticated.');
}

class AccountNotExistsException extends AuthenticationException {
  const AccountNotExistsException()
      : super(message: 'An account with that username does not exist.');
}

class WrongPasswordException extends AuthenticationException {
  const WrongPasswordException()
      : super(message: 'The passwords do not match.');
}

class AccountAlreadyExistsException extends AuthenticationException {
  const AccountAlreadyExistsException()
      : super(message: 'An account with that username already exists.');
}
