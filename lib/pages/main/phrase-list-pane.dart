import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:sirene/app.dart';
import 'package:sirene/interfaces.dart';
import 'package:sirene/pages/present-phrase/page.dart';
import 'package:sirene/services/logging.dart';
import 'package:sirene/services/login.dart';

final TextStyle italics = TextStyle(fontStyle: FontStyle.italic);

class PhraseCard extends StatelessWidget {
  PhraseCard({this.phrase});
  final Phrase phrase;

  @override
  Widget build(BuildContext context) {
    final shadow = TextStyle(shadows: [
      Shadow(
          blurRadius: 4.0,
          offset: Offset(3.0, 3.0),
          color:
              Theme.of(context).primaryTextTheme.title.color.withOpacity(0.15))
    ]);

    return ConstrainedBox(
        constraints: BoxConstraints(minHeight: 64.0, maxHeight: 256.0),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pushNamed("/present",
              arguments: PresentPhraseOptions(
                text: phrase.text,
                pauseAfterFinished: false,
              )),
          child: Card(
            elevation: 8,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  phrase.text,
                  overflow: TextOverflow.fade,
                  style: Theme.of(context)
                      .primaryTextTheme
                      .display1
                      .merge(italics)
                      .merge(shadow),
                ),
              ),
            ),
          ),
        ));
  }
}

class PhraseListPane extends StatefulWidget {
  @override
  _PhraseListPaneState createState() => _PhraseListPaneState();
}

class _PhraseListPaneState extends State<PhraseListPane>
    with UserEnabledPage, LoggerMixin {
  bool replyMode = false;
  List<Phrase> phrases = <Phrase>[];

  @override
  void initState() {
    super.initState();

    final lm = App.locator.get<LoginManager>();
    final sm = App.locator.get<StorageManager>();

    // XXX: This code won't handle logouts properly :cry:
    lm.ensureUser().then((_) async {
      sm.getPhrases().listen((xs) {
        debug("Phrase update! ${xs.length} items");
        setState(() => phrases = xs);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (phrases.length == 0) {
      return Center(
        child: RaisedButton(
          child: Text("Login"),
          onPressed: () => App.locator.get<LoginManager>().ensureNamedUser(),
        ),
      );
    }

    final list = ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: phrases.length,
      separatorBuilder: (ctx, i) => Padding(
            padding: EdgeInsets.all(8),
            child: Container(),
          ),
      itemBuilder: (ctx, i) => PhraseCard(
            phrase: phrases[i],
          ),
    );

    return Flex(
      direction: Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[Expanded(child: list)],
    );
  }
}
