import 'package:flutter/widgets.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:sirene/app.dart';
import 'package:sirene/interfaces.dart';

void main() {
  FlutterError.onError = (details) {
    var isDebug = false;
    assert(isDebug = true);

    if (isDebug) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      final user = App.locator != null
          ? App.locator.get<LoginManager>().currentUser
          : null;

      if (user != null) {
        Crashlytics.instance.setUserIdentifier(user.uid);
        Crashlytics.instance.setUserEmail(user.email);
      }

      Crashlytics.instance.onError(details);
    }
  };

  runApp(AppWidget());
}
