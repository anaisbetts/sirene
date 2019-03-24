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
  _PagedViewBottomNavBarState createState() =>
      _PagedViewBottomNavBarState(items: items, controller: controller);
}

class _PagedViewBottomNavBarState extends State<PagedViewBottomNavBar> {
  _PagedViewBottomNavBarState(
      {@required this.items, @required this.controller});

  final List<NavigationItem> items;
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

  _pageChanged() {
    setState(() => selectedIndex = controller.selectionChanged.value);
  }

  @override
  Widget build(BuildContext context) {
    final buttons = items
        .map((x) =>
            BottomNavigationBarItem(title: Text(x.caption), icon: x.icon))
        .toList();

    return BottomNavigationBar(
        currentIndex: selectedIndex,
        items: buttons,
        onTap: (i) => controller.selectionChanged.value = i);
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
