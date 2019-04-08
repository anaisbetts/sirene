import 'package:catcher/catcher_plugin.dart';
import 'package:flutter/material.dart';
import 'package:sirene/services/logging.dart';

import './app.dart';

final config = CatcherOptions(SilentReportMode(), [LoggingCatcherHandler()]);
//void main() => Catcher(AppWidget(), debugConfig: config, releaseConfig: config);
void main() => runApp(AppWidget());
