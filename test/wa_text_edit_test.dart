import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa/wa.dart';

void main() {
  testWidgets('WATextEdit maxLength clamps input to specified length',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: WAColors.yellow,
        builder: (context, _) => WATheme(
          child: const Center(
            child: WATextEdit(maxLength: 5),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(WATextEdit));
    await tester.enterText(find.byType(EditableText), 'Hello World!');
    await tester.pump();

    final editableText =
        tester.widget<EditableText>(find.byType(EditableText));
    expect(editableText.controller.text.length, 5);
    expect(editableText.controller.text, 'Hello');
  });
}
