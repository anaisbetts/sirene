import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import 'package:sirene/app.dart';
import 'package:sirene/services/router.dart';

class NavigationBarButton extends StatelessWidget {
  NavigationBarButton({this.icon, this.caption, this.selected, Key key})
      : super(key: key);

  final Widget icon;
  final String caption;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (this.selected) {
      return icon;
    }

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

class RoutingNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final router = App.locator<Router>();

    final navBarHandlers =
        router.routeHandlers.where((x) => x.isBottomNav).toList();
    final currentRoute = MatchedRoute.of(context);

    if (currentRoute == null) {
      throw Exception(
          "Current route is null - did you add a custom route handler but not wrap the content in MatchedRoute?");
    }

    final selectedIndex = navBarHandlers.indexOf(currentRoute);
    final buttons = <Widget>[];
    for (var i = 0; i < navBarHandlers.length; i++) {
      var cur = navBarHandlers[i];

      buttons.add(NavigationBarButton(
          caption: cur.caption,
          icon: cur.icon(context),
          selected: selectedIndex == i));
    }

    return CurvedNavigationBar(
        backgroundColor: Theme.of(context).primaryColorDark,
        initialIndex: selectedIndex,
        onTap: (i) {
          if (selectedIndex == i) return;

          final newRoute = navBarHandlers[i].getRouteForNavigation();

          // NB: I hate this hack so much, but onTap fires *before* the transition
          // completes, not after!
          Future.delayed(Duration(milliseconds: 250)).then(
              (_) => Navigator.of(context).pushReplacementNamed(newRoute));
        },
        animationCurve: Curves.easeInOutCubic,
        animationDuration: Duration(milliseconds: 250),
        items: buttons);
  }
}

class PageBodyContainer extends StatelessWidget {
  const PageBodyContainer({@required this.child, Key key}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColorDark,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: child,
      ),
    );
  }
}
