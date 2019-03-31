import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'package:device_info/device_info.dart';
import 'package:package_info/package_info.dart';

import 'package:sirene/app.dart';
import 'package:sirene/interfaces.dart';

/* Production mode:
 * Analytics to Firebase
 * Logging to Ringbuffer
 * Exceptions to Firebase + Sentry, dump ringbuffer
 */

final Map<int, String> _typeNameMap = Map();

abstract class LogWriter {
  void log(String message, {bool isDebug, Map<String, dynamic> extras});
  void logError(dynamic ex, StackTrace st,
      {String message, Map<String, dynamic> extras}) {}
}

class DebugLogWriter implements LogWriter {
  @override
  void log(String message, {bool isDebug, Map<String, dynamic> extras}) {
    debugPrint(message);
  }

  @override
  void logError(dynamic ex, StackTrace st,
      {String message, Map<String, dynamic> extras}) {
    if (message != null) {
      debugPrint('$message ($ex)\n$st');
    }
  }
}

class ProductionLogWriter implements LogWriter {
  @override
  void log(String message, {bool isDebug, Map<String, dynamic> extras}) {
    if (isDebug) return;

    Crashlytics.instance.log(message);
  }

  @override
  void logError(dynamic ex, StackTrace st,
      {String message, Map<String, dynamic> extras}) {
    extras ??= Map();
    final user = App.locator.get<LoginManager>().currentUser;

    if (user != null) {
      Crashlytics.instance.setUserIdentifier(user.uid);
      Crashlytics.instance.setUserEmail(user.email);
    }

    Crashlytics.instance.onError(
        FlutterErrorDetails(exception: ex, stack: st, context: message));
  }
}

mixin LoggerMixin {
  LogWriter _logger;

  _ensureLogger() {
    return _logger ?? (_logger = App.locator.get<LogWriter>());
  }

  log(String message) {
    final name = _typeNameMap[this.runtimeType.hashCode] ??
        (_typeNameMap[this.runtimeType.hashCode] = this.runtimeType.toString());

    _ensureLogger().log("$name: $message");
  }

  debug(String message) {
    final name = _typeNameMap[this.runtimeType.hashCode] ??
        (_typeNameMap[this.runtimeType.hashCode] = this.runtimeType.toString());

    _ensureLogger().log("$name: $message", isDebug: true);
  }

  logError(dynamic ex, StackTrace st,
      {String message, Map<String, dynamic> extras}) {
    _ensureLogger().logError(ex, st, message: message, extras: extras);
  }

  logException<TRet>(TRet Function() block,
      {bool rethrowIt = true, String message}) {
    try {
      return block();
    } catch (e, st) {
      _ensureLogger().logError(e, st, message: message);
      if (rethrowIt) rethrow;
    }
  }

  logAsyncException<TRet>(Future<TRet> Function() block,
      {bool rethrowIt = true, String message}) async {
    try {
      return await block();
    } catch (e, st) {
      _ensureLogger().logError(e, st, message: message);
      if (rethrowIt) rethrow;
    }
  }
}
