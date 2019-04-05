import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sirene/app.dart';
import 'package:sirene/interfaces.dart';
import 'package:sirene/pages/present-phrase/page.dart';
import 'package:sirene/services/logging.dart';
import 'package:sirene/services/login.dart';

// ignore: must_be_immutable
class PhraseCard extends StatelessWidget with LoggerMixin {
  PhraseCard({this.phrase});
  final Phrase phrase;

  presentPhrase(BuildContext ctx) {
    logAsyncException(
        () =>
            App.analytics.logEvent(name: "saved_phrase_presented", parameters: {
              "length": phrase.text.length,
              "pauseAfterFinished": false,
            }),
        rethrowIt: false);

    Navigator.of(ctx).pushNamed("/present",
        arguments: PresentPhraseOptions(
          text: phrase.text,
          pauseAfterFinished: false,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final shadow = TextStyle(fontStyle: FontStyle.italic, shadows: [
      Shadow(
          blurRadius: 4.0,
          offset: Offset(3.0, 3.0),
          color:
              Theme.of(context).primaryTextTheme.title.color.withOpacity(0.15))
    ]);

    final cardContents = Flex(
        direction: Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Theme.of(context).unselectedWidgetColor,
                ),
                onPressed: () {
                  log("DESTROYYYYYY");
                },
              )),
          Expanded(
              child: Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                phrase.text,
                overflow: TextOverflow.fade,
                style:
                    Theme.of(context).primaryTextTheme.display1.merge(shadow),
              ),
            ),
          )),
          SizedBox(
            height: 48,
          )
        ]);

    return ConstrainedBox(
        constraints: BoxConstraints(minHeight: 64.0, maxHeight: 256.0),
        child: GestureDetector(
          onTap: () => presentPhrase(context),
          child: Card(
            elevation: 8,
            child: cardContents,
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

    // Dismiss the keyboard on this pane if it's active
    SystemChannels.textInput.invokeMethod('TextInput.hide');
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
