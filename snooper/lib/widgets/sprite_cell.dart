import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:wa/wa.dart';

class SpriteCell extends LeafRenderObjectWidget {
  const SpriteCell({
    super.key,
    required this.sheet,
    required this.src,
    this.scale = waScale,
  });

  final ui.Image sheet;
  final Rect src;
  final double scale;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSpriteCell(sheet, src, scale);

  @override
  // ignore: library_private_types_in_public_api
  void updateRenderObject(BuildContext context, _RenderSpriteCell renderObject) {
    renderObject
      ..sheet = sheet
      ..src = src
      ..scale = scale;
  }
}

class _RenderSpriteCell extends RenderBox {
  _RenderSpriteCell(this._sheet, this._src, this._scale);

  ui.Image _sheet;
  Rect _src;
  double _scale;

  set sheet(ui.Image v) { if (v != _sheet) { _sheet = v; markNeedsPaint(); } }
  set src(Rect v) { if (v != _src) { _src = v; markNeedsPaint(); } }
  set scale(double v) { if (v != _scale) { _scale = v; markNeedsLayout(); } }

  @override
  void performLayout() {
    size = constraints.constrain(
      Size(_src.width * _scale, _src.height * _scale),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Rect dst = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      size.width,
      size.height,
    );
    context.canvas.drawImageRect(
      _sheet,
      _src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }
}
