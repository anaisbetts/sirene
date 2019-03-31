import 'package:flutter/material.dart';

import 'package:sirene/components/paged-bottom-navbar.dart';
import 'package:sirene/pages/main/phrase-list.dart';
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

class _MainPageState extends State<MainPage>
    with UserEnabledPage<MainPage>, LoggerMixin {
  final PagedViewController controller = PagedViewController();

  @override
  void initState() {
    super.initState();

    debug('Starting main page!');

    userRequestError.listen((e) => {
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text("aw jeez. $e"),
          ))
        });
  }

  @override
  Widget build(BuildContext context) {
    final panes = <NavigationItem>[
      NavigationItem(
          icon: Icon(Icons.record_voice_over, size: 30),
          caption: "phrases",
          contents: PhraseListPage()),
      NavigationItem(
          icon: Icon(Icons.chat_bubble_outline, size: 30),
          caption: "speak",
          contents: Center(
            child: Text("yes."),
          )),
    ];

    final appBarActions =
        PagedViewSelector(controller: controller, children: <Widget>[
      _ReplyToggle(),
      Container(),
    ]);

    final appBarTitles =
        PagedViewSelector(controller: controller, children: <Widget>[
      Text(
        "Phrases",
        style: Theme.of(context).primaryTextTheme.title,
      ),
      Text("Text")
    ]);

    final floatingActionButtons =
        PagedViewSelector(controller: controller, children: <Widget>[
      FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => throw Exception("die die die"),
      ),
      Container()
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
