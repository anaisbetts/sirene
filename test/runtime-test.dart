import 'package:flutter_test/flutter_test.dart';

import 'package:get_it/get_it.dart';
import 'package:sirene/app.dart';

void main() {
  testWidgets('Make sure the test runner works', (WidgetTester tester) {
    expect(1 + 2, 3);
  });

  testWidgets('Make sure that setting up registrations ends up in test mode',
      (_) {
    var fixture = GetIt();
    App.setupRegistration(fixture);

    expect(fixture<ApplicationMode>(), ApplicationMode.Test);
  });
}
