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

      try {
        App.locator.get<LogWriter>().logError(details.exception, details.stack);
      } catch (_) {
        FlutterError.dumpErrorToConsole(details);
      }
    }
  };

  Isolate.current.addErrorListener(RawReceivePort((dynamic pair) {
    var isolateError = pair as List<dynamic>;
    final error = isolateError.first;
    final nativeStack = isolateError.last.toString();

    var isDebug = false;
    assert(isDebug = true);

    if (isDebug) {
      debugPrint(error.toString());
      debugPrint(nativeStack);
    } else {
      if (App.locator == null) {
        debugPrint(error.toString());
        debugPrint(nativeStack);
        return;
      }

      try {
        App.locator
            .get<LogWriter>()
            .logError(error, null, extras: {'nativeStack': nativeStack});
      } catch (_) {
        debugPrint(error.toString());
        debugPrint(nativeStack);
      }
    }
  }).sendPort);

  runZoned(() => runApp(AppWidget()), onError: (e, StackTrace st) {
    var isDebug = false;
    assert(isDebug = true);

    if (isDebug) {
      debugPrint(e.toString());
      debugPrint(st.toString());
    } else {
      if (App.locator == null) {
        debugPrint(e.toString());
        debugPrint(st.toString());
        return;
      }

      try {
        App.locator.get<LogWriter>().logError(e, st);
      } catch (_) {
        debugPrint(e.toString());
        debugPrint(st.toString());
      }
    }
  });
}
