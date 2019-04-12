import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rx_command/rx_command.dart';
import 'package:sirene/app.dart';

import 'package:sirene/components/paged-bottom-navbar.dart';
import 'package:sirene/interfaces.dart';
import 'package:sirene/model-lib/bindable-state.dart';
import 'package:sirene/pages/present-phrase/page.dart';
import 'package:sirene/services/logging.dart';

class FuzzyMatchChipList extends StatefulWidget {
  final TextEditingController textController;
  final RxCommand<PresentPhraseOptions, void> presentPhrase;

  FuzzyMatchChipList(
      {@required this.textController, @required this.presentPhrase});

  @override
  _FuzzyMatchChipListState createState() => _FuzzyMatchChipListState();
}

class _FuzzyMatchChipListState extends BindableState<FuzzyMatchChipList> {
  List<Phrase> currentPhraseList = [];
  String searchText = '';

  _FuzzyMatchChipListState() {
    final sm = App.locator.get<StorageManager>();

    setupBinds([
      () => sm
          .getPhrases()
          .listen((xs) => setState(() => currentPhraseList = xs)),
      () => fromValueListener(widget.textController)
          .listen((x) => setState(() => searchText = x.text))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (searchText.isEmpty || searchText.length < 1) return Container();

    final stLower = searchText.toLowerCase();
    final toPresent = Phrase.recencySort(
            currentPhraseList
                .where((p) => p.text.toLowerCase().contains(stLower))
                .toList(),
            true)
        .take(4);

    final chips = toPresent
        .map((p) => ActionChip(
              key: Key(p.text),
              label: Container(
                constraints:
                    BoxConstraints(maxWidth: toPresent.length > 2 ? 128 : 512),
                child: Text(
                  p.text,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
              onPressed: () => widget.presentPhrase.execute(
                  PresentPhraseOptions(phrase: p, pauseAfterFinished: false)),
            ))
        .toList();

    return Wrap(
      children: chips,
      spacing: 8,
    );
  }
}

class SpeakPane extends StatefulWidget {
  final PagedViewController controller;
  final ValueNotifier<bool> replyMode;

  SpeakPane({@required this.controller, @required this.replyMode});

  @override
  _SpeakPaneState createState() => _SpeakPaneState();
}

class _SpeakPaneState extends State<SpeakPane> with LoggerMixin {
  TextEditingController toSpeak;
  FocusNode textBoxFocus;
  RxCommand<PresentPhraseOptions, void> quickFindPresent;

  bool pauseAfterFinished = false;

  @override
  void initState() {
    super.initState();

    toSpeak = TextEditingController();
    textBoxFocus = FocusNode();

    final textHasContent =
        fromValueListener(toSpeak).map((x) => x.text.length > 0);

    widget.controller.fabButton.value = RxCommand.createAsync((_) async {
      logAsyncException(
          App.analytics.logEvent(name: "custom_phrase_presented", parameters: {
            "length": toSpeak.text.length,
            "pauseAfterFinished": pauseAfterFinished,
          }),
          rethrowIt: false);

      widget.replyMode.value = true;

      await Navigator.of(context).pushNamed("/present",
          arguments: PresentPhraseOptions(
              phrase: Phrase(text: toSpeak.text, isReply: false),
              pauseAfterFinished: pauseAfterFinished));

      FocusScope.of(context).requestFocus(textBoxFocus);
    }, canExecute: textHasContent);

    quickFindPresent = RxCommand.createAsync((p) async {
      logAsyncException(
          App.analytics
              .logEvent(name: "quickfind_phrase_presented", parameters: {
            "length": p.phrase.text.length,
          }),
          rethrowIt: false);

      widget.replyMode.value = true;

      await Navigator.of(context).pushNamed("/present", arguments: p);
      FocusScope.of(context).requestFocus(textBoxFocus);
    });

    final sm = App.locator.get<StorageManager>();
    logAsyncException(
        sm.getCustomPhrase().then((s) => setState(() {
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
    toSpeak.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(this.context).reparentIfNeeded(textBoxFocus);

    final actualContent = Flex(
        direction: Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text("Phrase to say:", style: Theme.of(context).textTheme.headline),
          Expanded(
              child: TextField(
            autofocus: true,
            controller: toSpeak,
            focusNode: textBoxFocus,
            minLines: 1,
            maxLines: 5,
          )),
          FuzzyMatchChipList(
            textController: toSpeak,
            presentPhrase: quickFindPresent,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: RaisedButton(
                child: Text("Clear"),
                onPressed: () {
                  SystemChannels.textInput.invokeMethod('TextInput.show');
                  toSpeak.clear();
                  FocusScope.of(this.context).requestFocus(textBoxFocus);
                }),
          ),
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
                )
              ])
        ]);

    return Padding(
        padding: EdgeInsets.all(4),
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
