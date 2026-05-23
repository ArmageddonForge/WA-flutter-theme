import 'package:flutter/widgets.dart';

import 'storybook.dart';
import 'wa/widgets.dart';

void main() => runApp(const WAApp());

class WAApp extends StatelessWidget {
  const WAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      onGenerateRoute: (settings) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 100),
        reverseTransitionDuration: const Duration(milliseconds: 100),
        pageBuilder: (_, __, ___) => const DefaultTextStyle(
          style: WAFonts.body,
          child: WAStorybook(),
        ),
        transitionsBuilder: (_, animation, second, child) => FadeTransition(
          opacity: animation,
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(second),
            child: child,
          ),
        ),
      ),
      initialRoute: '/',
      color: WAColors.yellow,
    );
  }
}
