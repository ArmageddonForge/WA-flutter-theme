import 'package:flutter/widgets.dart';

import 'theme.dart';

class WAGroupBox extends StatelessWidget {
  const WAGroupBox({
    super.key,
    required this.child,
    this.title,
  });

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = WAFonts.bodyOn(WAColors.grey);
    final double borderW = waPx(2);
    final EdgeInsets framePad = EdgeInsets.fromLTRB(
      WAMetrics.groupPad,
      title == null ? WAMetrics.groupPad : WAMetrics.groupPad,
      WAMetrics.groupPad,
      WAMetrics.groupPad,
    );

    if (title == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: WAColors.grey, width: borderW),
        ),
        padding: framePad,
        child: child,
      );
    }

    // Position label so its baseline sits 3 WApx below the 2 WApx border.
    // baseline target = borderW + waPx(3) from the container top.
    // topToBaseline within the Text widget ≈ halfLeading + fontAscent.
    final double lineH = titleStyle.fontSize! * titleStyle.height!;
    final double leading = lineH - titleStyle.fontSize!;
    // DejaVu Sans Condensed Bold: hhea ascent 1901 / UPM 2048
    final double fontAscent = titleStyle.fontSize! * 1901 / 2048;
    final double topToBaseline = leading / 2 + fontAscent;
    final double baselineY = borderW + waPx(3);
    final double labelTop = baselineY - topToBaseline;

    final double gapLeft = WAMetrics.groupPad;
    final double gapPadH = WAMetrics.gap;
    final double outerTop = labelTop < 0 ? -labelTop : 0;

    return Padding(
      padding: EdgeInsets.only(top: outerTop),
      child: _GroupBoxLayout(
        gapLeft: gapLeft,
        gapPadH: gapPadH,
        borderWidth: borderW,
        framePad: framePad,
        titleStyle: titleStyle,
        title: title!,
        labelTop: labelTop,
        child: child,
      ),
    );
  }
}

class _GroupBoxLayout extends StatefulWidget {
  const _GroupBoxLayout({
    required this.gapLeft,
    required this.gapPadH,
    required this.borderWidth,
    required this.framePad,
    required this.titleStyle,
    required this.title,
    required this.labelTop,
    required this.child,
  });

  final double gapLeft;
  final double gapPadH;
  final double borderWidth;
  final EdgeInsets framePad;
  final TextStyle titleStyle;
  final String title;
  final double labelTop;
  final Widget child;

  @override
  State<_GroupBoxLayout> createState() => _GroupBoxLayoutState();
}

class _GroupBoxLayoutState extends State<_GroupBoxLayout> {
  final GlobalKey _titleKey = GlobalKey();
  double _gapWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTitle());
  }

  @override
  void didUpdateWidget(_GroupBoxLayout old) {
    super.didUpdateWidget(old);
    if (old.title != widget.title) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureTitle());
    }
  }

  void _measureTitle() {
    final box = _titleKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final w = box.size.width + 2 * widget.gapPadH;
      if (w != _gapWidth) setState(() => _gapWidth = w);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          painter: _GappedBorderPainter(
            color: WAColors.grey,
            width: widget.borderWidth,
            gapLeft: widget.gapLeft,
            gapWidth: _gapWidth,
          ),
          child: Padding(
            padding: widget.framePad + EdgeInsets.all(widget.borderWidth),
            child: widget.child,
          ),
        ),
        Positioned(
          left: widget.gapLeft + widget.gapPadH,
          top: widget.labelTop,
          child: Text(
            widget.title,
            key: _titleKey,
            style: widget.titleStyle,
          ),
        ),
      ],
    );
  }
}

class _GappedBorderPainter extends CustomPainter {
  _GappedBorderPainter({
    required this.color,
    required this.width,
    required this.gapLeft,
    required this.gapWidth,
  });

  final Color color;
  final double width;
  final double gapLeft;
  final double gapWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Left border
    canvas.drawRect(Rect.fromLTWH(0, 0, width, size.height), paint);
    // Right border
    canvas.drawRect(
        Rect.fromLTWH(size.width - width, 0, width, size.height), paint);
    // Bottom border
    canvas.drawRect(
        Rect.fromLTWH(0, size.height - width, size.width, width), paint);

    // Top border with gap
    if (gapWidth <= 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, width), paint);
    } else {
      canvas.drawRect(Rect.fromLTWH(0, 0, gapLeft, width), paint);
      canvas.drawRect(Rect.fromLTWH(
          gapLeft + gapWidth, 0, size.width - gapLeft - gapWidth, width),
          paint);
    }
  }

  @override
  bool shouldRepaint(_GappedBorderPainter old) =>
      old.color != color ||
      old.width != width ||
      old.gapLeft != gapLeft ||
      old.gapWidth != gapWidth;
}
