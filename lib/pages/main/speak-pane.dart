import 'package:flutter/material.dart';

class SpeakPane extends StatefulWidget {
  @override
  _SpeakPaneState createState() => _SpeakPaneState();
}

class _SpeakPaneState extends State<SpeakPane> {
  TextEditingController toSpeak;

  @override
  Widget build(BuildContext context) {
    final actualContent = Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Flex(
            direction: Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text("Phrase to say:",
                  style: Theme.of(context).primaryTextTheme.headline),
              Expanded(
                  child: TextField(
                controller: toSpeak,
              )),
            ]),
      ),
    );

    return Padding(
        padding: EdgeInsets.all(8),
        child: Flex(
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: actualContent,
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
