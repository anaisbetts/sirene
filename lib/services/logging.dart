import 'package:flutter/foundation.dart';

import 'package:catcher/catcher_plugin.dart';
import 'package:package_info/package_info.dart';
import 'package:sentry/sentry.dart' as sentry;

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
  void logError(Exception ex, StackTrace st,
      {String message, Map<String, dynamic> extras}) {}
}

class DebugLogWriter implements LogWriter {
  @override
  void log(String message, {bool isDebug, Map<String, dynamic> extras}) {
    debugPrint(message);
  }

  @override
  void logError(Exception ex, StackTrace st,
      {String message, Map<String, dynamic> extras}) {
    if (message != null) {
      debugPrint('$message ($ex)\n$st');
    }
  }
}

class _LogMessage {
  _LogMessage({this.message, this.extras}) {
    time = DateTime.now().millisecondsSinceEpoch;
  }

  int time;
  final String message;
  final Map<String, dynamic> extras;
}

const kMaxBufferSize = 16;

class ProductionLogWriter implements LogWriter {
  var _ringBuffer = <_LogMessage>[];
  PackageInfo _packageInfo;

  ProductionLogWriter() {
    PackageInfo.fromPlatform()
        .then((pi) => _packageInfo = pi)
        .catchError((e, st) {
      debugPrint("Couldn't get package info! $e\n$st");
    });
  }

  @override
  void log(String message, {bool isDebug, Map<String, dynamic> extras}) {
    if (isDebug) return;

    _ringBuffer.add(_LogMessage(message: message, extras: extras));
    while (_ringBuffer.length > kMaxBufferSize) {
      _ringBuffer.removeAt(0);
    }
  }

  @override
  void logError(Exception ex, StackTrace st,
      {String message, Map<String, dynamic> extras}) {
    final user = App.locator.get<LoginManager>().currentUser;

    // TODO: Fork flutter/sentry to support breadcrumbs
    App.locator.get<sentry.SentryClient>().capture(
        event: sentry.Event(
            exception: ex,
            stackTrace: st,
            extra: extras,
            message: message,
            userContext: sentry.User(email: user.email, id: user.uid),
            release: _packageInfo.version));

    App.analytics.logEvent(name: 'app_error', parameters: {
      "message": message ?? '',
      "error": ex.toString(),
    });
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

  logError(Exception ex, StackTrace st,
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

class LoggingCatcherHandler with LoggerMixin implements ReportHandler {
  @override
  Future<bool> handle(Report report) async {
    logError(report.error, report.stackTrace, extras: report.deviceParameters);
    return true;
  }
}
