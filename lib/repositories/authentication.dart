import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_todos/cubits.dart';
import 'package:flutter_todos/utils.dart';
import 'package:realm/realm.dart';
import 'package:sprint/sprint.dart';
import 'package:universal_io/io.dart';

import 'package:flutter_todos/constants.dart' as constants;
import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/structs/account.dart';

typedef Hasher = Future<String> Function({required String password});

final _argon2 = Argon2id(
  parallelism: Platform.numberOfProcessors * 64,
  memory: constants.hashingMemory,
  iterations: Platform.numberOfProcessors,
  hashLength: constants.hashingHashLength,
);

/// ! Throws a [StateError] on not being able to decode bytes into a string
/// ! hash.
Future<String> deriveHash({required String password}) async {
  final key = await _argon2.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: utf8.encode(constants.hashingSaltPhrase),
  );

  final String hash;
  try {
    hash = utf8.decode(await key.extractBytes(), allowMalformed: true);
  } on FormatException catch (exception) {
    throw StateError('Could not decode hash bytes: $exception');
  }

  return hash;
}

class AuthenticationRepository with Loggable, Disposable {
  @override
  bool isDisposed = false;

  @override
  final Sprint log;

  // * Visible for testing.
  final initialisationCubit = InitialisationCubit();

  // This is just a reference, not a managed resource, therefore do not dispose.
  final DatabaseRepository _database;

  Account? _account;

  // * Visible for testing.
  final Hasher deriveHashDebug;

  /// ! Throws a [StateError] if [AuthenticationRepository] has not been initialised.
  Account get account => _account!;

  bool get isNotAuthenticated => _account == null;

  bool get isAuthenticated => _account != null;

  AuthenticationRepository({
    required DatabaseRepository database,
    // * Visible for testing.
    Hasher? deriveHashDebug,
  })  : log = Sprint('Authentication'),
        _database = database,
        deriveHashDebug = deriveHashDebug ?? deriveHash;

  /// ! Throws:
  /// - ! [AlreadyLoggedInException] if has already logged in previously.
  /// - ! [AccountNotExistsException] if no account exists with the given
  ///   ! username.
  /// - ! [WrongPasswordException] if the passwords do not match.
  /// - ! (propagated) [StateError] if the repository is disposed.
  /// - ! (propagated) [StateError] upon failure to hash the password.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    verifyNotDisposed();

    if (isAuthenticated) {
      throw const AlreadyLoggedInException();
    }

    initialisationCubit.declareInitialising();

    final account = _database.realm.find<Account>(username);
    if (account == null) {
      initialisationCubit.declareFailed();
      throw const AccountNotExistsException();
    }

    final String passwordHash;
    try {
      passwordHash = await deriveHashDebug(password: password);
    } on StateError catch (error) {
      log
        ..severe('Failed to hash password during login.')
        ..severe(error);
      rethrow;
    }

    if (passwordHash != account.passwordHash) {
      initialisationCubit.declareFailed();
      throw const WrongPasswordException();
    }

    _account = account;
    initialisationCubit.declareInitialised();
  }

  /// ! Throws:
  /// - ! [AccountAlreadyExistsException] if an account with that username
  ///   ! already exists.
  /// - ! [FailedToRegisterException] upon failure to register the account.
  /// - ! (propagated) [StateError] if the repository is disposed.
  /// - ! (propagated) [StateError] upon failure to hash the password.
  Future<Account> register({
    required String username,
    required String? nickname,
    required String password,
  }) async {
    verifyNotDisposed();

    if (_database.realm.find<Account>(username) != null) {
      throw const AccountAlreadyExistsException();
    }

    final String passwordHash;
    try {
      passwordHash = await deriveHashDebug(password: password);
    } on StateError catch (error) {
      log
        ..severe('Failed to hash password during login.')
        ..severe(error);
      rethrow;
    }

    final Account account;
    try {
      account = await _database.realm.writeAsync(
        () => _database.realm.add(
          Account(
            username,
            passwordHash,
            profile: Profile(nickname: nickname),
            todos: Todos(),
          ),
        ),
      );
    } on RealmException {
      throw const FailedToRegisterException();
    }

    return account;
  }

  Future<void> logout() async {
    _account = null;
    initialisationCubit.declareUninitialised();
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;

    _account = null;

    return initialisationCubit.close();
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

class FailedToRegisterException extends AuthenticationException {
  const FailedToRegisterException()
      : super(message: 'Failed to register the account.');
}
