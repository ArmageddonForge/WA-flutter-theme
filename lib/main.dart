import 'dart:collection';

import 'package:flutter/gestures.dart';

//import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(const MyWidgetsApp());

class MyWidgetsApp extends StatelessWidget {
  const MyWidgetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF000000),
            Color(0xFF00008C),
          ],
        ),
      ),
      child: WidgetsApp(
        onGenerateRoute: _generateRoute,
        textStyle: const TextStyle(
          fontFamily: "Droid Sans",
        ),
        initialRoute: "/",
        color: const Color(0xFFFFFF00),
      ),
    );
  }

  Route _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case "/":
        return makePage(
          "Home Page",
          (context) => [
            WAButton(
              caption: "Go to First Page",
              onClick: () => Navigator.of(context).pushNamed("/first"),
            ),
            const Padding(padding: EdgeInsets.all(10.0)),
            WAButton(
              caption: "Invalid Route",
              onClick: () => Navigator.of(context).pushNamed("/abcd"),
            ),
            const Padding(padding: EdgeInsets.all(10.0)),
            WAButton(
              caption: "Quit",
              onClick: () => SystemNavigator.pop(),
            ),
            const Padding(padding: EdgeInsets.all(10.0)),
            const WATextEdit(),
          ],
        );
      case "/first":
        return makePage(
          "First Page",
          (context) => [
            WAButton(
              caption: "Back",
              onClick: () => Navigator.of(context).pop(),
            ),
          ],
        );
      default:
        return makePage(
          "I AM ERROR.",
          (context) => [
            WAButton(
              caption: "Back",
              onClick: () => Navigator.of(context).pop(),
            )
          ],
        );
    }
  }
}

PageRouteBuilder<dynamic> makePage(
    String title, List<Widget> Function(BuildContext) buildWidgets) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 100),
    reverseTransitionDuration: const Duration(milliseconds: 100),
    pageBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return FocusScope(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Padding(padding: EdgeInsets.all(10.0)),
              ] +
              buildWidgets(context),
        ),
      );
    },
    transitionsBuilder: myTransitionBuilder,
  );
}

Widget myTransitionBuilder(
  _,
  Animation<double> animation,
  Animation<double> second,
  Widget child,
) {
  return FadeTransition(
    opacity: animation,
    child: FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(second),
      child: child,
    ),
  );
}

class WAButton extends StatefulWidget {
  const WAButton({
    super.key,
    required this.caption,
    required this.onClick,
  });

  final String caption;
  final void Function() onClick;

  @override
  State<WAButton> createState() => _WAButtonState();
}

class _WAButtonState extends State<WAButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClick,
      child: Focus(
        child: MouseRegion(
          onEnter: (_) {
            setState(() {
              _hover = true;
            });
          },
          onExit: (_) {
            setState(() {
              _hover = false;
            });
          },
          child: Builder(
            builder: (BuildContext context) {
              final FocusNode focusNode = Focus.of(context);
              final bool hasFocus = focusNode.hasFocus;
              return Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF000000),
                  border: Border.all(
                    color: hasFocus || _hover
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF808080),
                    width: 2,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(3)),
                ),
                child: Text(
                  widget.caption,
                  style: const TextStyle(
                    color: Color(0xFF808080),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class WATextEdit extends StatefulWidget {
  const WATextEdit({
    super.key,
  });

  @override
  State<WATextEdit> createState() => _WATextEditState();
}

TextSpan transformTextSpanFragments(
  TextSpan span,
  List<int> stopPoints,
  TextSpan Function(TextRange, TextSpan) spanTransformer,
) {
  /// Copy `span`, except setting `text` to null and `children` to the given list.
  TextSpan cloneTextSpanWithChildren(TextSpan span, List<InlineSpan> children) {
    return TextSpan(
      text: null,
      children: children,
      style: span.style,
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }

  int pos = 0;
  ListQueue<int> stopPointQueue = ListQueue.of(stopPoints);
  InlineSpan visit(InlineSpan span) {
    if (span is TextSpan) {
      while (stopPointQueue.isNotEmpty && stopPointQueue.first < pos) {
        stopPointQueue.removeFirst();
      }
      if (span.text != null) {
        int end = pos + span.text!.length;
        // Fragment this TextSpan first, if necessary.
        if (stopPointQueue.isNotEmpty && stopPointQueue.first < end) {
          List<InlineSpan> children = [];
          int p0 = 0;
          while (stopPointQueue.isNotEmpty && stopPointQueue.first < end) {
            int p1 = stopPointQueue.removeFirst() - pos;
            children.add(TextSpan(text: span.text!.substring(p0, p1)));
            p0 = p1;
          }
          if (p0 < end) {
            children.add(TextSpan(text: span.text!.substring(p0, end)));
          }
          children = children + (span.children ?? []);
          return visit(cloneTextSpanWithChildren(span, children));
        }
        var start = pos;
        pos = end;
        span = spanTransformer(TextRange(start: start, end: end), span);
      } else if (span.children != null) {
        var children = List.of(span.children!.map(visit));
        span = cloneTextSpanWithChildren(span, children);
      }
    }
    return span;
  }

  return visit(span) as TextSpan;
}

class _WATextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    TextSelection selection = this.selection;
    TextSpan span = super.buildTextSpan(
        context: context, style: style, withComposing: withComposing);
    if (!selection.isCollapsed) {
      span = transformTextSpanFragments(span, [selection.start, selection.end], (TextRange range, TextSpan span) {
        if (range.start >= selection.start && range.end <= selection.end) {
          return TextSpan(
            style: const TextStyle(color: Color(0xFF000000)),
            children: [span],
          );
        }
        return span;
      });
    }
    return span;
  }
}

class _WATextEditState extends State<WATextEdit> {
  late TextEditingController controller;
  late FocusNode focusNode;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    controller = _WATextEditingController();
    focusNode = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        _hover = true;
      }),
      onExit: (_) => setState(() {
        _hover = false;
      }),
      child: Builder(
        builder: (BuildContext context) {
          final bool hasFocus = focusNode.hasFocus;
          return Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              border: Border.all(
                color: hasFocus || _hover
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF808080),
                width: 1,
              ),
            ),
            child: EditableText(
              controller: controller,
              focusNode: focusNode,
              dragStartBehavior: DragStartBehavior.down,
              style: const TextStyle(),
              cursorColor: const Color(0xFFFFFFFF),
              backgroundCursorColor: const Color(0xFF123456),
              // TODO
              selectionColor: const Color(0xFFFFFFFF),
            ),
          );
        },
      ),
    );
  }
}
