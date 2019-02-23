import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_other_plugin_example/main.dart';

void main() {
  testWidgets('Verify Widgets', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(new MyApp());
    final Finder flatButtonPass = find.widgetWithText(RaisedButton, '保 存 屏幕截图');
    expect(flatButtonPass, findsOneWidget);
  });
}
