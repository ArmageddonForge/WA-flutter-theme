import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'disable.dart';
import 'theme.dart';

class WAListBox extends StatefulWidget {
  const WAListBox({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.width,
    this.height,
    this.enabled = true,
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double? width;
  final double? height;
  final bool enabled;

  @override
  State<WAListBox> createState() => _WAListBoxState();
}

class _WAListBoxState extends State<WAListBox> {
  @override
  Widget build(BuildContext context) {
    final bool live = widget.enabled;
    return WADisable(
      disabled: !live,
      child: Focus(
        canRequestFocus: live,
        onKeyEvent: (node, event) {
          if (!live || event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            final int next =
                (widget.selectedIndex + 1).clamp(0, widget.items.length - 1);
            if (next != widget.selectedIndex) widget.onSelected(next);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            final int next =
                (widget.selectedIndex - 1).clamp(0, widget.items.length - 1);
            if (next != widget.selectedIndex) widget.onSelected(next);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Builder(builder: (context) {
          final bool hasFocus = Focus.of(context).hasFocus;
          // Outer border is always grey in WA, regardless of focus or hover.
          // Per-row keyboard focus is shown by a dotted grey rect (see below).
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: WAColors.darkBlue,
              border: Border.all(
                color: WAColors.grey,
                width: WAMetrics.borderWidth,
              ),
            ),
            child: ListView.builder(
              itemCount: widget.items.length,
              itemExtent: WAFonts.rowHeight,
              padding: EdgeInsets.zero,
              itemBuilder: (context, i) {
                final bool selected = i == widget.selectedIndex;
                final Color bg =
                    selected ? WAColors.selectionRed : WAColors.darkBlue;
                return MouseRegion(
                  cursor: live
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: live
                        ? (_) {
                            Focus.of(context).requestFocus();
                            widget.onSelected(i);
                          }
                        : null,
                    child: CustomPaint(
                      foregroundPainter: (selected && hasFocus && live)
                          ? _DottedRectPainter(WAColors.grey)
                          : null,
                      child: Container(
                        color: bg,
                        padding: EdgeInsets.symmetric(
                          horizontal: WAMetrics.controlPadH,
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.items[i],
                          style: WAFonts.bodyOn(WAColors.white),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class _DottedRectPainter extends CustomPainter {
  _DottedRectPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = color;
    final double d = waPx(1);
    for (double x = 0; x + d <= size.width; x += d * 2) {
      canvas.drawRect(Rect.fromLTWH(x, 0, d, d), p);
      canvas.drawRect(Rect.fromLTWH(x, size.height - d, d, d), p);
    }
    for (double y = 0; y + d <= size.height; y += d * 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, d, d), p);
      canvas.drawRect(Rect.fromLTWH(size.width - d, y, d, d), p);
    }
  }

  @override
  bool shouldRepaint(_DottedRectPainter old) => old.color != color;
}
