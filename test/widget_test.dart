// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sdui/state.dart';
import 'package:sdui/config.dart';
import 'package:sdui/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    KoboldApi api = KoboldApi(headers: {}, baseUrl: "http://localhost:5001");
    AppState state = await createState(api: api);
    // Build our app and trigger a frame.
    await tester.pumpWidget(Main(state: state));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
