import 'package:flutter/widgets.dart';

import 'disable.dart';
import 'pressable.dart';
import 'theme.dart';

class WARadio<T> extends StatelessWidget {
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

  bool get _selected => value == groupValue;

  void _select() {
    if (!_selected) onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return WADisable(
      disabled: !enabled,
      child: WAPressable(
        enabled: enabled,
        onActivate: _select,
        // WA doesn't actually paint radio circles — only the caption is drawn.
        // We keep the circle for usability and mirror the checkbox's per-state
        // visual: hover paints white border + white dot, press fills the
        // circle grey with white outline and hides the dot, focus alone draws
        // no visible change.
        builder: (context, hover, pressed, focused) {
          final Color textColor =
              (hover || pressed) ? WAColors.white : WAColors.grey;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: Size.square(waPx(11)),
                painter: _RadioPainter(
                  selected: _selected,
                  hover: hover,
                  pressed: pressed,
                ),
              ),
              if (label != null) ...[
                SizedBox(width: WAMetrics.gap),
                Text(label!, style: WAFonts.bodyOn(textColor)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RadioPainter extends CustomPainter {
  _RadioPainter({
    required this.selected,
    required this.hover,
    required this.pressed,
  });

  final bool selected;
  final bool hover;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double r = (size.shortestSide - waPx(1)) / 2;
    final double bw = waPx(1);

    if (pressed) {
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

    final Color border = hover ? WAColors.white : WAColors.grey;
    final Color dot = hover ? WAColors.white : WAColors.grey;

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
      old.hover != hover ||
      old.pressed != pressed;
}
