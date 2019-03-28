import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:sirene/app.dart';
import 'package:sirene/interfaces.dart';
import 'package:sirene/services/logging.dart';
import 'package:sirene/services/login.dart';

class _ReplyAndHeading extends StatefulWidget {
  @override
  _ReplyAndHeadingState createState() => _ReplyAndHeadingState();
}

class _ReplyAndHeadingState extends State<_ReplyAndHeading> {
  var toggle = false;

  @override
  Widget build(BuildContext context) {
    final shadow = TextStyle(shadows: [
      Shadow(
          blurRadius: 5.0,
          offset: Offset(3.0, 3.0),
          color: Theme.of(context).primaryColorLight.withOpacity(0.2))
    ]);

    return Flex(
      direction: Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          child: Text("Phrases",
              style: Theme.of(context).primaryTextTheme.title.merge(shadow)),
        ),
        Expanded(
          child: Container(),
        ),
        Text("Replies", style: Theme.of(context).primaryTextTheme.body1),
        Switch(
          value: toggle,
          onChanged: (_) => setState(() => toggle = !toggle),
        )
      ],
    );
  }
}

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
              Theme.of(context).primaryTextTheme.title.color.withOpacity(0.2))
    ]);

    return ConstrainedBox(
        constraints: BoxConstraints(minHeight: 64.0, maxHeight: 256.0),
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
        ));
  }
}

class PhraseListPage extends StatefulWidget {
  @override
  _PhraseListPageState createState() => _PhraseListPageState();
}

class _PhraseListPageState extends State<PhraseListPage>
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
      //final docs = await sm.allPhrasesQuery().getDocuments();
      //setState(() =>
      //   phrases = docs.documents.map((x) => Phrase.fromDocument(x)).toList());
      sm.getPhrases().listen((xs) {
        debug("Phrase update! ${xs.length} items");
        setState(() => phrases = xs);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(4),
        ),
        _ReplyAndHeading(),
        Expanded(
            child: Padding(
                padding: EdgeInsets.all(8),
                child: ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: phrases.length,
                  itemBuilder: (ctx, i) => PhraseCard(
                        phrase: phrases[i],
                      ),
                )))
      ],
    );
  }
}
