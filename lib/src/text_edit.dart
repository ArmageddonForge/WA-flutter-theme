import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'disable.dart';
import 'theme.dart';

class WATextEdit extends StatefulWidget {
  const WATextEdit({
    super.key,
    this.width,
    this.enabled = true,
    this.initialText,
  });

  final double? width;
  final bool enabled;
  final String? initialText;

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
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final TextSelection sel = selection;
    TextSpan span = super.buildTextSpan(
        context: context, style: style, withComposing: withComposing);
    if (!sel.isCollapsed) {
      span = _transformTextSpanFragments(
        span,
        [sel.start, sel.end],
        (TextRange range, TextSpan span) {
          if (range.start >= sel.start && range.end <= sel.end) {
            return TextSpan(
              style: const TextStyle(color: WAColors.black),
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

class _WATextEditState extends State<WATextEdit> {
  late final TextEditingController controller;
  late final FocusNode focusNode;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    controller = _WATextEditingController();
    if (widget.initialText != null) controller.text = widget.initialText!;
    focusNode = FocusNode();
    focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
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
    return WADisable(
      disabled: !live,
      // Edit-box variant: off-pixels render opaque black (palette-0) instead of
      // transparent, so the field still reads as a field even when disabled.
      background: WAColors.black,
      child: MouseRegion(
        cursor: live ? SystemMouseCursors.text : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: live ? (_) => focusNode.requestFocus() : null,
          child: Container(
            width: widget.width,
            padding: EdgeInsets.symmetric(
              horizontal: WAMetrics.controlPadH,
              vertical: WAMetrics.controlPadV,
            ),
            decoration: BoxDecoration(
              // Field interior is black at rest, dark blue only while
              // keyboard-active (typing).
              color: hasFocus ? WAColors.darkBlue : WAColors.black,
              border: Border.all(
                color: borderColor,
                width: WAMetrics.borderWidth,
              ),
            ),
            child: EditableText(
              controller: controller,
              focusNode: focusNode,
              readOnly: !live,
              dragStartBehavior: DragStartBehavior.down,
              // Text is grey at rest (Normal + Highlighted), white only while
              // focused (Active), matching WA's edit-control rendering. The
              // hover boundary only changes the frame border; text colour
              // does not promote until focus.
              style:
                  WAFonts.bodyOn(hasFocus ? WAColors.white : WAColors.grey),
              cursorColor: WAColors.pink,
              backgroundCursorColor: WAColors.grey,
              selectionColor: WAColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
