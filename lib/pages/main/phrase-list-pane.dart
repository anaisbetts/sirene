import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';
import 'package:when_rx/when_rx.dart';

import 'package:sirene/app.dart';
import 'package:sirene/interfaces.dart';
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
        ], borderRadius: const BorderRadius.all(Radius.circular(6))),
        child: child);
  }
}

// ignore: must_be_immutable
class PhraseCard extends StatelessWidget with LoggerMixin {
  final Phrase phrase;
  final ValueNotifier<bool> replyMode;

  PhraseCard({@required this.phrase, @required this.replyMode, Key key})
      : super(key: key);

  void presentPhrase(BuildContext ctx) {
    logAsyncException(
        App.analytics.logEvent(name: 'saved_phrase_presented', parameters: {
          'length': phrase.text.length,
          'pauseAfterFinished': false,
        }),
        rethrowIt: false);

    Navigator.of(ctx).pushNamed('/present',
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
              title: const Text('Remove Phrase'),
              content: const Text(
                'Are you sure you want to remove this phrase?',
              ),
              actions: <Widget>[
                FlatButton(
                    child: const Text('Remove'),
                    onPressed: () => Navigator.of(ctx).pop(true)),
                FlatButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(ctx).pop(false)),
              ],
            ));

    if (shouldDelete != true) return false;

    unawaited(logAsyncException(
        App.analytics.logEvent(name: 'phrase_deleted', parameters: {
          'length': phrase.text.length,
          'isReply': phrase.isReply,
        }),
        rethrowIt: false));

    unawaited(App.locator.get<StorageManager>().deletePhrase(phrase));

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final shadow = TextStyle(fontStyle: FontStyle.italic, shadows: [
      Shadow(
          blurRadius: 4.0,
          offset: const Offset(3.0, 3.0),
          color:
              Theme.of(context).accentTextTheme.body1.color.withOpacity(0.15))
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
                onPressed: () => tryDeletePhrase(context),
              )),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  phrase.text,
                  overflow: TextOverflow.fade,
                  style: Theme.of(context).accentTextTheme.body1.merge(shadow),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 48,
          )
        ]);

    return Dismissible(
        key: Key(phrase.id),
        confirmDismiss: (_) => tryDeletePhrase(context),
        direction: DismissDirection.startToEnd,
        child: GestureDetector(
            onTap: () => presentPhrase(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              child: _ReplyHighlightBox(
                shouldHighlight: replyMode.value && phrase.isReply,
                child: Card(
                  elevation: 16,
                  child: cardContents,
                ),
              ),
            )));
  }
}

class _PhraseListPaneViewModel extends ViewModel {
  List<Phrase> _phrases;
}

mixin _PhraseListPaneViewModelNotify on _PhraseListPaneViewModel {
  List<Phrase> get phrases => notifyAccessed('phrases', _phrases);
  set phrases(List<Phrase> p) =>
      notifyAndSet('phrases', _phrases, () => _phrases = p);
}

class PhraseListPaneViewModel extends _PhraseListPaneViewModel
    with _PhraseListPaneViewModelNotify {
  bool hasLoggedPhraseCount = false;
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
    final lm = App.locator.get<LoginManager>();
    final sm = App.locator.get<StorageManager>();

    setupBinds([
      () => fromValueListenable(widget.replyMode)
          .skip(1)
          .listen((_) => scrollController.jumpTo(0.0)),
      () => lm
              .getAuthState()
              .switchMap((u) => u != null
                  ? sm.getPhrases(forUser: u)
                  : Observable.just(<Phrase>[]))
              .listen((xs) {
            if (App.traces.containsKey('app_startup')) {
              App.traces['app_startup'].stop();
              App.traces.remove('app_startup');
            }

            if (!hasLoggedPhraseCount && xs.isNotEmpty) {
              unawaited(logAsyncException(
                  App.analytics.logEvent(
                      name: 'saved_phrase_list_size',
                      parameters: {'length': xs.length}),
                  rethrowIt: false));

              hasLoggedPhraseCount = true;
            }

            setState(() => phrases = xs);
          })
    ]);
  }

  @override
  void initState() {
    super.initState();

    // Dismiss the keyboard on this pane if it's active
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  Widget build(BuildContext context) {
    final lm = App.locator.get<LoginManager>();

    if (phrases.isEmpty) {
      final loginOrInitialPhrases = (lm.currentUser == null ||
              lm.currentUser.email == null ||
              lm.currentUser.email.isEmpty)
          ? RaisedButton.icon(
              icon: const Icon(Icons.account_circle),
              label: const Text('Login via Google'),
              onPressed: lm.ensureNamedUser,
            )
          : RaisedButton.icon(
              icon: const Icon(Icons.playlist_add),
              label: const Text('Add initial phrases'),
              onPressed: () =>
                  App.locator.get<StorageManager>().loadDefaultSavedPhrases(),
            );

      return Flex(
        direction: Axis.vertical,
        children: <Widget>[
          Expanded(
            child: Container(),
          ),
          loginOrInitialPhrases,
          Expanded(
            child: Container(),
          )
        ],
      );
    }

    final sortedPhrases = Phrase.recencySort(phrases, widget.replyMode.value);

    final list = GridView.builder(
      controller: scrollController,
      shrinkWrap: true,
      itemCount: phrases.length,
      padding: const EdgeInsets.all(8),
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      itemBuilder: (ctx, i) => PhraseCard(
            key: Key(sortedPhrases[i].text),
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
