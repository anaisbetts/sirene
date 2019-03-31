import 'package:flutter/material.dart';

class NavigationItem extends StatelessWidget {
  const NavigationItem(
      {@required this.icon, @required this.caption, @required this.contents});

  final Widget icon;
  final String caption;
  final Widget contents;

  @override
  Widget build(BuildContext context) {
    return contents;
  }
}

class PagedViewController {
  final PageController pageController = PageController();
  final ValueNotifier<int> selectionChanged = ValueNotifier(0);
}

class PagedViewBottomNavBar extends StatefulWidget {
  PagedViewBottomNavBar({@required this.items, @required this.controller}) {
    this.controller.selectionChanged.addListener(() {});
  }

  final List<NavigationItem> items;
  final PagedViewController controller;

  @override
  _PagedViewBottomNavBarState createState() => _PagedViewBottomNavBarState();
}

class _PagedViewBottomNavBarState extends State<PagedViewBottomNavBar> {
  int selectedIndex;

  @override
  void initState() {
    super.initState();

    widget.controller.selectionChanged.addListener(_pageChanged);
    selectedIndex = widget.controller.selectionChanged.value;
  }

  @override
  void didUpdateWidget(PagedViewBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    oldWidget.controller.selectionChanged.removeListener(_pageChanged);
    widget.controller.selectionChanged.addListener(_pageChanged);
    selectedIndex = widget.controller.selectionChanged.value;
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.selectionChanged.removeListener(_pageChanged);
  }

  _pageChanged() {
    setState(() => selectedIndex = widget.controller.selectionChanged.value);
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
  PagedViewBody({@required this.items, @required this.controller, Key key})
      : super(key: key);

  final List<NavigationItem> items;
  final PagedViewController controller;

  @override
  _PagedViewBodyState createState() =>
      _PagedViewBodyState(items: items, controller: controller);
}

class _PagedViewBodyState extends State<PagedViewBody> {
  _PagedViewBodyState({@required this.items, @required this.controller});

  final List<NavigationItem> items;
  final PagedViewController controller;

  @override
  void initState() {
    super.initState();

    controller.selectionChanged.addListener(_pageChanged);
  }

  @override
  void dispose() {
    super.dispose();
    controller.selectionChanged.removeListener(_pageChanged);
  }

  _pageChanged() {
    if (controller.pageController.page.floor() ==
        controller.selectionChanged.value) {
      return;
    }

    controller.pageController.animateToPage(controller.selectionChanged.value,
        curve: Curves.easeInOutCubic, duration: Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColorDark,
      child: Padding(
          padding: EdgeInsets.all(8),
          child: PageView.builder(
            controller: controller.pageController,
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            onPageChanged: (i) =>
                setState(() => controller.selectionChanged.value = i),
            itemBuilder: (ctx, i) => items[i].contents,
          )),
    );
  }
}

class PagedViewSelector extends StatefulWidget {
  PagedViewSelector(
      {@required this.children, @required this.controller, Key key})
      : super(key: key);

  final List<Widget> children;
  final PagedViewController controller;

  @override
  _PagedViewSelectorState createState() => _PagedViewSelectorState(
      children: this.children, controller: this.controller);
}

class _PagedViewSelectorState extends State<PagedViewSelector> {
  _PagedViewSelectorState({@required this.children, @required this.controller});

  final List<Widget> children;
  final PagedViewController controller;

  int selectedIndex;

  @override
  void initState() {
    super.initState();

    controller.selectionChanged.addListener(_pageChanged);
    selectedIndex = controller.selectionChanged.value;
  }

  @override
  void dispose() {
    super.dispose();
    controller.selectionChanged.removeListener(_pageChanged);
  }

  void _pageChanged() =>
      setState(() => selectedIndex = controller.selectionChanged.value);

  @override
  Widget build(BuildContext context) {
    return children[selectedIndex];
  }
}
