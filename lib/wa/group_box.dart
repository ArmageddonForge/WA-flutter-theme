import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A bordered panel with an optional title that sits on top of the border,
/// interrupting it (WA Frontend "Options" dialog style).
class WAGroupBox extends StatelessWidget {
  const WAGroupBox({
    super.key,
    required this.child,
    this.title,
  });

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = WAFonts.bodyOn(WAColors.grey);
    final EdgeInsets framePad = EdgeInsets.fromLTRB(
      WAMetrics.groupPad,
      title == null ? WAMetrics.groupPad : titleStyle.fontSize! * 0.6,
      WAMetrics.groupPad,
      WAMetrics.groupPad,
    );
    return Padding(
      padding: EdgeInsets.only(top: title == null ? 0 : titleStyle.fontSize! / 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: WAColors.grey,
                width: waPx(2),
              ),
            ),
            padding: framePad,
            child: child,
          ),
          if (title != null)
            Positioned(
              left: WAMetrics.groupPad,
              top: -titleStyle.fontSize! / 2,
              child: Container(
                color: WAColors.black,
                padding: EdgeInsets.symmetric(horizontal: WAMetrics.gap),
                child: Text(title!, style: titleStyle),
              ),
            ),
        ],
      ),
    );
  }
}
