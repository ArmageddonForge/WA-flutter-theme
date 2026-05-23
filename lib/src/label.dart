import 'package:flutter/widgets.dart';

import 'theme.dart';

enum WALabelTone { muted, normal, accent }

class WALabel extends StatelessWidget {
  const WALabel(
    this.text, {
    super.key,
    this.tone = WALabelTone.normal,
  });

  final String text;
  final WALabelTone tone;

  Color get _color {
    switch (tone) {
      case WALabelTone.muted:
        return WAColors.grey;
      case WALabelTone.normal:
        return WAColors.white;
      case WALabelTone.accent:
        return WAColors.yellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(text, style: WAFonts.bodyOn(_color));
  }
}
