import 'dart:io' show Platform;
import 'package:flutter/material.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:get_it/get_it.dart';
import 'package:sentry/sentry.dart';

import 'package:sirene/interfaces.dart';
import 'package:sirene/pages/main/page.dart';
import 'package:sirene/pages/present-phrase/page.dart';
import 'package:sirene/services/database.dart';
import 'package:sirene/services/debug-analytics.dart';
import 'package:sirene/services/logging.dart';
import 'package:sirene/services/login.dart';
import 'package:sirene/services/router.dart';
import 'package:sirene/services/theming.dart';

class App extends State<AppWidget> {
  static GetIt locator;
  static Map<String, Trace> traces = {};

  App() {
    traces['app_startup'] =
        FirebasePerformance.instance.newTrace('app_startup');
    traces['app_startup'].start();
    locator = App.setupRegistration(GetIt());
  }

  static FirebaseAnalytics get analytics => App.locator<FirebaseAnalytics>();

  static GetIt setupRegistration(GetIt locator) {
    final isTestMode = Platform.resolvedExecutable.contains('_tester');
    var isDebugMode = false;

    // NB: Assert statements are stripped from release mode. Clever!
    assert(isDebugMode = true);

    final appMode = isTestMode
        ? ApplicationMode.test
        : isDebugMode ? ApplicationMode.debug : ApplicationMode.production;

    locator
      ..registerSingleton<ApplicationMode>(appMode)
      ..registerSingleton<Router>(setupRoutes(Router()))
      ..registerSingleton<StorageManager>(FirebaseStorageManager());

    if (appMode == ApplicationMode.production) {
      locator
        ..registerSingleton<FirebaseAnalytics>(FirebaseAnalytics())
        ..registerSingleton<SentryClient>(SentryClient(
            dsn: 'https://04bfa4b9d5d34110a41b89e8d8c74649@sentry.io/1425391'))
        ..registerSingleton<LogWriter>(ProductionLogWriter());
    } else {
      locator
        ..registerSingleton<FirebaseAnalytics>(DebugFirebaseAnalytics())
        ..registerSingleton<LogWriter>(DebugLogWriter());
    }

    locator
      ..registerSingleton<LoginManager>(FirebaseLoginManager())
      ..registerSingleton<RouteObserver>(
          FirebaseAnalyticsObserver(analytics: locator<FirebaseAnalytics>()));

    return locator;
  }

  static Router setupRoutes(Router r) {
    MainPage.setupRoutes(r);
    PresentPhrasePage.setupRoutes(r);

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
  State<StatefulWidget> createState() => App();
}
