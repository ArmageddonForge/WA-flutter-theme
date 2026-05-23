import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'disable.dart';
import 'theme.dart';

class WATextEdit extends StatefulWidget {
  const WATextEdit({
    super.key,
    this.width,
    this.enabled = true,
    this.initialText,
    this.maxLength,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.multiline = false,
    this.textStyle,
  });

  final double? width;
  final bool enabled;
  final String? initialText;
  final int? maxLength;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool multiline;
  final TextStyle? textStyle;

  @override
  State<WATextEdit> createState() => _WATextEditState();
}

TextSpan _transformTextSpanFragments(
  TextSpan span,
  List<int> stopPoints,
  TextSpan Function(TextRange, TextSpan) spanTransformer,
) {
  TextSpan cloneTextSpanWithChildren(TextSpan span, List<InlineSpan> children) {
    return TextSpan(
      text: null,
      children: children,
      style: span.style,
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }

  int pos = 0;
  ListQueue<int> stopPointQueue = ListQueue.of(stopPoints);
  InlineSpan visit(InlineSpan span) {
    if (span is TextSpan) {
      while (stopPointQueue.isNotEmpty && stopPointQueue.first < pos) {
        stopPointQueue.removeFirst();
      }
      if (span.text != null) {
        int end = pos + span.text!.length;
        if (stopPointQueue.isNotEmpty && stopPointQueue.first < end) {
          List<InlineSpan> children = [];
          int p0 = 0;
          while (stopPointQueue.isNotEmpty && stopPointQueue.first < end) {
            int p1 = stopPointQueue.removeFirst() - pos;
            children.add(TextSpan(text: span.text!.substring(p0, p1)));
            p0 = p1;
          }
          if (p0 < end) {
            children.add(TextSpan(text: span.text!.substring(p0, end)));
          }
          children = children + (span.children ?? []);
          return visit(cloneTextSpanWithChildren(span, children));
        }
        var start = pos;
        pos = end;
        span = spanTransformer(TextRange(start: start, end: end), span);
      } else if (span.children != null) {
        var children = List.of(span.children!.map(visit));
        span = cloneTextSpanWithChildren(span, children);
      }
    }
    return span;
  }

  return visit(span) as TextSpan;
}

class _WATextEditingController extends TextEditingController {
  bool obscure = false;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final TextSelection sel = selection;
    TextSpan span;
    if (obscure) {
      span = TextSpan(style: style, text: '•' * text.length);
    } else {
      span = super.buildTextSpan(
          context: context, style: style, withComposing: withComposing);
    }
    if (!sel.isCollapsed) {
      span = _transformTextSpanFragments(
        span,
        [sel.start, sel.end],
        (TextRange range, TextSpan span) {
          if (range.start >= sel.start && range.end <= sel.end) {
            return TextSpan(
              style: const TextStyle(
                color: WAColors.black,
                backgroundColor: WAColors.white,
              ),
              children: [span],
            );
          }
          return span;
        },
      );
    }
    return span;
  }
}

class _NoAnimationScrollController extends ScrollController {
  @override
  Future<void> animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) async {
    for (final position in positions) {
      position.jumpTo(offset);
    }
  }
}

class _WATextEditState extends State<WATextEdit> {
  late final _WATextEditingController _controller;
  late final FocusNode focusNode;
  late final ScrollController _scrollController;
  final GlobalKey<EditableTextState> _editableKey = GlobalKey<EditableTextState>();
  bool _hover = false;

  DateTime? _lastTapTime;
  Offset? _lastTapPos;
  Offset? _dragOrigin;
  bool _dragging = false;
  bool _wordDrag = false;

  String get text => _controller.text;
  set text(String value) => _controller.text = value;

  @override
  void initState() {
    super.initState();
    _scrollController = _NoAnimationScrollController();
    _controller = _WATextEditingController()
      ..obscure = widget.obscureText;
    if (widget.initialText != null) {
      _controller.text = widget.initialText!;
    }
    if (widget.onChanged != null) {
      _controller.addListener(_onControllerChanged);
    }
    focusNode = FocusNode();
    focusNode.addListener(() => setState(() {}));
  }

  void _onControllerChanged() {
    widget.onChanged?.call(_controller.text);
  }

  @override
  void didUpdateWidget(WATextEdit old) {
    super.didUpdateWidget(old);
    if (old.obscureText != widget.obscureText) {
      _controller.obscure = widget.obscureText;
    }
    if (old.onChanged != widget.onChanged) {
      _controller.removeListener(_onControllerChanged);
      if (widget.onChanged != null) {
        _controller.addListener(_onControllerChanged);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  RenderEditable get _renderEditable =>
      _editableKey.currentState!.renderEditable;

  void _handlePointerDown(PointerDownEvent event) {
    focusNode.requestFocus();
    final now = DateTime.now();
    final bool isDoubleTap = _lastTapTime != null &&
        _lastTapPos != null &&
        now.difference(_lastTapTime!) < kDoubleTapTimeout &&
        (event.position - _lastTapPos!).distance <= kDoubleTapSlop;

    _renderEditable.handleTapDown(
      TapDownDetails(globalPosition: event.position),
    );

    if (isDoubleTap) {
      _renderEditable.selectWord(cause: SelectionChangedCause.doubleTap);
      _lastTapTime = null;
      _lastTapPos = null;
      _dragOrigin = event.position;
      _dragging = true;
      _wordDrag = true;
    } else {
      _renderEditable.selectPosition(cause: SelectionChangedCause.tap);
      _lastTapTime = now;
      _lastTapPos = event.position;
      _dragOrigin = event.position;
      _dragging = true;
      _wordDrag = false;
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_dragging) return;
    if (_wordDrag) {
      _renderEditable.selectWordsInRange(
        from: _dragOrigin!,
        to: event.position,
        cause: SelectionChangedCause.drag,
      );
    } else {
      _renderEditable.selectPositionAt(
        from: _dragOrigin!,
        to: event.position,
        cause: SelectionChangedCause.drag,
      );
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _dragging = false;
    _wordDrag = false;
  }

  @override
  Widget build(BuildContext context) {
    final bool live = widget.enabled;
    final bool hasFocus = focusNode.hasFocus;
    final Color borderColor = hasFocus
        ? WAColors.yellow
        : _hover
            ? WAColors.white
            : WAColors.grey;
    final List<TextInputFormatter> formatters = [
      if (widget.maxLength != null)
        LengthLimitingTextInputFormatter(widget.maxLength),
    ];
    return WADisable(
      disabled: !live,
      // Edit-box variant: off-pixels render opaque black (palette-0) instead of
      // transparent, so the field still reads as a field even when disabled.
      background: WAColors.black,
      child: MouseRegion(
        cursor: live ? SystemMouseCursors.text : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: live ? _handlePointerDown : null,
          onPointerMove: live ? _handlePointerMove : null,
          onPointerUp: live ? _handlePointerUp : null,
          child: Container(
            width: widget.width,
            padding: EdgeInsets.symmetric(
              horizontal: WAMetrics.cellPadH,
            ),
            decoration: BoxDecoration(
              color: hasFocus ? WAColors.darkBlue : WAColors.black,
              border: Border.all(
                color: borderColor,
                width: WAMetrics.borderWidth,
              ),
            ),
            child: EditableText(
              key: _editableKey,
              controller: _controller,
              focusNode: focusNode,
              scrollController: _scrollController,
              readOnly: !live,
              dragStartBehavior: DragStartBehavior.down,
              maxLines: widget.multiline ? null : 1,
              minLines: widget.multiline ? 1 : null,
              keyboardType: widget.multiline
                  ? TextInputType.multiline
                  : TextInputType.text,
              inputFormatters: formatters.isEmpty ? null : formatters,
              onSubmitted: widget.multiline ? null : widget.onSubmitted,
              style: (widget.textStyle ?? WAFonts.body)
                  .copyWith(color: hasFocus ? WAColors.white : WAColors.grey),
              cursorColor: WAColors.pink,
              backgroundCursorColor: WAColors.grey,
              selectionColor: const Color(0x00000000),
            ),
          ),
        ),
      ),
    );
  }
}
