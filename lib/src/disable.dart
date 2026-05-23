import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Marks [child] as disabled in WA's visual + behavioural sense.
///
/// Visual: applies the 1-WA-pixel checkerboard alpha mask — half the child's
/// pixels are cut to full transparency, so whatever is behind shows through.
/// This mirrors WA's native disabled-state rendering. Set [background] for
/// the edit-box variant, where the cut-out cells render an opaque colour
/// (palette-0 black) instead of transparent.
///
/// Behaviour: the subtree is wrapped in [AbsorbPointer] and [ExcludeFocus], so
/// it cannot be hovered, clicked, or reached by keyboard focus traversal.
///
/// Widgets should always render in their normal-state colours; this widget
/// produces the disabled appearance from them.
class WADisable extends StatelessWidget {
  const WADisable({
    super.key,
    required this.disabled,
    required this.child,
    this.background,
  });

  final bool disabled;
  final Widget child;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    if (!disabled) return child;
    Widget result = _DisableMaskBox(child: child);
    if (background != null) {
      result = DecoratedBox(
        decoration: BoxDecoration(color: background),
        child: result,
      );
    }
    return ExcludeFocus(child: AbsorbPointer(child: result));
  }
}

class _DisableMaskBox extends SingleChildRenderObjectWidget {
  const _DisableMaskBox({required Widget super.child});

  @override
  _RenderDisableMask createRenderObject(BuildContext context) =>
      _RenderDisableMask();
}

class _RenderDisableMask extends RenderProxyBox {
  final LayerHandle<ShaderMaskLayer> _maskLayer =
      LayerHandle<ShaderMaskLayer>();
  ui.Image? _tile;

  @override
  bool get alwaysNeedsCompositing => child != null;

  /// A 2×2 ARGB tile: opaque-white at (1,0) and (0,1), transparent at (0,0)
  /// and (1,1). Used with `BlendMode.dstIn` so the opaque cells keep the
  /// child pixels and the transparent ones cut them away. The GPU repeats the
  /// tile across the masked rect, so cost is one tiny texture + one quad per
  /// disabled widget no matter how large it grows.
  ui.Image _getTile() {
    if (_tile != null) return _tile!;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint white = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(const Rect.fromLTWH(1, 0, 1, 1), white);
    canvas.drawRect(const Rect.fromLTWH(0, 1, 1, 1), white);
    final ui.Picture picture = recorder.endRecording();
    _tile = picture.toImageSync(2, 2);
    picture.dispose();
    return _tile!;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? child = this.child;
    if (child == null) {
      _maskLayer.layer = null;
      return;
    }
    // Scale the 1-pixel tile up to one WA pixel per cell, then translate so
    // the chequer grid origin aligns with this RenderObject's top-left.
    final double p = waPx(1);
    final Matrix4 matrix = Matrix4.translationValues(offset.dx, offset.dy, 0)
      ..scaleByDouble(p, p, 1, 1);
    final ui.ImageShader shader = ui.ImageShader(
      _getTile(),
      TileMode.repeated,
      TileMode.repeated,
      matrix.storage,
      filterQuality: FilterQuality.none,
    );
    _maskLayer.layer ??= ShaderMaskLayer();
    _maskLayer.layer!
      ..shader = shader
      ..maskRect = offset & size
      ..blendMode = BlendMode.dstIn;
    context.pushLayer(
      _maskLayer.layer!,
      (PaintingContext ctx, Offset off) => ctx.paintChild(child, off),
      offset,
    );
  }

  @override
  void dispose() {
    _maskLayer.layer = null;
    _tile?.dispose();
    _tile = null;
    super.dispose();
  }
}
