import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Wraps the hover / press / focus scaffolding that nearly every WA control
/// shares. The builder receives the current hover, pressed, and focused flags
/// and returns the visual.
///
/// `onActivate` is fired on tap and (when [activateOnKeyboard] is true, the
/// default) on Space or Enter while focused. The handlers are all gated on
/// [enabled]; a disabled pressable never enters hover or pressed state.
class WAPressable extends StatefulWidget {
  const WAPressable({
    super.key,
    required this.enabled,
    required this.onActivate,
    required this.builder,
    this.focusNode,
    this.cursor = SystemMouseCursors.click,
    this.activateOnKeyboard = true,
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

  @override
  State<WAPressable> createState() => _WAPressableState();
}

class _WAPressableState extends State<WAPressable> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool live = widget.enabled;
    return MouseRegion(
      cursor: live ? widget.cursor : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: live ? (_) => setState(() => _pressed = true) : null,
        onTapUp: live ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: live ? () => setState(() => _pressed = false) : null,
        onTap: live ? widget.onActivate : null,
        child: Focus(
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
        ),
      ),
    );
  }
}
