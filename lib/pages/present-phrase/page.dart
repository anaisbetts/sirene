import 'package:flutter/material.dart';

import 'package:sirene/services/logging.dart';
import 'package:sirene/services/router.dart';

class PresentPhraseOptions {
  final String text;
  final bool pauseAfterFinished;

  PresentPhraseOptions({this.text, this.pauseAfterFinished});
}

class PresentPhrasePage extends StatefulWidget {
  static setupRoutes(Router r) {
    final h = Router.exactMatchFor(
        route: '/present',
        builder: (_) => PresentPhrasePage(),
        bottomNavCaption: "hello",
        bottomNavIcon: (c) => Icon(
              Icons.settings,
              size: 30,
            ));

    r.routeHandlers.add(h);
    return r;
  }

  @override
  _PresentPhrasePageState createState() => _PresentPhrasePageState();
}

class _PresentPhrasePageState extends State<PresentPhrasePage>
    with LoggerMixin {
  @override
  Widget build(BuildContext context) {
    final turns =
        MediaQuery.of(context).orientation == Orientation.portrait ? 1 : 0;
    PresentPhraseOptions settings = ModalRoute.of(context).settings.arguments;

    return Container(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: RotatedBox(
          quarterTurns: turns,
          child: SingleChildScrollView(
              child: Center(
            child: Text(
              settings.text,
              overflow: TextOverflow.fade,
              style: Theme.of(context)
                  .primaryTextTheme
                  .headline
                  .merge(TextStyle(fontSize: 96)),
            ),
          )),
        ),
      ),
    );
  }
}
