import 'dart:io' show Platform;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:fluro/fluro.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:sirene/debug-analytics.dart';

import 'package:sirene/interfaces.dart';
import 'package:sirene/pages/login.dart';

import './pages/hello.dart';

enum ApplicationMode { Debug, Production, Test }

// https://material.io/tools/color/#!/?view.left=0&view.right=0&primary.color=FFA5DD&secondary.color=7ED776&secondary.text.color=ffffff
class ThemeMetrics {
  static const primaryColor = Color.fromARGB(0xff, 0xff, 0xa5, 0xdd);
  static const primaryColorLight = Color.fromARGB(0xff, 0xff, 0xd7, 0xff);
  static const primaryColorDark = Color.fromARGB(0xff, 0xcb, 0x75, 0xab);

  static const primaryColorText = Colors.black;

  static const secondaryColor = Color.fromARGB(0xff, 0x7e, 0xd7, 0x76);
  static const secondaryColorLight = Color.fromARGB(0xff, 0xb1, 0xff, 0xa6);
  static const secondaryColorDark = Color.fromARGB(0xff, 0x4c, 0xa5, 0x48);

  static const secondaryColorText = Colors.white;

  static const neutralDark = Color.fromARGB(0xff, 0xe1, 0xe2, 0xe1);
  static const neutralLight = Color.fromARGB(0xff, 0xf5, 0xf5, 0xf6);

  static ThemeData fullTheme() {
    final titleFont =
        TextTheme(title: TextStyle(fontFamily: "GrandHotel", fontSize: 26.0));

    final typography = Typography(
        platform: defaultTargetPlatform,
        dense: Typography.dense2018,
        englishLike: Typography.englishLike2018.merge(titleFont),
        tall: Typography.tall2018);

    return ThemeData(
        primaryColor: primaryColor,
        primaryColorLight: primaryColorLight,
        primaryColorDark: primaryColorDark,
        primaryTextTheme:
            typography.englishLike.apply(bodyColor: primaryColorText),
        backgroundColor: neutralLight,
        dialogBackgroundColor: neutralLight,
        scaffoldBackgroundColor: neutralLight,
        accentColor: secondaryColor,
        accentTextTheme:
            typography.englishLike.apply(displayColor: secondaryColorText),
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

  static get analytics => App.locator<FirebaseAnalytics>();

  static setupRegistration(GetIt l) {
    final isTestMode = Platform.resolvedExecutable.contains("_tester");
    var isDebugMode = false;

    // NB: Assert statements are stripped from release mode. Clever!
    assert(isDebugMode = true);

    l.registerSingleton<Router>(setupRoutes(new Router()));
    l.registerSingleton<LoginManager>(new FirebaseLoginManager());

    final appMode = isTestMode
        ? ApplicationMode.Test
        : isDebugMode ? ApplicationMode.Debug : ApplicationMode.Production;

    l.registerSingleton<ApplicationMode>(appMode);

    if (appMode == ApplicationMode.Production) {
      l.registerSingleton<FirebaseAnalytics>(FirebaseAnalytics());
    } else {
      l.registerSingleton<FirebaseAnalytics>(DebugFirebaseAnalytics());
    }

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
    final routeObserver = App.locator<RouteObserver>();

    return MaterialApp(
      title: 'Sirene',
      theme: ThemeMetrics.fullTheme(),
      initialRoute: '/login',
      onGenerateRoute: App.locator<Router>().generator,
      navigatorObservers: routeObserver != null ? [routeObserver] : [],
    );
  }
}

class AppWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new App();
}
