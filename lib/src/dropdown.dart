import 'package:flutter/widgets.dart';

import 'pressable.dart';
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

  void _toggle() {
    // WA leaves the anchor focused (Active) after the list closes; clicking
    // should not unfocus it.
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
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: Offset(0, anchorSize.height - WAMetrics.borderWidth),
            child: _DropdownMenu(
              items: widget.items,
              selectedIndex: widget.selectedIndex,
              width: anchorSize.width,
              onSelect: widget.onSelected,
              onClose: _close,
            ),
          ),
        ],
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
    // The overlay closure reads widget.selectedIndex/items, but OverlayEntry
    // does not rebuild on parent setState — push it manually after the
    // current build phase finishes (markNeedsBuild is illegal mid-build).
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
    return WAPressable(
      enabled: widget.enabled,
      onActivate: _toggle,
      focusNode: _focusNode,
      // Dropdown anchor opens on mouse-down (selection-style, like text edit
      // focus), not on the mouse-up + drag-away-to-cancel that buttons use.
      activateOnDown: true,
      builder: (context, hover, pressed, focused) {
        // Opening the dropdown drops the anchor back to Normal; Active is
        // "keyboard focus with list closed".
        final bool active = focused && !_open;
        final bool live = widget.enabled;
        final Color border = !live
            ? WAColors.disabled
            : active
                ? WAColors.yellow
                : hover
                    ? WAColors.white
                    : WAColors.grey;
        // Caption is grey at rest, white only when focused (Active). Hover
        // does not promote the caption.
        final Color textColor = !live
            ? WAColors.disabled
            : active
                ? WAColors.white
                : WAColors.grey;
        // Drop-button arrow is independent of caption: grey at rest, white
        // on hover or press; cell stays opaque black even when the anchor
        // face is dark blue.
        final Color chevronColor = !live
            ? WAColors.disabled
            : (hover || pressed)
                ? WAColors.white
                : WAColors.grey;
        final Color interior =
            live && active ? WAColors.darkBlue : WAColors.black;
        return CompositedTransformTarget(
          link: _link,
          child: Container(
            key: _anchorKey,
            width: widget.width,
            decoration: BoxDecoration(
              color: interior,
              border: Border.all(color: border, width: WAMetrics.borderWidth),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: WAMetrics.controlPadH,
                        vertical: WAMetrics.controlPadV,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: WAMetrics.controlPadH,
                    ),
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(0, pressed ? waPx(1) : 0),
                        child: CustomPaint(
                          size: Size(waPx(7), waPx(4)),
                          painter: _ChevronPainter(chevronColor),
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
        // Open menu's outer border is grey, same as a regular list box.
        border: Border.all(color: WAColors.grey, width: WAMetrics.borderWidth),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (i) {
          // WA's menu has no hover highlight; only the currently selected row
          // is painted red. Mouse moves do not preview a new selection.
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
                height: WAFonts.rowHeight,
                color: bg,
                padding: EdgeInsets.symmetric(
                  horizontal: WAMetrics.controlPadH,
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  items[i],
                  style: WAFonts.bodyOn(WAColors.white),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}
