import 'package:flutter/widgets.dart';
import 'package:wa/wa.dart';

import 'storybook.dart';

void main() => runApp(const WAApp());

class WAApp extends StatelessWidget {
  const WAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      onGenerateRoute: (settings) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => const WATheme(child: WAStorybook()),
      ),
      initialRoute: '/',
      color: WAColors.yellow,
    );
  }
}
