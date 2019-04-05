import 'package:flutter/material.dart';

import 'package:rx_command/rx_command.dart';

import 'package:sirene/app.dart';
import 'package:sirene/components/paged-bottom-navbar.dart';
import 'package:sirene/interfaces.dart';
import 'package:sirene/model-lib/bindable-state.dart';
import 'package:sirene/pages/main/add-phrase-bottom-sheet.dart';
import 'package:sirene/pages/main/phrase-list-pane.dart';
import 'package:sirene/pages/main/speak-pane.dart';
import 'package:sirene/services/logging.dart';
import 'package:sirene/services/login.dart';
import 'package:sirene/services/router.dart';

class _ReplyToggle extends StatefulWidget {
  final ValueNotifier<bool> replyModeToggle;

  _ReplyToggle({@required this.replyModeToggle});

  @override
  _ReplyToggleState createState() => _ReplyToggleState();
}

class _ReplyToggleState extends BindableState<_ReplyToggle> {
  var toggle = false;

  _ReplyToggleState() {
    setupBinds([
      () => fromValueListener(widget.replyModeToggle)
          .listen((x) => setState(() => toggle = x)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Flex(
        direction: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text("Replies", style: Theme.of(context).primaryTextTheme.body1),
          Switch(
              value: toggle, onChanged: (x) => widget.replyModeToggle.value = x)
        ],
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  static setupRoutes(Router r) {
    final h = Router.exactMatchFor(
        route: '/',
        builder: (_) => MainPage(),
        bottomNavCaption: "hello",
        bottomNavIcon: (c) => Icon(
              Icons.settings,
              size: 30,
            ));

    r.routeHandlers.add(h);

    return r;
  }

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends BindableState<MainPage>
    with UserEnabledPage<MainPage>, LoggerMixin {
  final PagedViewController controller = PagedViewController();

  RxCommand<dynamic, dynamic> speakPaneFab = RxCommand.createSync((_) => {});
  bool speakFabCanExecute = false;

  bool currentReplyMode;
  final ValueNotifier<bool> replyMode = ValueNotifier(false);

  _MainPageState() {
    // NB: This code sucks so hard, how can we get rid of it
    setupBinds([
      () => fromValueListener(controller.fabButton)
          .listen((x) => setState(() => speakPaneFab = x)),
      () => fromValueListener(controller.fabButton)
          .flatMap((x) => x.canExecute)
          .listen((x) => setState(() => speakFabCanExecute = x)),
      () => fromValueListener(replyMode)
          .listen((x) => setState(() => currentReplyMode = x)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final panes = <NavigationItem>[
      NavigationItem(
          icon: Icon(Icons.record_voice_over, size: 30),
          caption: "phrases",
          contents: PhraseListPane(
            replyMode: currentReplyMode,
          )),
      NavigationItem(
          icon: Icon(Icons.chat_bubble_outline, size: 30),
          caption: "speak",
          contents: SpeakPane(controller: controller)),
    ];

    final appBarActions =
        PagedViewSelector(controller: controller, children: <Widget>[
      _ReplyToggle(
        replyModeToggle: replyMode,
      ),
      Container(),
    ]);

    final appBarTitles =
        PagedViewSelector(controller: controller, children: <Widget>[
      Text(
        "Saved Phrases",
        style: Theme.of(context).primaryTextTheme.title,
      ),
      Text("Speak text")
    ]);

    final floatingActionButtons =
        PagedViewSelector(controller: controller, children: <Widget>[
      FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          // NB: This was originally envisioned as a bottom sheet but
          // https://github.com/flutter/flutter/issues/18564 throws a spanner
          // in that plan
          final newPhrase = await showDialog<Phrase>(
              context: context, builder: (ctx) => AddPhraseBottomSheet());

          if (newPhrase == null) return;
          final sm = App.locator.get<StorageManager>();

          logAsyncException(
              () => App.analytics.logEvent(name: "add_new_phrase", parameters: {
                    "length": newPhrase.text.length,
                    "isReply": newPhrase.isReply,
                  }),
              rethrowIt: false);

          await sm.upsertSavedPhrase(newPhrase, addOnly: true);
        },
      ),
      FloatingActionButton(
          child: Icon(Icons.speaker),
          backgroundColor:
              speakFabCanExecute ? null : Theme.of(context).disabledColor,
          onPressed:
              this.speakFabCanExecute ? () => speakPaneFab.execute() : null),
    ]);

    return Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
        child: Scaffold(
            appBar: AppBar(
              title: appBarTitles,
              actions: <Widget>[appBarActions],
            ),
            bottomNavigationBar: PagedViewBottomNavBar(
              items: panes,
              controller: controller,
            ),
            floatingActionButton: floatingActionButtons,
            body: PagedViewBody(
              items: panes,
              controller: controller,
            )));
  }
}
