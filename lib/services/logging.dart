import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import 'package:catcher/catcher_plugin.dart';
import 'package:device_info/device_info.dart';
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
  AndroidDeviceInfo _androidDeviceInfo;
  IosDeviceInfo _iosDeviceInfo;

  ProductionLogWriter() {
    final dip = DeviceInfoPlugin();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      dip.iosInfo.then((di) => _iosDeviceInfo = di).catchError((e, st) {
        debugPrint("Couldn't get device info! $e\n$st");
      });
    } else {
      dip.androidInfo.then((di) => _androidDeviceInfo = di).catchError((e, st) {
        debugPrint("Couldn't get device info! $e\n$st");
      });
    }

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
  void logError(dynamic ex, StackTrace st,
      {String message, Map<String, dynamic> extras}) {
    extras ??= Map();
    final user = App.locator.get<LoginManager>().currentUser;
    var deviceFingerprint = '';
    var device = '';
    var os = '';

    if (_androidDeviceInfo != null) {
      extras.addAll(androidToMap(_androidDeviceInfo));
      deviceFingerprint = _androidDeviceInfo.fingerprint;
      device = '${_androidDeviceInfo.manufacturer} ${_androidDeviceInfo.model}';
      os = '${_androidDeviceInfo.version.sdkInt}';
    }

    if (_iosDeviceInfo != null) {
      extras.addAll(iosToMap(_iosDeviceInfo));
      deviceFingerprint = _iosDeviceInfo.utsname.machine;
      device = _iosDeviceInfo.localizedModel;
      os = _iosDeviceInfo.systemVersion;
    }

    // TODO: Fork flutter/sentry to support breadcrumbs
    App.locator.get<sentry.SentryClient>().capture(
        event: sentry.Event(
            exception: ex,
            stackTrace: st,
            extra: extras,
            message: message,
            tags: {
              "device": device,
              "deviceFingerprint": deviceFingerprint,
              "os": os,
            },
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

  logAsyncException<TRet>(Future<TRet> block,
      {bool rethrowIt = true, String message}) async {
    try {
      return await block;
    } catch (e, st) {
      _ensureLogger().logError(e, st, message: message);
      if (rethrowIt) rethrow;
    }
  }

  traceAsync<TRet>(String name, Future<TRet> block) async {
    final trace = await FirebasePerformance.startTrace(name);
    final ret = await block;
    trace.stop();

    return ret;
  }
}

class LoggingCatcherHandler with LoggerMixin implements ReportHandler {
  @override
  Future<bool> handle(Report report) async {
    logError(report.error, report.stackTrace, extras: report.deviceParameters);
    return true;
  }
}

void setMapValue(Map<String, dynamic> map, String key, dynamic value) {
  map[key] = value;
}

void setMapValueIfNotNull(Map<String, dynamic> map, String key, dynamic value) {
  if (value != null) map[key] = value;
}

List<T> codeIterable<T>(Iterable values, T callback(value)) =>
    values?.map<T>(callback)?.toList();

Map<String, dynamic> androidToMap(AndroidDeviceInfo model) {
  if (model == null) return null;
  Map<String, dynamic> ret = <String, dynamic>{};
  setMapValue(ret, 'board', model.board);
  setMapValue(ret, 'bootloader', model.bootloader);
  setMapValue(ret, 'brand', model.brand);
  setMapValue(ret, 'device', model.device);
  setMapValue(ret, 'display', model.display);
  setMapValue(ret, 'fingerprint', model.fingerprint);
  setMapValue(ret, 'hardware', model.hardware);
  setMapValue(ret, 'host', model.host);
  setMapValue(ret, 'id', model.id);
  setMapValue(ret, 'manufacturer', model.manufacturer);
  setMapValue(ret, 'model', model.model);
  setMapValue(ret, 'product', model.product);
  setMapValue(ret, 'supported32BitAbis',
      codeIterable(model.supported32BitAbis, (val) => val as String));
  setMapValue(ret, 'supported64BitAbis',
      codeIterable(model.supported64BitAbis, (val) => val as String));
  setMapValue(ret, 'supportedAbis',
      codeIterable(model.supportedAbis, (val) => val as String));
  setMapValue(ret, 'tags', model.tags);
  setMapValue(ret, 'type', model.type);
  setMapValue(ret, 'isPhysicalDevice', model.isPhysicalDevice);
  setMapValue(ret, 'androidId', model.androidId);

  ret['version'] =
      "Android ${model.version.sdkInt} ${model.version.release} - ${model.version.incremental} Patch Level ${model.version.securityPatch}";
  return ret;
}

Map<String, dynamic> iosToMap(IosDeviceInfo model) {
  if (model == null) return null;
  Map<String, dynamic> ret = <String, dynamic>{};
  setMapValue(ret, 'name', model.name);
  setMapValue(ret, 'systemName', model.systemName);
  setMapValue(ret, 'systemVersion', model.systemVersion);
  setMapValue(ret, 'model', model.model);
  setMapValue(ret, 'localizedModel', model.localizedModel);
  setMapValue(ret, 'identifierForVendor', model.identifierForVendor);
  setMapValue(ret, 'isPhysicalDevice', model.isPhysicalDevice);
  return ret;
}
