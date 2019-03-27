import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:sirene/components/paged-bottom-navbar.dart';
import 'package:sirene/interfaces.dart';
import 'package:sirene/services/logging.dart';
import 'package:sirene/services/login.dart';
import 'package:sirene/services/router.dart';

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

  doSomething() async {
    withUser(requireNamed: true);
  }

  @override
  Widget build(BuildContext context) {
    final UserInfo user = withUser(requireNamed: true);
    final userName = user != null ? user.displayName : '(none!)';

    final panes = <NavigationItem>[
      NavigationItem(
        icon: Icon(Icons.settings, size: 30),
        caption: "foo",
        contents: Center(
          child: Text("hi"),
        ),
      ),
      NavigationItem(
          icon: Icon(Icons.bluetooth, size: 30),
          caption: "bar",
          contents: Center(
            child: Text("yes."),
          )),
    ];

    return Scaffold(
        appBar: AppBar(title: Text("Sirene - $userName")),
        bottomNavigationBar: PagedViewBottomNavBar(
          items: panes,
          controller: controller,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            catchToLog(() {
              throw Exception("kerplowie");
            });
          },
        ),
        body: PagedViewBody(
          items: panes,
          controller: controller,
        ));
  }
}
