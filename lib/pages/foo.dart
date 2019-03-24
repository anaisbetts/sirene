import 'package:flutter/material.dart';

import 'package:sirene/components/navigation-navbar.dart';
import 'package:sirene/services/login.dart';
import 'package:sirene/services/router.dart';

class FooPage extends StatefulWidget {
  static setupRoutes(Router r) {
    final h = Router.exactMatchFor(
        route: '/foo',
        builder: (_) => FooPage(),
        bottomNavCaption: "foo",
        bottomNavIcon: (c) => Icon(
              Icons.settings_bluetooth,
              size: 30,
            ));

    r.routeHandlers.add(h);

    return r;
  }

  @override
  _HelloPageState createState() => _HelloPageState();
}

class _HelloPageState extends State<FooPage> with UserEnabledPage<FooPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Sirene")),
        //bottomNavigationBar: RoutingNavigationBar(),
        body: PageBodyContainer(
            child: Center(
                child: RaisedButton(
          child: Text("leave"),
          onPressed: () => Navigator.of(context).pop(),
        ))));
  }
}
