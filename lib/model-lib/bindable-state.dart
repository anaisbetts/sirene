import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:rxdart/rxdart.dart';

typedef Subscriber<T> = StreamSubscription<T> Function();

abstract class BindableState<T extends StatefulWidget> extends State<T> {
  List<Subscriber<dynamic>> _toDispose;
  final CompositeSubscription _sub = CompositeSubscription();

  void setupBinds([List<Subscriber<dynamic>> toDispose]) {
    if (_toDispose != null) {
      throw Exception('Only initialize this once in your Constructor!');
    }

    _toDispose = toDispose;
  }

  @override
  void setState(fn) {
    // NB: We do this because we encourage people to set things up in
    // the constructor - this means that it is very easy to have a borked
    // initial call to build() since lots of people write:
    //
    // () => someObservable.listen(x => setState(() => someVar = x));
    //
    // someVar won't be set on the initial build, since setState will schedule.
    //
    // Instead, we'll change setState to setStateUnlessWeHaventInittedYet
    if (!mounted) {
      fn();
    } else {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();

    if (_toDispose == null) {
      throw Exception('Call setupBinds in your Constructor!');
    }

    for (var d in _toDispose) {
      _sub.add<dynamic>(d());
    }
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    _sub.clear();
    for (var d in _toDispose) {
      _sub.add<dynamic>(d());
    }
  }

  @override
  void dispose() {
    super.dispose();
    _sub.dispose();
  }
}

Observable<T> fromValueListener<T>(ValueListenable<T> listener) {
  // ignore: close_sinks
  Subject<T> subj = BehaviorSubject(seedValue: listener.value);

  final next = () {
    subj.add(listener.value);
  };

  subj.onCancel = () => listener.removeListener(next);
  listener.addListener(next);

  return subj;
}
