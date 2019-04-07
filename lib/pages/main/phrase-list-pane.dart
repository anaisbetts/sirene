import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sirene/app.dart';
import 'package:sirene/interfaces.dart';
import 'package:sirene/model-lib/bindable-state.dart';
import 'package:sirene/pages/present-phrase/page.dart';
import 'package:sirene/services/logging.dart';
import 'package:sirene/services/login.dart';

class _ReplyHighlightBox extends StatelessWidget {
  final bool shouldHighlight;
  final Widget child;

  _ReplyHighlightBox({this.shouldHighlight, this.child});

  @override
  Widget build(BuildContext context) {
    if (!shouldHighlight) return child;
    return DecoratedBox(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
              color: Theme.of(context).accentColor.withOpacity(0.9),
              blurRadius: 5,
              spreadRadius: 4)
        ], borderRadius: BorderRadius.all(Radius.circular(6))),
        child: child);
  }
}

// ignore: must_be_immutable
class PhraseCard extends StatelessWidget with LoggerMixin {
  final Phrase phrase;
  final ValueNotifier<bool> replyMode;

  PhraseCard({@required this.phrase, @required this.replyMode});

  presentPhrase(BuildContext ctx) {
    logAsyncException(
        App.analytics.logEvent(name: "saved_phrase_presented", parameters: {
          "length": phrase.text.length,
          "pauseAfterFinished": false,
        }),
        rethrowIt: false);

    Navigator.of(ctx).pushNamed("/present",
        arguments: PresentPhraseOptions(
          phrase: phrase,
          pauseAfterFinished: false,
        ));

    replyMode.value = true;
  }

  Future<bool> tryDeletePhrase(BuildContext context) async {
    final shouldDelete = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text("Remove Phrase"),
              content: Text(
                "Are you sure you want to remove this phrase?",
              ),
              actions: <Widget>[
                FlatButton(
                    child: Text("Remove"),
                    onPressed: () => Navigator.of(ctx).pop(true)),
                FlatButton(
                    child: Text("Cancel"),
                    onPressed: () => Navigator.of(ctx).pop(false)),
              ],
            ));

    if (shouldDelete != true) return false;

    logAsyncException(
        App.analytics.logEvent(name: "phrase_deleted", parameters: {
          "length": phrase.text.length,
          "isReply": phrase.isReply,
        }),
        rethrowIt: false);

    App.locator.get<StorageManager>().deletePhrase(phrase);

    return true;
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

    Widget cardContents = Flex(
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
                onPressed: () => tryDeletePhrase,
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

    return Dismissible(
        key: Key(phrase.id),
        confirmDismiss: (_) => tryDeletePhrase(context),
        direction: DismissDirection.startToEnd,
        child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 64.0, maxHeight: 256.0),
            child: GestureDetector(
                onTap: () => presentPhrase(context),
                child: _ReplyHighlightBox(
                  shouldHighlight: replyMode.value && phrase.isReply,
                  child: Card(
                    elevation: 8,
                    child: cardContents,
                  ),
                ))));
  }
}

class PhraseListPane extends StatefulWidget {
  final ValueNotifier<bool> replyMode;

  PhraseListPane({@required this.replyMode});

  @override
  _PhraseListPaneState createState() => _PhraseListPaneState();
}

class _PhraseListPaneState extends BindableState<PhraseListPane>
    with UserEnabledPage, LoggerMixin {
  List<Phrase> phrases = <Phrase>[];
  final ScrollController scrollController = ScrollController();
  bool hasLoggedPhraseCount = false;

  _PhraseListPaneState() {
    setupBinds([
      () => fromValueListener(widget.replyMode)
          .skip(1)
          .listen((_) => scrollController.jumpTo(0.0))
    ]);
  }

  @override
  void initState() {
    super.initState();

    final lm = App.locator.get<LoginManager>();
    final sm = App.locator.get<StorageManager>();

    // XXX: This code won't handle logouts properly :cry:
    lm.ensureUser().then((_) async {
      sm.getPhrases().listen((xs) {
        debug("Phrase update! ${xs.length} items");

        if (App.traces.containsKey('app_startup')) {
          App.traces['app_startup'].stop();
          App.traces.remove('app_startup');
        }

        if (!hasLoggedPhraseCount && xs.length > 0) {
          logAsyncException(
              App.analytics.logEvent(
                  name: "saved_phrase_list_size",
                  parameters: {"length": xs.length}),
              rethrowIt: false);

          hasLoggedPhraseCount = true;
        }

        setState(() => phrases = xs);
      });
    });

    // Dismiss the keyboard on this pane if it's active
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  Widget build(BuildContext context) {
    final lm = App.locator.get<LoginManager>();

    if (phrases.length == 0) {
      final login = (lm.currentUser == null || lm.currentUser.email.isEmpty)
          ? RaisedButton(
              child: Text("Login via Google"),
              onPressed: () => lm.ensureNamedUser(),
            )
          : Container();

      return Flex(
        direction: Axis.vertical,
        children: <Widget>[
          Expanded(
            child: Container(),
          ),
          login,
          RaisedButton(
            child: Text("Use initial phrases"),
            onPressed: () =>
                App.locator.get<StorageManager>().loadDefaultSavedPhrases(),
          ),
          Expanded(
            child: Container(),
          )
        ],
      );
    }

    final sortedPhrases = Phrase.recencySort(phrases, widget.replyMode.value);

    final list = ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.all(16),
      itemCount: phrases.length,
      separatorBuilder: (ctx, i) => Padding(
            padding: EdgeInsets.all(8),
            child: Container(),
          ),
      itemBuilder: (ctx, i) => PhraseCard(
            phrase: sortedPhrases[i],
            replyMode: widget.replyMode,
          ),
    );

    return Flex(
      direction: Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[Expanded(child: list)],
    );
  }
}
