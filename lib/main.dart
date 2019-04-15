import 'dart:async';
import 'dart:isolate';

import 'package:flutter/widgets.dart';

import 'package:sirene/app.dart';
import 'package:sirene/services/logging.dart';

void main() {
  FlutterError.onError = (details) {
    var isDebug = false;
    assert(isDebug = true);

    if (isDebug) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      if (App.locator == null) {
        FlutterError.dumpErrorToConsole(details);
        return;
      }

      LogWriter logger;
      try {
        logger = App.locator.get<LogWriter>();
        logger.logError(details.exception, details.stack);
      } catch (_) {
        FlutterError.dumpErrorToConsole(details);
      }
    }
  };

  Isolate.current.addErrorListener(new RawReceivePort((dynamic pair) {
    var isolateError = pair as List<dynamic>;
    dynamic error = isolateError.first;
    final nativeStack = isolateError.last.toString();

    var isDebug = false;
    assert(isDebug = true);

    if (isDebug) {
      debugPrint(error);
      debugPrint(nativeStack);
    } else {
      if (App.locator == null) {
        debugPrint(error);
        debugPrint(nativeStack);
        return;
      }

      LogWriter logger;
      try {
        logger = App.locator.get<LogWriter>();
        logger.logError(error, null, extras: {"nativeStack": nativeStack});
      } catch (_) {
        debugPrint(error);
        debugPrint(nativeStack);
      }
    }
  }).sendPort);

  runZoned(() => runApp(AppWidget()), onError: (e, st) {
    var isDebug = false;
    assert(isDebug = true);

    if (isDebug) {
      debugPrint(e);
      debugPrint(st);
    } else {
      if (App.locator == null) {
        debugPrint(e);
        debugPrint(st);
        return;
      }

      LogWriter logger;
      try {
        logger = App.locator.get<LogWriter>();
        logger.logError(e, st);
      } catch (_) {
        debugPrint(e);
        debugPrint(st);
      }
    }
  });
}
