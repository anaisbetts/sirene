import 'package:flutter/material.dart';
import 'package:sirene/interfaces.dart';
import 'package:sirene/model-lib/bindable-state.dart';

class AddPhraseBottomSheet extends StatefulWidget {
  @override
  _AddPhraseBottomSheetState createState() => _AddPhraseBottomSheetState();
}

class _AddPhraseBottomSheetState extends BindableState<AddPhraseBottomSheet> {
  TextEditingController toSpeak = TextEditingController(text: '');

  FocusNode textBoxFocus = FocusNode();
  bool isReply = false;
  bool hasText = false;

  _AddPhraseBottomSheetState() {
    setupBinds([
      () => fromValueListener(toSpeak)
          .map((x) => x.text.isNotEmpty)
          .listen((x) => setState(() => hasText = x))
    ]);
  }

  @override
  void initState() {
    super.initState();

    // NB: Make sure the keyboard gets shown once the dialog is initially
    // popped
    Future<void>.delayed(Duration(milliseconds: 10))
        .then((_) => FocusScope.of(context).requestFocus(textBoxFocus));
  }

  @override
  Widget build(BuildContext context) {
    final actualContent = Flex(
        direction: Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Phrase to say:', style: Theme.of(context).textTheme.headline),
          TextField(
            controller: toSpeak,
            focusNode: textBoxFocus,
            minLines: 1,
            maxLines: 10,
          ),
          Flex(
              direction: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Switch(
                  value: isReply,
                  onChanged: (x) => setState(() => isReply = x),
                ),
                Text(
                  'Treat this phrase as a Reply',
                  style: Theme.of(context).textTheme.body1,
                )
              ]),
          Expanded(
            child: Container(),
          ),
          RaisedButton(
              child: const Text('Ok'),
              onPressed: !hasText
                  ? null
                  : () => Navigator.pop(
                      context, Phrase(text: toSpeak.text, isReply: isReply)))
        ]);

    return Dialog(
      child: Padding(padding: const EdgeInsets.all(8), child: actualContent),
    );
  }
}
