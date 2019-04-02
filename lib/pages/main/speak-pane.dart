import 'package:flutter/material.dart';

import 'package:rx_command/rx_command.dart';
import 'package:sirene/app.dart';

import 'package:sirene/components/paged-bottom-navbar.dart';
import 'package:sirene/interfaces.dart';
import 'package:sirene/model-lib/bindable-state.dart';
import 'package:sirene/pages/present-phrase/page.dart';
import 'package:sirene/services/logging.dart';

class SpeakPane extends StatefulWidget {
  final PagedViewController controller;

  SpeakPane({this.controller});

  @override
  _SpeakPaneState createState() => _SpeakPaneState();
}

class _SpeakPaneState extends State<SpeakPane> with LoggerMixin {
  TextEditingController toSpeak = TextEditingController(text: "");
  FocusNode textBoxFocus = FocusNode();

  bool pauseAfterFinished = false;

  @override
  void initState() {
    super.initState();

    final textHasContent =
        fromValueListener(toSpeak).map((x) => x.text.length > 0);

    widget.controller.fabButton.value = RxCommand.createSync((_) {
      logAsyncException(
          () => App.analytics
                  .logEvent(name: "custom_phrase_presented", parameters: {
                "length": toSpeak.text.length,
                "pauseAfterFinished": pauseAfterFinished,
              }),
          rethrowIt: false);

      // NB: If writing the custom phrase fails, we don't care, we're just
      // letting it go
      final sm = App.locator.get<StorageManager>();
      logAsyncException(() => sm.saveCustomPhrase(toSpeak.text),
          rethrowIt: false, message: "Failed to fetch custom phrase");

      Navigator.of(context).pushNamed("/present",
          arguments: PresentPhraseOptions(
              text: toSpeak.text, pauseAfterFinished: pauseAfterFinished));
    }, canExecute: textHasContent);

    final sm = App.locator.get<StorageManager>();
    logAsyncException(
        () => sm.getCustomPhrase().then((s) => setState(() {
              if (s != null && toSpeak.text.isEmpty) {
                toSpeak.text = s;
                toSpeak.selection =
                    TextSelection(baseOffset: 0, extentOffset: s.length);
              }
            })),
        rethrowIt: false,
        message: "Failed to get saved custom phrase");

    Future.delayed(Duration(milliseconds: 5))
        .then((_) => FocusScope.of(context).requestFocus(textBoxFocus));
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.fabButton.value.dispose();
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
            focusNode: textBoxFocus,
          )),
          Flex(
              direction: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Switch(
                  value: pauseAfterFinished,
                  onChanged: (x) => setState(() => pauseAfterFinished = x),
                ),
                Text(
                  "Pause after phrase is complete",
                  maxLines: 10,
                  softWrap: true,
                  style: Theme.of(context).primaryTextTheme.body1,
                )
              ])
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
