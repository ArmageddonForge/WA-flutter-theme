import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa/wa.dart';

void main() {
  testWidgets('WATable renders rows and fires onSelected on tap',
      (WidgetTester tester) async {
    int? selected;
    await tester.pumpWidget(
      WidgetsApp(
        color: WAColors.yellow,
        builder: (context, _) => WATheme(
          child: Center(
            child: WATable(
              width: waPx(200),
              height: waPx(150),
              columns: [
                const WATableColumn(flex: 1),
                const WATableColumn(flex: 1),
              ],
              rowCount: 3,
              rowBuilder: (context, i) => WATableRow(
                cells: [
                  Text('Row $i A'),
                  Text('Row $i B'),
                ],
              ),
              selectedIndex: selected,
              onSelected: (i) => selected = i,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Row 0 A'), findsOneWidget);
    expect(find.text('Row 1 A'), findsOneWidget);
    expect(find.text('Row 2 A'), findsOneWidget);

    await tester.tap(find.text('Row 1 A'));
    expect(selected, 1);
  });
}
