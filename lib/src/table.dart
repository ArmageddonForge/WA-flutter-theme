import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'disable.dart';
import 'scrollbar.dart';
import 'theme.dart';

class WATableColumn {
  const WATableColumn({this.header, this.width, this.flex = 0});
  final String? header;
  final double? width;
  final int flex;
}

class WATableRow {
  const WATableRow({required this.cells, this.color});
  final List<Widget> cells;
  final Color? color;
}

class WATable extends StatefulWidget {
  const WATable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.rowBuilder,
    this.selectedIndex,
    this.onSelected,
    this.onActivated,
    this.onHeaderTap,
    this.rowHeight,
    this.width,
    this.height,
    this.enabled = true,
  });

  final List<WATableColumn> columns;
  final int rowCount;
  final WATableRow Function(BuildContext, int index) rowBuilder;
  final int? selectedIndex;
  final ValueChanged<int>? onSelected;
  final ValueChanged<int>? onActivated;
  final ValueChanged<int>? onHeaderTap;
  final double? rowHeight;
  final double? width;
  final double? height;
  final bool enabled;

  @override
  State<WATable> createState() => _WATableState();
}

class _WATableState extends State<WATable> {
  final ScrollController _scrollController = ScrollController();
  double _scrollT = 0;

  // Manual double-tap tracking: GestureDetector.onDoubleTap competes with
  // onTapDown in the gesture arena, causing a 300 ms selection delay. We
  // detect double-taps ourselves so onTapDown fires immediately.
  DateTime? _lastTapTime;
  int? _lastTapIndex;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    final double t =
        pos.maxScrollExtent > 0 ? pos.pixels / pos.maxScrollExtent : 0;
    if (t != _scrollT) setState(() => _scrollT = t);
  }

  void _jumpToT(double t) {
    if (!_scrollController.hasClients) return;
    _scrollController
        .jumpTo(t * _scrollController.position.maxScrollExtent);
  }

  void _handleTapDown(BuildContext ctx, int i) {
    Focus.of(ctx).requestFocus();
    final now = DateTime.now();
    final isDoubleTap = _lastTapIndex == i &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < kDoubleTapTimeout;
    if (isDoubleTap) {
      _lastTapTime = null;
      _lastTapIndex = null;
      widget.onActivated?.call(i);
    } else {
      widget.onSelected?.call(i);
      _lastTapTime = now;
      _lastTapIndex = i;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool live = widget.enabled;
    return WADisable(
      disabled: !live,
      child: Focus(
        canRequestFocus: live,
        onKeyEvent: (node, event) {
          if (!live || event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (widget.rowCount == 0) return KeyEventResult.handled;
            final int current = widget.selectedIndex ?? -1;
            final int next = (current + 1).clamp(0, widget.rowCount - 1);
            if (next != widget.selectedIndex) widget.onSelected?.call(next);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            if (widget.selectedIndex == null) return KeyEventResult.handled;
            final int next =
                (widget.selectedIndex! - 1).clamp(0, widget.rowCount - 1);
            if (next != widget.selectedIndex) widget.onSelected?.call(next);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (widget.selectedIndex != null) {
              widget.onActivated?.call(widget.selectedIndex!);
            }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Builder(builder: (context) {
          final bool hasFocus = Focus.of(context).hasFocus;
          return LayoutBuilder(builder: (context, outerConstraints) {
            final double containerH =
                widget.height ?? outerConstraints.maxHeight;
            final bool hasHeaders =
                widget.columns.any((c) => c.header != null);
            final double headerH = hasHeaders ? waPx(17) : 0;
            final double borderCount = hasHeaders ? 1 : 2;
            final double listH =
                containerH - borderCount * WAMetrics.borderWidth - headerH;
            final double totalH = widget.rowCount * (widget.rowHeight ?? WAFonts.smallRowHeight);
            final bool overflows = totalH > listH;
            final double vf = totalH > 0
                ? (listH / totalH).clamp(0.0, 1.0)
                : 1.0;
            final BorderSide borderSide = BorderSide(
              color: WAColors.grey,
              width: WAMetrics.borderWidth,
            );
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: WAColors.darkBlue,
                border: Border(
                  top: hasHeaders ? BorderSide.none : borderSide,
                  left: borderSide,
                  bottom: borderSide,
                  right: overflows ? BorderSide.none : borderSide,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasHeaders)
                  _HeaderRow(
                    columns: widget.columns,
                    onTap: widget.onHeaderTap,
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ListView.builder(
                      controller: _scrollController,
                      itemCount: widget.rowCount,
                      itemExtent: widget.rowHeight ?? WAFonts.smallRowHeight,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, i) {
                        final WATableRow row = widget.rowBuilder(context, i);
                        assert(
                          row.cells.length == widget.columns.length,
                          'WATableRow.cells.length must equal columns.length',
                        );
                        final bool selected = i == widget.selectedIndex;
                        final Color bg =
                            selected ? WAColors.selectionRed : WAColors.darkBlue;
                        final Color textColor = row.color ?? WAColors.white;
                        return MouseRegion(
                          cursor: live
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          child: Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: live
                                ? (_) => _handleTapDown(context, i)
                                : null,
                            child: CustomPaint(
                              foregroundPainter: (selected && hasFocus && live)
                                  ? _DottedRectPainter(WAColors.grey)
                                  : null,
                              child: DefaultTextStyle(
                                style: WAFonts.smallOn(textColor),
                                child: Container(
                                  color: bg,
                                  child: Row(
                                    children: [
                                      for (int c = 0;
                                          c < widget.columns.length;
                                          c++)
                                        _cellWrapper(
                                          widget.columns[c],
                                          row.cells[c],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                        ),
                        if (overflows)
                          WAScrollbar(
                            axis: Axis.vertical,
                            value: _scrollT,
                            viewportFraction: vf,
                            onChanged: _jumpToT,
                            enabled: live,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
        }),
      ),
    );
  }

  Widget _cellWrapper(WATableColumn col, Widget cell) {
    Widget padded = Padding(
      padding: EdgeInsets.symmetric(horizontal: WAMetrics.cellPadH),
      child: Align(alignment: Alignment.centerLeft, child: cell),
    );
    if (col.width != null) {
      return SizedBox(width: col.width, child: padded);
    }
    return Expanded(flex: col.flex == 0 ? 1 : col.flex, child: padded);
  }
}

class _HeaderRow extends StatefulWidget {
  const _HeaderRow({required this.columns, this.onTap});
  final List<WATableColumn> columns;
  final ValueChanged<int>? onTap;

  @override
  State<_HeaderRow> createState() => _HeaderRowState();
}

class _HeaderRowState extends State<_HeaderRow> {
  int? _hoverIndex;
  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: waPx(17),
      color: WAColors.black,
      child: Row(
        children: [
          for (int i = 0; i < widget.columns.length; i++)
            _headerCell(i, widget.columns[i]),
        ],
      ),
    );
  }

  Widget _headerCell(int index, WATableColumn col) {
    final bool hover = _hoverIndex == index;
    final bool pressed = _pressedIndex == index;
    final Color borderColor =
        pressed ? WAColors.yellow : (hover ? WAColors.white : WAColors.grey);
    final Color bg = pressed ? WAColors.darkBlue : WAColors.black;
    final Widget cell = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoverIndex = index),
      onExit: (_) => setState(() {
        if (_hoverIndex == index) _hoverIndex = null;
        if (_pressedIndex == index) _pressedIndex = null;
      }),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressedIndex = index),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (_) {
            setState(() => _pressedIndex = null);
            widget.onTap?.call(index);
          },
          onTapCancel: () => setState(() => _pressedIndex = null),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: borderColor, width: waPx(1)),
            ),
            padding: EdgeInsets.only(left: waPx(3), right: waPx(2)),
            alignment: Alignment.centerLeft,
            child: Text(
              col.header ?? '',
              style: WAFonts.smallOn(WAColors.grey),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
    if (col.width != null) {
      return SizedBox(width: col.width, child: cell);
    }
    return Expanded(flex: col.flex == 0 ? 1 : col.flex, child: cell);
  }
}

class _DottedRectPainter extends CustomPainter {
  _DottedRectPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = color;
    final double d = waPx(1);
    for (double x = 0; x + d <= size.width; x += d * 2) {
      canvas.drawRect(Rect.fromLTWH(x, 0, d, d), p);
      canvas.drawRect(Rect.fromLTWH(x, size.height - d, d, d), p);
    }
    for (double y = 0; y + d <= size.height; y += d * 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, d, d), p);
      canvas.drawRect(Rect.fromLTWH(size.width - d, y, d, d), p);
    }
  }

  @override
  bool shouldRepaint(_DottedRectPainter old) => old.color != color;
}
