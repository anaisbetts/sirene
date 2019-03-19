import 'package:flutter/material.dart';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluro/fluro.dart';

import 'package:sirene/services/login.dart';

const ColorList = [
  Colors.redAccent,
  Colors.greenAccent,
  Colors.blueAccent,
];

class NavigationBarButton extends StatelessWidget {
  NavigationBarButton({this.icon, this.caption, this.selected});

  final Widget icon;
  final String caption;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (this.selected) {
      return icon;
    } else {
      return Padding(
          padding: EdgeInsets.only(top: 8),
          child: Column(
            children: <Widget>[
              icon,
              Text(caption, style: Theme.of(context).textTheme.caption),
            ],
          ));
    }
  }
}

class HelloPage extends StatefulWidget {
  static setupRoutes(Router r) {
    r.define("/",
        handler: new Handler(
            type: HandlerType.route, handlerFunc: (_b, _c) => HelloPage()));

    return r;
  }

  @override
  _HelloPageState createState() => _HelloPageState();
}

class _HelloPageState extends State<HelloPage> with UserEnabledPage<HelloPage> {
  var currentIcon = 0;

  doSomething() async {
    withUser(requireNamed: true);
  }

  @override
  Widget build(BuildContext context) {
    final UserInfo user = withUser();
    final userName = user != null ? user.displayName : '(none!)';

    return Scaffold(
        appBar: AppBar(title: Text("Sirene - $userName")),
        bottomNavigationBar: CurvedNavigationBar(
            backgroundColor: Theme.of(context).primaryColorDark,
            initialIndex: currentIcon,
            onTap: (i) {
              setState(() {
                currentIcon = i;
              });
            },
            animationCurve: Curves.easeInOutCubic,
            animationDuration: Duration(milliseconds: 250),
            items: <Widget>[
              NavigationBarButton(
                caption: "alarm",
                icon: Icon(Icons.access_alarm, size: 30),
                selected: currentIcon == 0,
              ),
              NavigationBarButton(
                caption: "account",
                icon: Icon(Icons.account_balance, size: 30),
                selected: currentIcon == 1,
              ),
              NavigationBarButton(
                caption: "fly",
                icon: Icon(Icons.airline_seat_legroom_extra, size: 30),
                selected: currentIcon == 2,
              ),
            ]),
        body: Container(
            color: Theme.of(context).primaryColorDark,
            child: Center(
                child: RaisedButton(
                    child: Text("Upgrade"), onPressed: doSomething))));
  }
}
