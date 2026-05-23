import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'disable.dart';
import 'theme.dart';

/// Horizontal scrollbar-style value control. WA uses this widget shape for
/// any continuous-value picker (its true "slider" widget is implemented in
/// the game but never instantiated). Diverges from the game's scrollbar by
/// adding hover/focus border feedback so keyboard navigation has a visible
/// active state.
class WAScrollbar extends StatefulWidget {
  const WAScrollbar({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.width,
    this.enabled = true,
  });

  final double value;
  final double min;
  final double max;

  /// If null, the keyboard/arrow-button step is `(max - min) / 20` and drag is continuous.
  /// If set, drag snaps to the same N divisions.
  final int? divisions;
  final double? width;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  State<WAScrollbar> createState() => _WAScrollbarState();
}

class _WAScrollbarState extends State<WAScrollbar> {
  bool _hover = false;
  bool _dragging = false;

  double get _t =>
      ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  double get _step => (widget.max - widget.min) / (widget.divisions ?? 20);

  void _setFromT(double t) {
    if (widget.divisions != null && widget.divisions! > 0) {
      t = (t * widget.divisions!).round() / widget.divisions!;
    }
    t = t.clamp(0.0, 1.0);
    final double v = widget.min + t * (widget.max - widget.min);
    if (v != widget.value) widget.onChanged(v);
  }

  void _stepBy(double delta) {
    final double v = (widget.value + delta).clamp(widget.min, widget.max);
    if (v != widget.value) widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final bool live = widget.enabled;
    return WADisable(
      disabled: !live,
      child: MouseRegion(
        cursor: live ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Focus(
          canRequestFocus: live,
          onKeyEvent: (node, event) {
            if (!live || event is! KeyDownEvent) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _stepBy(-_step);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _stepBy(_step);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Builder(builder: (context) {
            final bool hasFocus = Focus.of(context).hasFocus;
            final Color border = hasFocus
                ? WAColors.yellow
                : (_hover || _dragging)
                    ? WAColors.white
                    : WAColors.grey;
            return SizedBox(
              width: widget.width,
              height: waPx(18),
              child: Row(
                children: [
                  _ScrollbarButton(
                    dir: _ArrowDir.left,
                    border: border,
                    onTap: () {
                      Focus.of(context).requestFocus();
                      _stepBy(-_step);
                    },
                  ),
                  Expanded(
                    child: _ScrollbarTrack(
                      t: _t,
                      border: border,
                      dragging: _dragging,
                      onTapDown: (t) {
                        Focus.of(context).requestFocus();
                        _setFromT(t);
                      },
                      onDragStart: () => setState(() => _dragging = true),
                      onDragUpdate: _setFromT,
                      onDragEnd: () => setState(() => _dragging = false),
                    ),
                  ),
                  _ScrollbarButton(
                    dir: _ArrowDir.right,
                    border: border,
                    onTap: () {
                      Focus.of(context).requestFocus();
                      _stepBy(_step);
                    },
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

enum _ArrowDir { left, right }

class _ScrollbarButton extends StatefulWidget {
  const _ScrollbarButton({
    required this.dir,
    required this.border,
    required this.onTap,
  });

  final _ArrowDir dir;
  final Color border;
  final VoidCallback onTap;

  @override
  State<_ScrollbarButton> createState() => _ScrollbarButtonState();
}

class _ScrollbarButtonState extends State<_ScrollbarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final BorderSide side = BorderSide(color: widget.border, width: waPx(1));
    // Omit the edge that abuts the track so the shared seam is 1px, not 2px.
    final Border box = Border(
      top: side,
      bottom: side,
      left: widget.dir == _ArrowDir.left ? side : BorderSide.none,
      right: widget.dir == _ArrowDir.right ? side : BorderSide.none,
    );
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        widget.onTap();
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: Container(
        width: waPx(13),
        height: waPx(18),
        decoration: BoxDecoration(color: WAColors.black, border: box),
        child: Center(
          child: Transform.translate(
            offset: Offset(0, _pressed ? waPx(1) : 0),
            child: CustomPaint(
              size: Size(waPx(4), waPx(8)),
              painter: _ArrowPainter(dir: widget.dir, color: WAColors.grey),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.dir, required this.color});
  final _ArrowDir dir;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path();
    if (dir == _ArrowDir.left) {
      p.moveTo(size.width, 0);
      p.lineTo(size.width, size.height);
      p.lineTo(0, size.height / 2);
    } else {
      p.moveTo(0, 0);
      p.lineTo(0, size.height);
      p.lineTo(size.width, size.height / 2);
    }
    p.close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.dir != dir || old.color != color;
}

class _ScrollbarTrack extends StatelessWidget {
  const _ScrollbarTrack({
    required this.t,
    required this.border,
    required this.dragging,
    required this.onTapDown,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final double t;
  final Color border;
  final bool dragging;
  final ValueChanged<double> onTapDown;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double w = constraints.maxWidth;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onTapDown: (d) => onTapDown((d.localPosition.dx / w).clamp(0.0, 1.0)),
        onHorizontalDragStart: (d) {
          onDragStart();
          onDragUpdate((d.localPosition.dx / w).clamp(0.0, 1.0));
        },
        onHorizontalDragUpdate: (d) =>
            onDragUpdate((d.localPosition.dx / w).clamp(0.0, 1.0)),
        onHorizontalDragEnd: (_) => onDragEnd(),
        child: CustomPaint(
          painter: _TrackPainter(
            t: t,
            border: border,
            thumb: dragging ? WAColors.white : WAColors.pink,
          ),
          size: Size(w, waPx(18)),
        ),
      );
    });
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.t,
    required this.border,
    required this.thumb,
  });

  final double t;
  final Color border;
  final Color thumb;

  static const double _thumb1x = 11.0;

  @override
  void paint(Canvas canvas, Size size) {
    final double bw = waPx(1);
    final double margin = waPx(1);

    // Outer grey border drawn as a filled rect underneath.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = border,
    );
    // Black interior (covers margin and checkerboard area).
    canvas.drawRect(
      Rect.fromLTWH(bw, bw, size.width - 2 * bw, size.height - 2 * bw),
      Paint()..color = WAColors.black,
    );

    // Checkerboard interior — inside border + 1px black margin.
    final double ix = bw + margin;
    final double iy = bw + margin;
    final double iw = size.width - 2 * (bw + margin);
    final double ih = size.height - 2 * (bw + margin);
    _paintCheckerboard(
      canvas,
      Rect.fromLTWH(ix, iy, iw, ih),
      cell: waPx(1),
      fill: WAColors.grey,
    );

    // Thumb: 1px black border + pink interior.
    final double thumbW = waPx(_thumb1x);
    final double thumbX = ix + (iw - thumbW).clamp(0.0, double.infinity) * t;
    final Rect thumbRect = Rect.fromLTWH(thumbX, iy, thumbW, ih);
    canvas.drawRect(thumbRect, Paint()..color = WAColors.black);
    canvas.drawRect(
      Rect.fromLTWH(
        thumbRect.left + bw,
        thumbRect.top + bw,
        thumbRect.width - 2 * bw,
        thumbRect.height - 2 * bw,
      ),
      Paint()..color = thumb,
    );
  }

  void _paintCheckerboard(
    Canvas canvas,
    Rect rect, {
    required double cell,
    required Color fill,
  }) {
    final Paint p = Paint()..color = fill;
    final int cols = (rect.width / cell).floor();
    final int rows = (rect.height / cell).floor();
    for (int gy = 0; gy < rows; gy++) {
      for (int gx = 0; gx < cols; gx++) {
        if (((gx + gy) & 1) == 0) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left + gx * cell,
            rect.top + gy * cell,
            cell,
            cell,
          ),
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.t != t || old.border != border || old.thumb != thumb;
}
