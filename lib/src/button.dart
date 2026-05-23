import 'package:flutter/widgets.dart';

import 'disable.dart';
import 'pressable.dart';
import 'theme.dart';

class WAButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return WADisable(
      disabled: !enabled,
      child: WAPressable(
        enabled: enabled,
        onActivate: onClick,
        builder: (context, hover, pressed, focused) {
          // Keyboard focus alone draws no visible change on a push button.
          // Only press (border yellow + face dark-blue) and hover (border
          // white) produce feedback. Disabled state is the checkerboard
          // mask applied by WADisable; colours below are always the
          // live values.
          final Color borderColor = pressed
              ? WAColors.yellow
              : hover
                  ? WAColors.white
                  : WAColors.grey;
          final Color faceColor =
              pressed ? WAColors.darkBlue : WAColors.black;
          final Color textColor =
              (pressed || hover) ? WAColors.white : WAColors.grey;
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: WAMetrics.controlPadH,
              vertical: WAMetrics.controlPadV,
            ),
            decoration: BoxDecoration(
              color: faceColor,
              border: Border.all(color: borderColor, width: waPx(2)),
              borderRadius: BorderRadius.all(Radius.circular(waPx(2))),
            ),
            child: Text(caption, style: WAFonts.bodyOn(textColor)),
          );
        },
      ),
    );
  }
}
