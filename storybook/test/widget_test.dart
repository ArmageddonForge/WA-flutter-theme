import 'package:flutter_test/flutter_test.dart';

import 'package:wa_storybook/main.dart';

void main() {
  testWidgets('WAApp builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const WAApp());
    expect(find.text('Controls'), findsOneWidget);
  });
}
