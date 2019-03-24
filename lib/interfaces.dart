import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum ApplicationMode { Debug, Production, Test }

abstract class LoginManager {
  UserInfo currentUser;

  Future<UserInfo> login();
  Future<void> logout();

  Future<UserInfo> ensureNamedUser();
  Future<UserInfo> ensureUser();
}
