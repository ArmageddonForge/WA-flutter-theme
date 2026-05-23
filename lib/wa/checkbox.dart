import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

class WACheckbox extends StatefulWidget {
  const WACheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.enabled = true,
  });

  /// `null` is the indeterminate (tri-state) value, shown as a hashed tick.
  /// Clicking an indeterminate checkbox transitions to `true`.
  final bool? value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final bool enabled;

  @override
  State<WACheckbox> createState() => _WACheckboxState();
}

class _WACheckboxState extends State<WACheckbox> {
  bool _hover = false;
  bool _pressed = false;

  void _toggle() => widget.onChanged(widget.value != true);

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
        onTap: live ? _toggle : null,
        child: Focus(
          canRequestFocus: live,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (live &&
                event is KeyDownEvent &&
                (event.logicalKey.keyLabel == ' ' ||
                    event.logicalKey.keyLabel == 'Enter')) {
              _toggle();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          // WA: keyboard focus draws no visible change. Hover (Highlighted)
          // and press (Pressed) each have distinct faces; both render
          // caption white.
          child: Builder(builder: (context) {
            final bool emphasis = live && (_hover || _pressed);
            final Color textColor = !live
                ? WAColors.disabledFg
                : emphasis
                    ? WAColors.white
                    : WAColors.grey;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: Size.square(waPx(10)),
                  painter: _CheckboxPainter(
                    value: widget.value,
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

class _CheckboxPainter extends CustomPainter {
  _CheckboxPainter({
    required this.value,
    required this.enabled,
    required this.hover,
    required this.pressed,
  });

  final bool? value;
  final bool enabled;
  final bool hover;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final double bw = waPx(1);
    final Color border = !enabled
        ? WAColors.disabledBorder
        : (hover || pressed)
            ? WAColors.white
            : WAColors.grey;
    final Color tickColor =
        !enabled ? WAColors.disabledFg : (hover ? WAColors.white : WAColors.grey);

    final Rect outer = Rect.fromLTWH(
      bw / 2,
      bw / 2,
      size.width - bw,
      size.height - bw,
    );

    if (pressed && enabled) {
      // Pressed face: outer rect filled with border color (grey), outline
      // white, tick hidden.
      canvas.drawRect(outer, Paint()..color = WAColors.grey);
      canvas.drawRect(
        outer,
        Paint()
          ..color = WAColors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = bw,
      );
      return;
    }

    canvas.drawRect(outer, Paint()..color = WAColors.black);
    canvas.drawRect(
      outer,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = bw,
    );

    if (value == false) return;

    // Solid inner square: 1px border + 2px pad + 4px tick + 2px pad + 1px border.
    final double pad = waPx(3);
    final Rect tick = Rect.fromLTWH(
      pad,
      pad,
      size.width - pad * 2,
      size.height - pad * 2,
    );
    canvas.drawRect(tick, Paint()..color = tickColor);

    if (value == null) {
      // Indeterminate: hash the tick rect with transparent (dither). Half the
      // 1-px cells of the tick get painted black so the underlying tick
      // color shows through as a checkerboard pattern.
      final Paint hashPaint = Paint()..color = WAColors.black;
      final double cell = waPx(1);
      final int cols = (tick.width / cell).floor();
      final int rows = (tick.height / cell).floor();
      for (int gy = 0; gy < rows; gy++) {
        for (int gx = 0; gx < cols; gx++) {
          if (((gx + gy) & 1) == 0) continue;
          canvas.drawRect(
            Rect.fromLTWH(
              tick.left + gx * cell,
              tick.top + gy * cell,
              cell,
              cell,
            ),
            hashPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CheckboxPainter old) =>
      old.value != value ||
      old.enabled != enabled ||
      old.hover != hover ||
      old.pressed != pressed;
}
