import 'package:flutter/widgets.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';

import 'package:sirene/app.dart';
import 'package:sirene/interfaces.dart';
import 'package:sirene/services/logging.dart';

class FirebaseLoginManager with LoggerMixin implements LoginManager {
  UserInfo _currentUser;
  UserInfo get currentUser => _currentUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Observable<UserInfo> getAuthState() {
    return Observable.concat([
      Observable.fromFuture(ensureUser()),
      Observable(FirebaseAuth.instance.onAuthStateChanged)
    ]);
  }

  @override
  Future<UserInfo> login() async {
    var ret = await FirebaseAuth.instance.currentUser();

    if (ret == null) {
      ret = await FirebaseAuth.instance.signInAnonymously();

      logAsyncException(
          (new User(isAnonymous: true)).toDocument(
              Firestore.instance.collection('users').document(ret.uid)),
          rethrowIt: false);
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

    final newUser = await logAsyncException(() async {
      final ret = await _upgradeAnonymousUser();
      App.analytics.logEvent(name: "upgrade_user", parameters: {
        "uid": ret.uid,
        "email": ret.email,
      });

      return ret;
    }());

    _currentUser = newUser;

    // NB: This is intentionally not awaited, there's no reason to
    // block on this
    logAsyncException(
        (new User(isAnonymous: false, email: newUser.email)).toDocument(
            Firestore.instance.collection('users').document(newUser.uid)),
        rethrowIt: false);

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
      App.analytics.logLogin();
      setState(() {});
    }, onError: (e, st) {
      final log = App.locator.get<LogWriter>();

      log.logError(e, st,
          message: "Failed to ensure user, named = $requireNamed");
      userRequestError.add(e);
    });

    return user;
  }
}
