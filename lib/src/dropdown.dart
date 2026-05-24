import 'package:flutter/widgets.dart';

import 'disable.dart';
import 'pressable.dart';
import 'scrollbar.dart' show WAArrowDir, WAArrowPainter;
import 'theme.dart';

class WADropdown extends StatefulWidget {
  const WADropdown({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.width,
    this.enabled = true,
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double? width;
  final bool enabled;

  @override
  State<WADropdown> createState() => _WADropdownState();
}

class _WADropdownState extends State<WADropdown> {
  bool _open = false;
  OverlayEntry? _overlay;
  final LayerLink _link = LayerLink();
  final GlobalKey _anchorKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  final Object _tapRegionGroup = Object();

  void _toggle() {
    _focusNode.requestFocus();
    if (_open) {
      _close();
    } else {
      _openOverlay();
    }
  }

  void _openOverlay() {
    final RenderBox box =
        _anchorKey.currentContext!.findRenderObject() as RenderBox;
    final Size anchorSize = box.size;
    _overlay = OverlayEntry(
      builder: (context) => Align(
        alignment: Alignment.topLeft,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: Offset(0, anchorSize.height),
          child: TapRegion(
            groupId: _tapRegionGroup,
            child: _DropdownMenu(
              items: widget.items,
              selectedIndex: widget.selectedIndex,
              width: anchorSize.width,
              onSelect: widget.onSelected,
              onClose: _close,
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() => _open = true);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _open = false);
  }

  @override
  void didUpdateWidget(WADropdown old) {
    super.didUpdateWidget(old);
    if (_overlay != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlay?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _overlay?.remove();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _tapRegionGroup,
      onTapOutside: _open ? (_) => _close() : null,
      child: WADisable(
        disabled: !widget.enabled,
        child: WAPressable(
          enabled: widget.enabled,
          onActivate: _toggle,
          focusNode: _focusNode,
          activateOnDown: true,
          builder: (context, hover, pressed, focused) {
            final bool active = focused && !_open;
            final Color border = active
                ? WAColors.yellow
                : hover
                    ? WAColors.white
                    : WAColors.grey;
            final Color textColor =
                active ? WAColors.white : WAColors.grey;
            final Color chevronColor =
                (hover || pressed) ? WAColors.white : WAColors.grey;
            final Color interior =
                active ? WAColors.darkBlue : WAColors.black;
            return CompositedTransformTarget(
              link: _link,
              child: Container(
                key: _anchorKey,
                width: widget.width,
                decoration: BoxDecoration(
                  color: interior,
                  border:
                      Border.all(color: border, width: WAMetrics.borderWidth),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: WAMetrics.cellPadH,
                          ),
                          child: Text(
                            widget.items[widget.selectedIndex],
                            style: WAFonts.bodyOn(textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Container(width: WAMetrics.borderWidth, color: border),
                      Container(
                        color: WAColors.black,
                        width: waPx(19),
                        child: Center(
                          child: Transform.translate(
                            offset: Offset(0, pressed ? waPx(1) : 0),
                            child: CustomPaint(
                              size: Size(waPx(8), waPx(4)),
                              painter: WAArrowPainter(dir: WAArrowDir.down, color: chevronColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DropdownMenu extends StatelessWidget {
  const _DropdownMenu({
    required this.items,
    required this.selectedIndex,
    required this.width,
    required this.onSelect,
    required this.onClose,
  });

  final List<String> items;
  final int selectedIndex;
  final double width;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: WAColors.darkBlue,
        border: Border.all(color: WAColors.grey, width: WAMetrics.borderWidth),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (i) {
          final bool selected = i == selectedIndex;
          final Color bg =
              selected ? WAColors.selectionRed : WAColors.darkBlue;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // WA fires on mouse-down (no drag-away-to-cancel). Pressing an
              // unselected row commits the selection but keeps the menu open;
              // pressing the already-selected row closes it.
              onTapDown: (_) => selected ? onClose() : onSelect(i),
              child: Container(
                height: WAFonts.smallRowHeight,
                color: bg,
                padding: EdgeInsets.symmetric(
                  horizontal: WAMetrics.cellPadH,
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  items[i],
                  style: WAFonts.smallOn(WAColors.white),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
