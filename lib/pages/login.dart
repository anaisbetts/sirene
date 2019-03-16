import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

import 'package:sirene/app.dart';
import 'package:sirene/interfaces.dart';

class LoginPage extends StatefulWidget {
  static setupRoutes(Router r) {
    r.define("/login",
        handler: new Handler(
            type: HandlerType.route, handlerFunc: (_b, _c) => LoginPage()));
  }

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  UserInfo _currentUser;

  @override
  void initState() {
    super.initState();

    print("login!");
    LoginManager lm = App.locator<LoginManager>();
    if (lm.currentUser != null) {
      setState(() {
        print("instant login!");
        _currentUser = lm.currentUser;
      });
    } else {
      lm.login().then((u) => setState(() {
            print("delayed login!");
            _currentUser = u;
            Navigator.of(context).pop();
          }));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser != null) {
      //Navigator.of(context).pushReplacementNamed("/");
      return Center(
        child: Text("Logged in"),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: Text("Login"),
        ),
        body: Center(child: Text("Thinking about login!")));
  }
}
