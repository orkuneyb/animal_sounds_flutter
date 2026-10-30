import 'package:animal_sounds_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the parent alert is shown at most once per launch',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    MyApp.resetParentAlertForTesting();
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        context = c;
        return const SizedBox();
      }),
    ));

    // Two requests in the same launch, as a navigator rebuild would cause.
    const app = MyApp();
    final first = app.showParentAlert(context);
    final second = app.showParentAlert(context);
    await tester.pump();
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    await first;
    await second;
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('accepting the offer never throws when the notification plugin is missing',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    MyApp.resetParentAlertForTesting();
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        context = c;
        return const SizedBox();
      }),
    ));

    final shown = const MyApp().showParentAlert(context);
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    await expectLater(shown, completes);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reminder_offer_shown'), isTrue);
  });
}
