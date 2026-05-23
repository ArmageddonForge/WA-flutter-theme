import 'package:flutter/widgets.dart';

import 'theme.dart';

class WAButton extends StatefulWidget {
  const WAButton({
    super.key,
    required this.caption,
    required this.onClick,
    this.enabled = true,
  });

  final String caption;
  final VoidCallback onClick;
  final bool enabled;

  @override
  State<WAButton> createState() => _WAButtonState();
}

class _WAButtonState extends State<WAButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool live = widget.enabled;
    return MouseRegion(
      cursor: live ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: live ? (_) => setState(() => _pressed = true) : null,
        onTapUp: live ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: live ? () => setState(() => _pressed = false) : null,
        onTap: live ? widget.onClick : null,
        child: Focus(
          canRequestFocus: live,
          child: Builder(
            builder: (BuildContext context) {
              // WA: keyboard focus alone draws no visible change on a push
              // button. Only press (border yellow + face dark-blue) and hover
              // (border white) produce feedback.
              final Color borderColor = !live
                  ? WAColors.disabledBorder
                  : _pressed
                      ? WAColors.yellow
                      : _hover
                          ? WAColors.white
                          : WAColors.grey;
              final Color faceColor =
                  live && _pressed ? WAColors.darkBlue : WAColors.black;
              final Color textColor = !live
                  ? WAColors.disabledFg
                  : (_pressed || _hover)
                      ? WAColors.white
                      : WAColors.grey;
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: WAMetrics.controlPadH,
                  vertical: WAMetrics.controlPadV,
                ),
                decoration: BoxDecoration(
                  color: faceColor,
                  border: Border.all(
                    color: borderColor,
                    width: waPx(2),
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(waPx(2))),
                ),
                child: Text(
                  widget.caption,
                  style: WAFonts.bodyOn(textColor),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
