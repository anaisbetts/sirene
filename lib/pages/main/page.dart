import 'package:flutter/material.dart';
import 'package:rx_command/rx_command.dart';

import 'package:sirene/components/paged-bottom-navbar.dart';
import 'package:sirene/model-lib/bindable-state.dart';
import 'package:sirene/pages/main/phrase-list-pane.dart';
import 'package:sirene/pages/main/speak-pane.dart';
import 'package:sirene/services/logging.dart';
import 'package:sirene/services/login.dart';
import 'package:sirene/services/router.dart';

class _ReplyToggle extends StatefulWidget {
  @override
  _ReplyToggleState createState() => _ReplyToggleState();
}

class _ReplyToggleState extends State<_ReplyToggle> {
  var toggle = false;

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
            value: toggle,
            onChanged: (_) => setState(() => toggle = !toggle),
          )
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

  _MainPageState() {
    // NB: This code sucks so hard, how can we get rid of it
    setupBinds([
      () => fromValueListener(controller.fabButton)
          .listen((x) => setState(() => speakPaneFab = x)),
      () => fromValueListener(controller.fabButton)
          .flatMap((x) => x.canExecute)
          .listen((x) => setState(() => speakFabCanExecute = x))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final panes = <NavigationItem>[
      NavigationItem(
          icon: Icon(Icons.record_voice_over, size: 30),
          caption: "phrases",
          contents: PhraseListPane()),
      NavigationItem(
          icon: Icon(Icons.chat_bubble_outline, size: 30),
          caption: "speak",
          contents: SpeakPane(controller: controller)),
    ];

    final appBarActions =
        PagedViewSelector(controller: controller, children: <Widget>[
      _ReplyToggle(),
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
        onPressed: () => {},
      ),
      FloatingActionButton(
          child: Icon(Icons.speaker),
          backgroundColor:
              speakFabCanExecute ? null : Theme.of(context).disabledColor,
          onPressed:
              this.speakFabCanExecute ? () => speakPaneFab.execute() : null),
    ]);

    return Scaffold(
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
        ));
  }
}
