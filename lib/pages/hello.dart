import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

import 'package:sirene/app.dart';
import 'package:sirene/interfaces.dart';

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

class _HelloPageState extends State<HelloPage> {
  var currentIcon = 0;

  doSomething() async {
    final LoginManager lm = App.locator<LoginManager>();
    FirebaseAnalytics track = App.locator<FirebaseAnalytics>();

    track.logLogin();

    await lm.ensureNamedUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("sandwiches."),
        ),
        bottomNavigationBar: CurvedNavigationBar(
            backgroundColor: ColorList[currentIcon],
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
            color: ColorList[currentIcon],
            child: Center(
                child: RaisedButton(
                    child: Text("Upgrade"), onPressed: doSomething))));
  }
}
