import 'package:firebase_auth/firebase_auth.dart';

enum ApplicationMode { Debug, Production, Test }

abstract class LoginManager {
  UserInfo currentUser;

  Future<UserInfo> login();
  Future<void> logout();

  Future<UserInfo> ensureNamedUser();
  Future<UserInfo> ensureUser();
}
