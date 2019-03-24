import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:sirene/components/navigation-navbar.dart';
import 'package:sirene/services/login.dart';
import 'package:sirene/services/router.dart';

class HelloPage extends StatefulWidget {
  static setupRoutes(Router r) {
    final h = Router.exactMatchFor(
        route: '/',
        builder: (_) => HelloPage(),
        bottomNavCaption: "hello",
        bottomNavIcon: (c) => Icon(
              Icons.settings,
              size: 30,
            ));

    r.routeHandlers.add(h);

    return r;
  }

  @override
  _HelloPageState createState() => _HelloPageState();
}

class _HelloPageState extends State<HelloPage> with UserEnabledPage<HelloPage> {
  var currentIcon = 0;

  @override
  void initState() {
    super.initState();

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
    final UserInfo user = withUser();
    final userName = user != null ? user.displayName : '(none!)';

    return Scaffold(
        appBar: AppBar(title: Text("Sirene - $userName")),
        bottomNavigationBar: RoutingNavigationBar(),
        body: PageBodyContainer(
            child: Center(
                child: RaisedButton(
                    child: Text("Upgrade"), onPressed: doSomething))));
  }
}
