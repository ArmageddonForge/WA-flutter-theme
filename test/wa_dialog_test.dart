import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa/wa.dart';

Widget _app(WidgetBuilder pageBuilder) => WidgetsApp(
      color: WAColors.yellow,
      onGenerateRoute: (_) => PageRouteBuilder(
        pageBuilder: (context, _, __) => WATheme(child: pageBuilder(context)),
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    );

void main() {
  testWidgets('showWADialog displays dialog content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        (context) => Center(
          child: WAButton(
            caption: 'Open',
            onClick: () => showWADialog(
              context: context,
              builder: (_) => const WADialog(
                title: 'Test',
                child: Text('Hello dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Hello dialog'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
  });

  testWidgets('showWADialog dismisses on barrier tap when barrierDismissible',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        (context) => Center(
          child: WAButton(
            caption: 'Open',
            onClick: () => showWADialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => const WADialog(
                child: Text('Dismissible'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Dismissible'), findsOneWidget);

    // Tap top-left corner (outside the centered dialog) to hit the barrier.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Dismissible'), findsNothing);
  });
}
