import 'package:flutter/widgets.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';

import 'package:sirene/app.dart';
import 'package:sirene/interfaces.dart';

class FirebaseLoginManager extends LoginManager {
  UserInfo _currentUser;
  UserInfo get currentUser => _currentUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Future<UserInfo> login() async {
    var ret = await FirebaseAuth.instance.currentUser();

    if (ret == null) {
      ret = await FirebaseAuth.instance.signInAnonymously();
    }

    _currentUser = ret;
    return ret;
  }

  @override
  Future<void> logout() {
    _currentUser = null;
    return FirebaseAuth.instance.signOut();
  }

  @override
  Future<UserInfo> ensureUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    return await login();
  }

  @override
  Future<UserInfo> ensureNamedUser() async {
    _currentUser = _currentUser ?? await FirebaseAuth.instance.currentUser();

    if (_currentUser != null &&
        _currentUser.email != null &&
        _currentUser.email.isNotEmpty) {
      return _currentUser;
    }

    final newUser = await _upgradeAnonymousUser();
    _currentUser = newUser;

    return newUser;
  }

  Future<UserInfo> _upgradeAnonymousUser() async {
    final googleUser = await _googleSignIn.signIn();
    final googleAuth = await googleUser.authentication;

    final cred = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(cred);
  }
}

mixin UserEnabledPage<T extends StatefulWidget> on State<T> {
  var userRequestError = new PublishSubject<Error>();

  withUser({bool requireNamed = false}) {
    final user = App.locator<LoginManager>().currentUser;

    if (user != null) {
      if (!requireNamed) return user;

      if (user.email != null && user.email.isNotEmpty) {
        return user;
      }
    }

    final getUser = requireNamed
        ? App.locator<LoginManager>().ensureNamedUser()
        : App.locator<LoginManager>().ensureUser();

    getUser.then((_) {
      // NB: This is to trigger the change from no user => some kind of user
      setState(() {});
    }, onError: (e) {
      userRequestError.add(e);
    });

    return user;
  }
}
