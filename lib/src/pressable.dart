import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Wraps the hover / press / focus scaffolding that nearly every WA control
/// shares. The builder receives the current hover, pressed, and focused flags
/// and returns the visual.
///
/// `onActivate` fires on mouse-UP by default (with drag-away-to-cancel,
/// matching classic Windows push-button behaviour: the Pressed face appears
/// on down, but the click only commits if the pointer is still inside on
/// release). Set [activateOnDown] for selection-style controls (dropdown
/// anchors, list rows) that commit immediately on press with no cancel.
/// Keyboard Space/Enter activation is gated by [activateOnKeyboard] (default
/// true). The handlers are all gated on [enabled]; a disabled pressable
/// never enters hover or pressed state.
class WAPressable extends StatefulWidget {
  const WAPressable({
    super.key,
    required this.enabled,
    required this.onActivate,
    required this.builder,
    this.focusNode,
    this.cursor = SystemMouseCursors.click,
    this.activateOnKeyboard = true,
    this.activateOnDown = false,
  });

  final bool enabled;
  final VoidCallback onActivate;
  final Widget Function(
    BuildContext context,
    bool hover,
    bool pressed,
    bool focused,
  ) builder;
  final FocusNode? focusNode;
  final MouseCursor cursor;
  final bool activateOnKeyboard;
  final bool activateOnDown;

  @override
  State<WAPressable> createState() => _WAPressableState();
}

class _WAPressableState extends State<WAPressable> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool live = widget.enabled;
    Widget inner = Focus(
      focusNode: widget.focusNode,
      canRequestFocus: live,
      onKeyEvent: widget.activateOnKeyboard
          ? (FocusNode node, KeyEvent event) {
              if (live &&
                  event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.space ||
                      event.logicalKey == LogicalKeyboardKey.enter)) {
                widget.onActivate();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            }
          : null,
      child: Builder(builder: (context) {
        final bool focused = Focus.of(context).hasFocus;
        return widget.builder(context, _hover, _pressed, focused);
      }),
    );

    if (widget.activateOnDown) {
      inner = Listener(
        onPointerDown: live
            ? (_) {
                setState(() => _pressed = true);
                widget.onActivate();
              }
            : null,
        onPointerUp: live ? (_) => setState(() => _pressed = false) : null,
        onPointerCancel: live
            ? (_) => setState(() => _pressed = false)
            : null,
        child: inner,
      );
    } else {
      inner = Listener(
        onPointerDown: live
            ? (_) => setState(() => _pressed = true)
            : null,
        child: GestureDetector(
          onTap: live ? widget.onActivate : null,
          onTapUp: live ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: live ? () => setState(() => _pressed = false) : null,
          child: inner,
        ),
      );
    }

    return MouseRegion(
      cursor: live ? widget.cursor : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: inner,
    );
  }
}
