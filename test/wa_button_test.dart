import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa/wa.dart';

void main() {
  testWidgets('WAButton renders caption and fires onClick on tap',
      (WidgetTester tester) async {
    int clicks = 0;
    await tester.pumpWidget(
      WidgetsApp(
        color: WAColors.yellow,
        builder: (context, _) => WATheme(
          child: Center(
            child: WAButton(caption: 'OK', onClick: () => clicks++),
          ),
        ),
      ),
    );

    expect(find.text('OK'), findsOneWidget);
    await tester.tap(find.text('OK'));
    expect(clicks, 1);
  });
}
