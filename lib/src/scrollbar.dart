import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'disable.dart';
import 'theme.dart';

/// Scrollbar-style value control supporting both horizontal and vertical
/// orientations. WA uses this widget shape for continuous-value pickers and
/// as the scroll track alongside list/table controls.
class WAScrollbar extends StatefulWidget {
  const WAScrollbar({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.axis = Axis.horizontal,
    this.crossAxisSize,
    this.viewportFraction,
    this.width,
    this.height,
    this.enabled = true,
  });

  final double value;
  final double min;
  final double max;

  /// If null, the keyboard/arrow-button step is `(max - min) / 20` and drag is continuous.
  /// If set, drag snaps to the same N divisions.
  final int? divisions;
  final Axis axis;

  /// Thickness perpendicular to the scroll direction. Defaults to `waPx(12)`.
  final double? crossAxisSize;

  /// Fraction of total content visible in the viewport (0..1]. When set, the
  /// thumb is sized proportionally. When null, a fixed-size thumb is used.
  final double? viewportFraction;
  final double? width;
  final double? height;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  State<WAScrollbar> createState() => _WAScrollbarState();
}

class _WAScrollbarState extends State<WAScrollbar> {
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
    final bool horiz = widget.axis == Axis.horizontal;
    final LogicalKeyboardKey decKey =
        horiz ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowUp;
    final LogicalKeyboardKey incKey =
        horiz ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowDown;
    final WAArrowDir decDir = horiz ? WAArrowDir.left : WAArrowDir.up;
    final WAArrowDir incDir = horiz ? WAArrowDir.right : WAArrowDir.down;
    final double crossSize = widget.crossAxisSize ?? waPx(12);
    return WADisable(
      disabled: !live,
      child: Focus(
        canRequestFocus: live,
        onKeyEvent: (node, event) {
          if (!live || event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == decKey) {
            _stepBy(-_step);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == incKey) {
            _stepBy(_step);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: SizedBox(
          width: horiz ? widget.width : crossSize,
          height: horiz ? crossSize : widget.height,
          child: Flex(
            direction: widget.axis,
            children: [
              _ScrollbarButton(
                dir: decDir,
                crossAxisSize: crossSize,
                onTap: () => _stepBy(-_step),
              ),
              Expanded(
                child: _ScrollbarTrack(
                  t: _t,
                  axis: widget.axis,
                  crossAxisSize: crossSize,
                  viewportFraction: widget.viewportFraction,
                  dragging: _dragging,
                  onDragStart: () => setState(() => _dragging = true),
                  onDragUpdate: _setFromT,
                  onDragEnd: () => setState(() => _dragging = false),
                ),
              ),
              _ScrollbarButton(
                dir: incDir,
                crossAxisSize: crossSize,
                onTap: () => _stepBy(_step),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum WAArrowDir { left, right, up, down }

class _ScrollbarButton extends StatefulWidget {
  const _ScrollbarButton({
    required this.dir,
    required this.crossAxisSize,
    required this.onTap,
  });

  final WAArrowDir dir;
  final double crossAxisSize;
  final VoidCallback onTap;

  @override
  State<_ScrollbarButton> createState() => _ScrollbarButtonState();
}

class _ScrollbarButtonState extends State<_ScrollbarButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool horiz =
        widget.dir == WAArrowDir.left || widget.dir == WAArrowDir.right;
    final double mainSize = waPx(12);
    final double crossSize = widget.crossAxisSize;
    final BorderSide side =
        BorderSide(color: WAColors.grey, width: waPx(1));
    final Border box = switch (widget.dir) {
      WAArrowDir.left =>
        Border(top: side, bottom: side, left: side),
      WAArrowDir.right =>
        Border(top: side, bottom: side, right: side),
      WAArrowDir.up =>
        Border(left: side, right: side, top: side),
      WAArrowDir.down =>
        Border(left: side, right: side, bottom: side),
    };
    final Color glyphColor = _hover ? WAColors.white : WAColors.grey;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: Listener(
        onPointerDown: (_) {
          setState(() => _pressed = true);
          widget.onTap();
        },
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: Container(
          width: horiz ? mainSize : crossSize,
          height: horiz ? crossSize : mainSize,
          decoration: BoxDecoration(color: WAColors.black, border: box),
          child: Center(
            child: Transform.translate(
              offset: Offset(0, _pressed ? waPx(1) : 0),
              child: CustomPaint(
                size: horiz ? Size(waPx(4), waPx(8)) : Size(waPx(8), waPx(4)),
                painter:
                    WAArrowPainter(dir: widget.dir, color: glyphColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WAArrowPainter extends CustomPainter {
  WAArrowPainter({required this.dir, required this.color});
  final WAArrowDir dir;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path();
    switch (dir) {
      case WAArrowDir.left:
        p.moveTo(size.width, 0);
        p.lineTo(size.width, size.height);
        p.lineTo(0, size.height / 2);
      case WAArrowDir.right:
        p.moveTo(0, 0);
        p.lineTo(0, size.height);
        p.lineTo(size.width, size.height / 2);
      case WAArrowDir.up:
        p.moveTo(0, size.height);
        p.lineTo(size.width, size.height);
        p.lineTo(size.width / 2, 0);
      case WAArrowDir.down:
        p.moveTo(0, 0);
        p.lineTo(size.width, 0);
        p.lineTo(size.width / 2, size.height);
    }
    p.close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(WAArrowPainter old) =>
      old.dir != dir || old.color != color;
}

class _ScrollbarTrack extends StatefulWidget {
  const _ScrollbarTrack({
    required this.t,
    required this.axis,
    required this.crossAxisSize,
    this.viewportFraction,
    required this.dragging,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final double t;
  final Axis axis;
  final double crossAxisSize;
  final double? viewportFraction;
  final bool dragging;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  State<_ScrollbarTrack> createState() => _ScrollbarTrackState();
}

class _ScrollbarTrackState extends State<_ScrollbarTrack> {
  double _grabOffset = 0;

  double _thumbExtent(double innerLen) {
    if (widget.viewportFraction != null) {
      final double frac = widget.viewportFraction!.clamp(0.0, 1.0);
      return (innerLen * frac).clamp(waPx(_TrackPainter._minThumb1x), innerLen);
    }
    return waPx(_TrackPainter._fixedThumb1x);
  }

  @override
  Widget build(BuildContext context) {
    final bool horiz = widget.axis == Axis.horizontal;
    return LayoutBuilder(builder: (context, constraints) {
      final double extent =
          horiz ? constraints.maxWidth : constraints.maxHeight;
      final double bw = waPx(1);
      final double margin = waPx(1);
      final double innerStart = bw + margin;
      final double innerLen = extent - 2 * (bw + margin);
      final double thumbExt = _thumbExtent(innerLen);
      final double travel = (innerLen - thumbExt).clamp(0.0, double.infinity);

      double tFromDrag(Offset pos) {
        if (travel <= 0) return 0;
        final double p = (horiz ? pos.dx : pos.dy) - innerStart - _grabOffset;
        return (p / travel).clamp(0.0, 1.0);
      }

      void onDragStart(Offset localPos) {
        final double p = horiz ? localPos.dx : localPos.dy;
        final double thumbStart = innerStart + travel * widget.t;
        final double rel = p - thumbStart;
        if (rel >= 0 && rel <= thumbExt) {
          _grabOffset = rel;
        } else {
          _grabOffset = thumbExt / 2;
        }
        widget.onDragStart();
        widget.onDragUpdate(tFromDrag(localPos));
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: horiz
            ? (d) => onDragStart(d.localPosition)
            : null,
        onHorizontalDragUpdate: horiz
            ? (d) => widget.onDragUpdate(tFromDrag(d.localPosition))
            : null,
        onHorizontalDragEnd: horiz ? (_) => widget.onDragEnd() : null,
        onVerticalDragStart: !horiz
            ? (d) => onDragStart(d.localPosition)
            : null,
        onVerticalDragUpdate: !horiz
            ? (d) => widget.onDragUpdate(tFromDrag(d.localPosition))
            : null,
        onVerticalDragEnd: !horiz ? (_) => widget.onDragEnd() : null,
        child: CustomPaint(
          painter: _TrackPainter(
            t: widget.t,
            axis: widget.axis,
            viewportFraction: widget.viewportFraction,
            thumb: widget.dragging ? WAColors.white : WAColors.pink,
          ),
          size: horiz
              ? Size(extent, widget.crossAxisSize)
              : Size(widget.crossAxisSize, extent),
        ),
      );
    });
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.t,
    required this.axis,
    this.viewportFraction,
    required this.thumb,
  });

  final double t;
  final Axis axis;
  final double? viewportFraction;
  final Color thumb;

  static const double _fixedThumb1x = 11.0;
  static const double _minThumb1x = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final double bw = waPx(1);
    final double margin = waPx(1);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = WAColors.grey,
    );
    canvas.drawRect(
      Rect.fromLTWH(bw, bw, size.width - 2 * bw, size.height - 2 * bw),
      Paint()..color = WAColors.black,
    );

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

    final bool horiz = axis == Axis.horizontal;
    final double trackLen = horiz ? iw : ih;
    final double thumbExtent;
    if (viewportFraction != null) {
      final double frac = viewportFraction!.clamp(0.0, 1.0);
      thumbExtent = (trackLen * frac).clamp(waPx(_minThumb1x), trackLen);
    } else {
      thumbExtent = waPx(_fixedThumb1x);
    }
    final double travel =
        (trackLen - thumbExtent).clamp(0.0, double.infinity);
    final double thumbX = horiz ? ix + travel * t : ix;
    final double thumbY = horiz ? iy : iy + travel * t;
    final double thumbW = horiz ? thumbExtent : iw;
    final double thumbH = horiz ? ih : thumbExtent;
    final Rect thumbRect = Rect.fromLTWH(thumbX, thumbY, thumbW, thumbH);
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
      old.t != t ||
      old.axis != axis ||
      old.viewportFraction != viewportFraction ||
      old.thumb != thumb;
}
