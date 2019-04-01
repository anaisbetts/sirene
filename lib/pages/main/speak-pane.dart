import 'package:flutter/material.dart';

import 'package:rx_command/rx_command.dart';

import 'package:sirene/components/paged-bottom-navbar.dart';
import 'package:sirene/model-lib/bindable-state.dart';
import 'package:sirene/services/logging.dart';

class SpeakPane extends StatefulWidget {
  final PagedViewController controller;

  SpeakPane({this.controller});

  @override
  _SpeakPaneState createState() => _SpeakPaneState();
}

class _SpeakPaneState extends BindableState<SpeakPane> with LoggerMixin {
  TextEditingController toSpeak = TextEditingController(text: "");

  _SpeakPaneState() : super() {
    setupBinds([]);
  }

  @override
  void initState() {
    super.initState();

    final textHasContent =
        fromValueListener(toSpeak).map((x) => x.text.length > 0);

    widget.controller.fabButton.value = RxCommand.createSync(
        (_) => log("speak! ${toSpeak.text}"),
        canExecute: textHasContent);
  }

  @override
  Widget build(BuildContext context) {
    final actualContent = Flex(
        direction: Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text("Phrase to say:",
              style: Theme.of(context).primaryTextTheme.headline),
          Expanded(
              child: TextField(
            controller: toSpeak,
          )),
        ]);

    return Padding(
        padding: EdgeInsets.all(8),
        child: Flex(
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Card(
                  child: Padding(
                      padding: EdgeInsets.all(8), child: actualContent)),
              flex: 8,
            ),
            Expanded(
              flex: 1,
              child: Container(),
            )
          ],
        ));
  }
}
