import 'package:flutter/widgets.dart';

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
    return WAPressable(
      enabled: enabled,
      onActivate: onClick,
      builder: (context, hover, pressed, focused) {
        // Keyboard focus alone draws no visible change on a push button.
        // Only press (border yellow + face dark-blue) and hover (border
        // white) produce feedback.
        final Color borderColor = !enabled
            ? WAColors.disabled
            : pressed
                ? WAColors.yellow
                : hover
                    ? WAColors.white
                    : WAColors.grey;
        final Color faceColor =
            enabled && pressed ? WAColors.darkBlue : WAColors.black;
        final Color textColor = !enabled
            ? WAColors.disabled
            : (pressed || hover)
                ? WAColors.white
                : WAColors.grey;
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
    );
  }
}
