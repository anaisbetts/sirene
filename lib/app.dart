import 'dart:io' show Platform;
import 'package:flutter/material.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:get_it/get_it.dart';
import 'package:sentry/sentry.dart';

import 'package:sirene/interfaces.dart';
import 'package:sirene/pages/main/page.dart';
import 'package:sirene/services/database.dart';
import 'package:sirene/services/debug-analytics.dart';
import 'package:sirene/services/logging.dart';
import 'package:sirene/services/login.dart';
import 'package:sirene/services/router.dart';
import 'package:sirene/services/theming.dart';

class App extends State<AppWidget> {
  static GetIt locator;

  App() {
    locator = App.setupRegistration(GetIt());
  }

  static FirebaseAnalytics get analytics => App.locator<FirebaseAnalytics>();

  static setupRegistration(GetIt l) {
    final isTestMode = Platform.resolvedExecutable.contains("_tester");
    var isDebugMode = false;

    // NB: Assert statements are stripped from release mode. Clever!
    assert(isDebugMode = true);

    l.registerSingleton<LoginManager>(new FirebaseLoginManager());

    final appMode = isTestMode
        ? ApplicationMode.Test
        : isDebugMode ? ApplicationMode.Debug : ApplicationMode.Production;

    l.registerSingleton<ApplicationMode>(appMode);
    l.registerSingleton<Router>(setupRoutes(Router()));
    l.registerSingleton<StorageManager>(FirebaseStorageManager());

    if (appMode == ApplicationMode.Production || true) {
      l.registerSingleton<FirebaseAnalytics>(FirebaseAnalytics());
      l.registerSingleton<SentryClient>(SentryClient(
          dsn: 'https://04bfa4b9d5d34110a41b89e8d8c74649@sentry.io/1425391'));
      l.registerSingleton<LogWriter>(new ProductionLogWriter());
    } else {
      l.registerSingleton<FirebaseAnalytics>(DebugFirebaseAnalytics());
      l.registerSingleton<LogWriter>(new DebugLogWriter());
    }

    l.registerSingleton<RouteObserver>(
        new FirebaseAnalyticsObserver(analytics: l<FirebaseAnalytics>()));

    return l;
  }

  static setupRoutes(Router r) {
    MainPage.setupRoutes(r);
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final routeObserver = App.locator<RouteObserver>();

    return MaterialApp(
      title: 'Sirene',
      theme: ThemeMetrics.fullTheme(),
      initialRoute: '/',
      onGenerateRoute: App.locator<Router>().generator,
      navigatorObservers: routeObserver != null ? [routeObserver] : [],
    );
  }
}

class AppWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new App();
}
