import 'package:firebase_auth/firebase_auth.dart';

abstract class LoginManager {
  UserInfo currentUser;

  Future<UserInfo> login();
  Future<void> logout();
  Future<UserInfo> ensureNamedUser();
}
