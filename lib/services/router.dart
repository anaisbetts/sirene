import 'package:flutter/material.dart';

class RouteAffinity<T> {
  const RouteAffinity({@required this.affinity, this.route});

  final double affinity;
  final PageRoute<T> route;
}

class RouteHandler<T> {
  RouteHandler(
      {this.getAffinity, this.icon, this.caption, this.getRouteForNavigation});

  RouteAffinityHandler<T> getAffinity;

  // These are only required if this route should be in the bottom nav bar
  WidgetBuilder icon;
  String caption;
  String Function() getRouteForNavigation;

  bool get isBottomNav => this.icon != null && this.caption != null;
}

typedef RouteAffinityHandler<T> = RouteAffinity<T> Function(RouteSettings);

class MatchedRoute extends InheritedWidget {
  const MatchedRoute({@required this.matchedHandler, @required Widget child})
      : super(child: child);

  final RouteHandler<dynamic> matchedHandler;

  @override
  bool updateShouldNotify(MatchedRoute oldWidget) {
    return matchedHandler != oldWidget.matchedHandler;
  }

  static RouteHandler<dynamic> of(BuildContext context) {
    final MatchedRoute mr = context.inheritFromWidgetOfExactType(MatchedRoute);
    return mr.matchedHandler;
  }
}

class Router {
  final List<RouteHandler<dynamic>> routeHandlers = List();

  PageRoute<T> routeFor<T>(RouteSettings routeSettings) {
    final RouteAffinity<dynamic> aff = routeHandlers.fold(null, (acc, x) {
      final result = x.getAffinity(routeSettings);
      if (acc == null) {
        return result;
      }

      return (acc.affinity >= result.affinity ? acc : result);
    });

    return (aff != null && aff.affinity > 0.0) ? aff.route : null;
  }

  Route<dynamic> generator(RouteSettings settings) {
    return this.routeFor(settings);
  }

  static RouteHandler<void> exactMatchFor(
      {@required String route,
      @required WidgetBuilder builder,
      WidgetBuilder bottomNavIcon,
      String bottomNavCaption,
      double affinity,
      bool maintainState = true,
      bool fullscreenDialog = false}) {
    final ret = RouteHandler(
        caption: bottomNavCaption,
        icon: bottomNavIcon,
        getRouteForNavigation: () => route);

    ret.getAffinity = (settings) {
      if (settings.name != route) {
        return RouteAffinity(affinity: 0.0);
      }

      if (ret.isBottomNav && !fullscreenDialog) {
        return RouteAffinity(
            affinity: affinity ?? 1.0,
            route: PageRouteBuilder(
                pageBuilder: (ctx, _, __) =>
                    MatchedRoute(matchedHandler: ret, child: builder(ctx)),
                settings: settings,
                maintainState: maintainState));
      } else {
        return RouteAffinity(
            affinity: affinity ?? 1.0,
            route: MaterialPageRoute(
                builder: (ctx) =>
                    MatchedRoute(matchedHandler: ret, child: builder(ctx)),
                settings: settings,
                maintainState: maintainState,
                fullscreenDialog: fullscreenDialog));
      }
    };

    return ret;
  }
}
