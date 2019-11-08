import 'package:flutter/widgets.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';

import 'package:sirene/app.dart';
import 'package:sirene/interfaces.dart';
import 'package:sirene/services/logging.dart';

class FirebaseLoginManager with LoggerMixin implements LoginManager {
  UserInfo _currentUser;
  @override
  UserInfo get currentUser => _currentUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Observable<UserInfo> getAuthState() {
    return Observable.concat([
      Observable.fromFuture(
          FirebaseAuth.instance.currentUser().then((u) => _currentUser = u)),
      Observable(FirebaseAuth.instance.onAuthStateChanged)
    ]);
  }

  @override
  Future<UserInfo> login() async {
    var ret = await FirebaseAuth.instance.currentUser();

    if (ret == null) {
      ret = (await FirebaseAuth.instance.signInAnonymously()).user;

      unawaited(logAsyncException(
          (User(isAnonymous: true)).toDocument(
              Firestore.instance.collection('users').document(ret.uid)),
          rethrowIt: false));
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
  Future<UserInfo> ensureNamedUser() async {
    _currentUser = _currentUser ?? await FirebaseAuth.instance.currentUser();

    if (_currentUser != null &&
        _currentUser.email != null &&
        _currentUser.email.isNotEmpty) {
      return _currentUser;
    }

    final newUser = await logAsyncException(() async {
      final ret = await _upgradeAnonymousUser();
      unawaited(App.analytics.logEvent(name: 'upgrade_user', parameters: {
        'uid': ret.uid,
        'email': ret.email,
      }));

      return ret;
    }());

    _currentUser = newUser;

    // NB: This is intentionally not awaited, there's no reason to
    // block on this
    unawaited(logAsyncException(
        (User(isAnonymous: false, email: newUser.email)).toDocument(
            Firestore.instance.collection('users').document(newUser.uid)),
        rethrowIt: false));

    return newUser;
  }

  Future<UserInfo> _upgradeAnonymousUser() async {
    final googleUser = await _googleSignIn.signIn();
    final googleAuth = await googleUser.authentication;

    final cred = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return (await FirebaseAuth.instance.signInWithCredential(cred)).user;
  }
}

mixin UserEnabledPage<T extends StatefulWidget> on State<T> {
  var userRequestError = PublishSubject<dynamic>();

  UserInfo withNamedUser() {
    final user = App.locator<LoginManager>().currentUser;

    if (user != null && user.email != null && user.email.isNotEmpty) {
      return user;
    }

    App.locator<LoginManager>().ensureNamedUser()
      ..then((_) {
        App.analytics.logLogin();
        setState(() {});
      }, onError: (e, st) {
        App.locator
            .get<LogWriter>()
            .logError(e, st as StackTrace, message: 'Failed to ensure user');
        userRequestError.add(e);
      });

    return user;
  }
}
