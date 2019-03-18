import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:fluro/fluro.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import 'package:sirene/interfaces.dart';
import 'package:sirene/pages/login.dart';

import './pages/hello.dart';

// https://material.io/tools/color/#!/?view.left=0&view.right=0&primary.color=FFA5DD&secondary.color=7ED776&secondary.text.color=ffffff
class ThemeMetrics {
  static const primaryColor = Color.fromARGB(0xff, 0xff, 0xa5, 0xdd);
  static const primaryColorLight = Color.fromARGB(0xff, 0xff, 0xd7, 0xff);
  static const primaryColorDark = Color.fromARGB(0xff, 0xcb, 0x75, 0xab);

  static const primaryColorText = Color.fromARGB(0xff, 0, 0, 0);

  static const secondaryColor = Color.fromARGB(0xff, 0x7e, 0xd7, 0x76);
  static const secondaryColorLight = Color.fromARGB(0xff, 0xb1, 0xff, 0xa6);
  static const secondaryColorDark = Color.fromARGB(0xff, 0x4c, 0xa5, 0x48);

  static const secondaryColorText = Color.fromARGB(0xff, 0xff, 0xff, 0xff);

  static ThemeData fullTheme() {
    final titleFont =
        TextTheme(title: TextStyle(fontFamily: "GrandHotel", fontSize: 26.0));

    final typography = Typography(
        platform: defaultTargetPlatform,
        dense: Typography.dense2018,
        englishLike: Typography.englishLike2018.merge(titleFont),
        tall: Typography.tall2018);

    return ThemeData(
        primaryColor: ThemeMetrics.primaryColor,
        primaryColorLight: ThemeMetrics.primaryColorLight,
        primaryColorDark: ThemeMetrics.primaryColorDark,
        accentColor: ThemeMetrics.secondaryColor,
        typography: typography);
  }
}

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

class App extends State<AppWidget> {
  static GetIt locator;

  App() {
    locator = App.setupRegistration(GetIt());
  }

  static setupRegistration(GetIt l) {
    l.registerSingleton<Router>(setupRoutes(new Router()));
    l.registerSingleton<LoginManager>(new FirebaseLoginManager());
    l.registerSingleton<FirebaseAnalytics>(new FirebaseAnalytics());
    l.registerSingleton<RouteObserver>(
        new FirebaseAnalyticsObserver(analytics: l<FirebaseAnalytics>()));

    return l;
  }

  static setupRoutes(Router r) {
    HelloPage.setupRoutes(r);
    LoginPage.setupRoutes(r);

    return r;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sirene',
      theme: ThemeMetrics.fullTheme(),
      initialRoute: '/login',
      onGenerateRoute: App.locator<Router>().generator,
      navigatorObservers: [
        App.locator<RouteObserver>(),
      ],
    );
  }
}

class AppWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new App();
}
