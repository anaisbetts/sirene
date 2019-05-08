import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:pedantic/pedantic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirene/rx_command/rx_command.dart';
import 'package:when_rx/when_rx.dart';

import 'package:sirene/app.dart';
import 'package:sirene/components/paged-bottom-navbar.dart';
import 'package:sirene/interfaces.dart';
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
      () => fromValueListenable(widget.replyModeToggle)
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
          Text('Replies', style: Theme.of(context).primaryTextTheme.body1),
          Switch(
              value: toggle, onChanged: (x) => widget.replyModeToggle.value = x)
        ],
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  static Router setupRoutes(Router r) {
    final h = Router.exactMatchFor(
        route: '/',
        builder: (_) => MainPage(),
        bottomNavCaption: 'hello',
        bottomNavIcon: (c) => const Icon(
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
  UserInfo user;

  bool currentReplyMode;
  final ValueNotifier<bool> replyMode = ValueNotifier(false);

  _MainPageState() {
    // NB: This code sucks so hard, how can we get rid of it
    setupBinds([
      () => fromValueListenable(controller.fabButton)
          .listen((x) => setState(() => speakPaneFab = x)),
      () => fromValueListenable(controller.fabButton)
          .flatMap((x) => x.canExecute)
          .listen((x) => setState(() => speakFabCanExecute = x)),
      () => fromValueListenable(replyMode)
          .listen((x) => setState(() => currentReplyMode = x)),
      () => App.locator
          .get<LoginManager>()
          .getAuthState()
          .listen((u) => setState(() => user = u)),
    ]);
  }

  @override
  void initState() {
    super.initState();

    Future<void>.delayed(Duration(milliseconds: 250))
        .then<void>((_) => showPrivacyDialogIfNeeded());
  }

  @override
  Widget build(BuildContext context) {
    final panes = <NavigationItem>[
      NavigationItem(
          icon: const Icon(Icons.record_voice_over, size: 30),
          caption: 'phrases',
          contents: PhraseListPane(
            replyMode: replyMode,
          )),
      NavigationItem(
          icon: const Icon(Icons.chat_bubble_outline, size: 30),
          caption: 'speak',
          contents: SpeakPane(
            controller: controller,
            replyMode: replyMode,
          )),
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
        'Saved Phrases',
        style: Theme.of(context).primaryTextTheme.title,
      ),
      const Text('Speak text')
    ]);

    final floatingActionButtons =
        PagedViewSelector(controller: controller, children: <Widget>[
      FloatingActionButton(
          child: const Icon(Icons.add),
          backgroundColor:
              user != null ? null : Theme.of(context).disabledColor,
          onPressed: user != null ? onPressedAddSavedPhraseFab : null),
      FloatingActionButton(
          child: const Icon(Icons.speaker),
          backgroundColor:
              speakFabCanExecute ? null : Theme.of(context).disabledColor,
          onPressed: speakFabCanExecute ? () => speakPaneFab.execute() : null),
    ]);

    return Theme(
        data: Theme.of(context),
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

  void showPrivacyDialogIfNeeded() async {
    const privacyKey = 'seenPrivacyScreen';

    final sharedPrefs = await SharedPreferences.getInstance();
    if (sharedPrefs.containsKey(privacyKey)) {
      return;
    }

    unawaited(sharedPrefs.setBool(privacyKey, true));

    final privacyText = await rootBundle.loadString('resources/privacy.md');
    showAboutDialog(
        context: context,
        applicationName: 'Some Important Information!',
        children: <Widget>[
          MarkdownBody(
            data: privacyText,
          )
        ]);
  }

  void onPressedAddSavedPhraseFab() async {
    // NB: This was originally envisioned as a bottom sheet but
    // https://github.com/flutter/flutter/issues/18564 throws a spanner
    // in that plan
    final newPhrase = await showDialog<Phrase>(
        context: context, builder: (ctx) => AddPhraseBottomSheet());

    if (newPhrase == null) return;
    final sm = App.locator.get<StorageManager>();

    unawaited(logAsyncException(
        App.analytics
            .logEvent(name: 'add_new_phrase', parameters: <String, dynamic>{
          'length': newPhrase.text.length,
          'isReply': newPhrase.isReply,
        }),
        rethrowIt: false));

    await sm.upsertSavedPhrase(newPhrase, addOnly: true);
  }
}
