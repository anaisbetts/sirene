import 'package:flutter/material.dart';
import 'package:rx_command/rx_command.dart';
import 'package:sirene/model-lib/bindable-state.dart';

class NavigationItem extends StatelessWidget {
  final Widget icon;
  final String caption;
  final Widget contents;

  const NavigationItem(
      {@required this.icon, @required this.caption, @required this.contents});

  @override
  Widget build(BuildContext context) {
    return contents;
  }
}

class PagedViewController {
  final PageController pageController = PageController();
  final ValueNotifier<int> selectionChanged = ValueNotifier(0);

  final ValueNotifier<RxCommand<dynamic, dynamic>> fabButton =
      ValueNotifier(RxCommand.createSync((_) => {}));
}

class PagedViewBottomNavBar extends StatefulWidget {
  final List<NavigationItem> items;
  final PagedViewController controller;

  PagedViewBottomNavBar({@required this.items, @required this.controller});

  @override
  _PagedViewBottomNavBarState createState() => _PagedViewBottomNavBarState();
}

class _PagedViewBottomNavBarState extends BindableState<PagedViewBottomNavBar> {
  int selectedIndex = 0;

  _PagedViewBottomNavBarState() {
    setupBinds([
      () => fromValueListener(widget.controller.selectionChanged)
          .listen((x) => setState(() => selectedIndex = x))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <BottomNavigationBarItem>[];

    const inactiveOpacity = 0.5;
    for (var i = 0; i < widget.items.length; i++) {
      var cur = widget.items[i];

      buttons.add(BottomNavigationBarItem(
          title: Opacity(
              opacity: i == selectedIndex ? 1.0 : inactiveOpacity,
              child: Text(cur.caption)),
          icon: Opacity(opacity: inactiveOpacity, child: cur.icon),
          activeIcon: cur.icon));
    }

    return BottomNavigationBar(
        currentIndex: selectedIndex,
        items: buttons,
        backgroundColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).colorScheme.onPrimary,
        selectedItemColor: Theme.of(context).colorScheme.onPrimary,
        onTap: (i) => widget.controller.selectionChanged.value = i);
  }
}

class PagedViewBody extends StatefulWidget {
  final List<NavigationItem> items;
  final PagedViewController controller;

  PagedViewBody({@required this.items, @required this.controller, Key key})
      : super(key: key);

  @override
  _PagedViewBodyState createState() => _PagedViewBodyState();
}

class _PagedViewBodyState extends BindableState<PagedViewBody> {
  _PagedViewBodyState() {
    setupBinds([
      () => fromValueListener(widget.controller.selectionChanged)
          .listen(_pageChanged),
    ]);
  }

  _pageChanged(int page) {
    // NB: Somehow on startup this is null. How the hell that can happen,
    // I don't know.
    if (widget.controller.pageController.page == null) {
      return;
    }

    if (widget.controller.pageController.page.floor() == page) {
      return;
    }

    widget.controller.pageController.animateToPage(page,
        curve: Curves.easeInOutCubic, duration: Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColorDark,
      child: Padding(
          padding: EdgeInsets.all(8),
          child: PageView.builder(
            controller: widget.controller.pageController,
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: widget.items.length,
            onPageChanged: (i) =>
                setState(() => widget.controller.selectionChanged.value = i),
            itemBuilder: (ctx, i) => widget.items[i].contents,
          )),
    );
  }
}

class PagedViewSelector extends StatefulWidget {
  final List<Widget> children;
  final PagedViewController controller;

  PagedViewSelector(
      {@required this.children, @required this.controller, Key key})
      : super(key: key);

  @override
  _PagedViewSelectorState createState() => _PagedViewSelectorState();
}

class _PagedViewSelectorState extends BindableState<PagedViewSelector> {
  int selectedIndex = 0;

  _PagedViewSelectorState() {
    setupBinds([
      () => fromValueListener(widget.controller.selectionChanged)
          .listen((x) => setState(() => selectedIndex = x)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return widget.children[selectedIndex];
  }
}
