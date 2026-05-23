import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

class WARadio<T> extends StatefulWidget {
  const WARadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.label,
    this.enabled = true,
  });

  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final String? label;
  final bool enabled;

  @override
  State<WARadio<T>> createState() => _WARadioState<T>();
}

class _WARadioState<T> extends State<WARadio<T>> {
  bool _hover = false;
  bool _pressed = false;

  bool get _selected => widget.value == widget.groupValue;

  void _select() {
    if (!_selected) widget.onChanged(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final bool live = widget.enabled;
    return MouseRegion(
      cursor: live ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: live ? (_) => setState(() => _pressed = true) : null,
        onTapUp: live ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: live ? () => setState(() => _pressed = false) : null,
        onTap: live ? _select : null,
        child: Focus(
          canRequestFocus: live,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (live &&
                event is KeyDownEvent &&
                (event.logicalKey.keyLabel == ' ' ||
                    event.logicalKey.keyLabel == 'Enter')) {
              _select();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          // WA doesn't actually paint radio circles — only the caption is
          // drawn. We keep the circle for usability and mirror the
          // checkbox's per-state visual: hover paints white border + white
          // dot, press fills the circle grey with white outline and hides
          // the dot, focus alone draws no visible change.
          child: Builder(builder: (context) {
            final Color textColor = !live
                ? WAColors.disabledFg
                : (_hover || _pressed)
                    ? WAColors.white
                    : WAColors.grey;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: Size.square(waPx(11)),
                  painter: _RadioPainter(
                    selected: _selected,
                    enabled: live,
                    hover: _hover,
                    pressed: _pressed,
                  ),
                ),
                if (widget.label != null) ...[
                  SizedBox(width: WAMetrics.gap),
                  Text(widget.label!, style: WAFonts.bodyOn(textColor)),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _RadioPainter extends CustomPainter {
  _RadioPainter({
    required this.selected,
    required this.enabled,
    required this.hover,
    required this.pressed,
  });

  final bool selected;
  final bool enabled;
  final bool hover;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double r = (size.shortestSide - waPx(1)) / 2;
    final double bw = waPx(1);

    if (pressed && enabled) {
      // Pressed face mirrors the checkbox: circle filled with the border
      // colour (grey), outlined white, dot hidden.
      canvas.drawCircle(center, r, Paint()..color = WAColors.grey);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = WAColors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = bw,
      );
      return;
    }

    final Color border = !enabled
        ? WAColors.disabledBorder
        : hover
            ? WAColors.white
            : WAColors.grey;
    final Color dot = !enabled
        ? WAColors.disabledFg
        : hover
            ? WAColors.white
            : WAColors.grey;

    canvas.drawCircle(center, r, Paint()..color = WAColors.black);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = bw,
    );
    if (selected) {
      canvas.drawCircle(center, r - waPx(3), Paint()..color = dot);
    }
  }

  @override
  bool shouldRepaint(_RadioPainter old) =>
      old.selected != selected ||
      old.enabled != enabled ||
      old.hover != hover ||
      old.pressed != pressed;
}
