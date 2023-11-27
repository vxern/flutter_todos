import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realm/realm.dart';
import 'package:universal_io/io.dart';

import 'package:flutter_todos/constants.dart' as constants;
import 'package:flutter_todos/repositories/database.dart';
import 'package:flutter_todos/structs/account.dart';

class AuthenticationRepository {
  final KdfAlgorithm _argon2;

  static final int iterations = Platform.numberOfProcessors * 64;
  static final int parallelism = Platform.numberOfProcessors;

  final DatabaseRepository _database;

  Account? account;

  bool get isAuthenticated => account != null;

  bool get isNotAuthenticated => !isAuthenticated;

  String get username => account!.username;

  AuthenticationRepository._({required DatabaseRepository database})
      : _argon2 = Argon2id(
          parallelism: parallelism,
          memory: constants.hashingMemory,
          iterations: iterations,
          hashLength: constants.hashingHashLength,
        ),
        _database = database;

  factory AuthenticationRepository.create({
    required DatabaseRepository database,
  }) =>
      AuthenticationRepository._(database: database);

  static RepositoryProvider<AuthenticationRepository> getProvider({
    required DatabaseRepository database,
  }) =>
      RepositoryProvider.value(
        value: AuthenticationRepository.create(database: database),
      );

  Future<String> _hash({required String password}) async {
    final key = await _argon2.deriveKeyFromPassword(
      nonce: utf8.encode(constants.hashingSaltPhrase),
      password: password,
    );

    final String hash;
    try {
      hash = utf8.decode(await key.extractBytes(), allowMalformed: true);
    } on FormatException catch (exception) {
      throw StateError('Could not decode hash bytes: $exception');
    }

    return hash;
  }

  /// ⚠️ Throws:
  /// - [AlreadyLoggedInException] if has already logged in previously.
  /// - [AccountNotExistsException] if no account exists with the given
  ///   username.
  /// - [WrongPasswordException] if the passwords do not match.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (isAuthenticated) {
      throw const AlreadyLoggedInException();
    }

    final database = _database.database;

    final account = database.find<Account>(username);
    if (account == null) {
      throw const AccountNotExistsException();
    }

    final passwordHash = await _hash(password: password);

    if (passwordHash != account.passwordHash) {
      throw const WrongPasswordException();
    }

    this.account = account;
  }

  /// ⚠️ Throws an [AccountAlreadyExistsException] if an account with that
  /// username already exists.
  Future<Account> register({
    required String username,
    required String? nickname,
    required String password,
  }) async {
    final database = _database.database;

    if (database.find<Account>(username) != null) {
      throw const AccountAlreadyExistsException();
    }

    final passwordHash = await _hash(password: password);

    final Account account;
    try {
      account = await database.writeAsync(
        () => database.add<Account>(
          Account(
            username,
            passwordHash,
            profile: Profile(nickname: nickname),
            todos: Todos(),
          ),
        ),
      );
    } on RealmException catch (exception) {
      throw StateError('Encountered unexpected realm exception: $exception');
    }

    return account;
  }

  /// ⚠️ Throws an [AlreadyLoggedOutException] if the user has already logged
  /// out of their account.
  Future<void> logout() async {
    if (account == null) {
      throw const AlreadyLoggedOutException();
    }

    account = null;
  }

  Future<void> dispose() async {
    account = null;
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

class AlreadyLoggedOutException extends AuthenticationException {
  const AlreadyLoggedOutException() : super(message: 'Already logged out.');
}

class AccountAlreadyExistsException extends AuthenticationException {
  const AccountAlreadyExistsException()
      : super(message: 'An account with that username already exists.');
}
